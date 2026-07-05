import 'package:mobile_assistant/core/db/app_database.dart';
import 'package:mobile_assistant/shared/models/chat_message.dart';
import 'package:mobile_assistant/shared/models/chat_session.dart';
import 'package:sqflite/sqflite.dart';
import 'package:stacked/stacked.dart';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart' hide ChatSession;
import 'package:mobile_assistant/shared/models/task_item.dart';
import 'package:mobile_assistant/shared/models/agent_action.dart';
import 'package:mobile_assistant/core/services/action_dispatcher.dart';
import 'package:mobile_assistant/core/agent/tools/memory_tool.dart';
import 'package:mobile_assistant/core/services/ocr_service.dart';
import 'package:flutter/material.dart' hide ActionDispatcher;
import 'dart:math' as math;
import 'dart:io';

class ChatVM extends BaseViewModel {
  Database? db;
  List<ChatMessage> messages = [];
  List<ChatSession> sessions = [];
  ChatSession? currentSession;

  bool isGenerating = false;
  final TextEditingController messageController = TextEditingController();

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }

  Future<void> loadDB() async {
    db ??= await AppDatabase.instance.database;
  }

  Future<void> loadSessions() async {
    await loadDB();
    final result = await db!.query('chat_sessions', orderBy: 'createdAt DESC');
    sessions = result.map((e) => ChatSession.fromMap(e)).toList();
    if (sessions.isNotEmpty && currentSession == null) {
      currentSession = sessions.first;
      await loadMessages();
    } else if (sessions.isEmpty) {
      await createNewSession();
    }
    notifyListeners();
  }

  Future<void> createNewSession() async {
    await loadDB();
    ChatSession newSession = ChatSession(
      title: 'New Chat',
      createdAt: DateTime.now(),
    );
    final id = await db!.insert('chat_sessions', newSession.toMap());
    newSession.id = id;
    sessions.insert(0, newSession);
    currentSession = newSession;
    messages.clear();
    notifyListeners();
  }

  Future<void> switchSession(ChatSession session) async {
    currentSession = session;
    await loadMessages();
  }

  Future<void> deleteSession(int sessionId) async {
    await loadDB();
    await db!.delete('chat_sessions', where: 'id = ?', whereArgs: [sessionId]);
    await db!.delete('messages', where: 'sessionId = ?', whereArgs: [sessionId]);
    sessions.removeWhere((s) => s.id == sessionId);
    if (currentSession?.id == sessionId) {
      if (sessions.isNotEmpty) {
        currentSession = sessions.first;
        await loadMessages();
      } else {
        await createNewSession();
      }
    }
    notifyListeners();
  }

  Future<void> _generateChatTitle(String firstMessage) async {
    if (currentSession == null || currentSession!.title != 'New Chat') return;
    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty || apiKey == 'YOUR_API_KEY_HERE') return;
      
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: apiKey,
      );
      final response = await model.generateContent([
        Content.text("Generate a short, 2-4 word title for this chat based on the user's first message: '$firstMessage'. Only return the title, no quotes or extra text.")
      ]);
      final title = response.text?.trim() ?? "New Chat";
      currentSession!.title = title;
      await db!.update('chat_sessions', currentSession!.toMap(), where: 'id = ?', whereArgs: [currentSession!.id]);
      int index = sessions.indexWhere((s) => s.id == currentSession!.id);
      if (index != -1) sessions[index] = currentSession!;
      notifyListeners();
    } catch (e) {
      // Ignore errors for title generation
    }
  }

  Future<void> sendMessage(
    String content,
    DateTime timestamp, {
    required bool isUser,
  }) async {
    clearErrors();
    await loadDB();
    if (content.trim().isEmpty) {
      setError("Message cannot be empty");
      return;
    }
    if (currentSession == null) {
      await createNewSession();
    }

    ChatMessage message = ChatMessage(
      sessionId: currentSession!.id,
      content: content,
      isUser: isUser,
      timestamp: timestamp,
      attachmentPath: isUser ? pendingAttachmentPath : null,
    );
    
    if (isUser) pendingAttachmentPath = null;

    final id = await db!.insert('messages', message.toMap());
    message.id = id;
    messages.add(message);
    notifyListeners();

    // If it's a user message, trigger the Assistant's response pipeline
    if (isUser) {
      if (messages.length == 1 || (messages.isNotEmpty && currentSession!.title == 'New Chat')) {
        _generateChatTitle(content);
      }
      await _generateAssistantResponse();
    }
  }

  Future<void> _generateAssistantResponse() async {
    isGenerating = true;
    notifyListeners();

    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty || apiKey == 'YOUR_API_KEY_HERE') {
        setError("Please set your Gemini API Key in the .env file.");
        notifyListeners();
        return;
      }

      await loadDB();
      final tasksResult = await db!.query('tasks', where: 'completed = 0');
      final currentTasks = tasksResult.map((e) => TaskItem.fromMap(e)).toList();
      final tasksContext = currentTasks.map((t) => "{id: ${t.id}, title: '${t.title}', dueDate: '${t.dueDate.toIso8601String()}', priority: '${t.priority.name}'}").join(", ");

      final prompt = messages.last.content;
      final memoryTool = MemoryTool();
      final memoryContext = await memoryTool.execute('search_memory', {'query': prompt});

      final systemInstruction = '''
You are a helpful assistant for a task management app with agentic capabilities. Extract the user's intent into a structured JSON array.
Current time: ${DateTime.now().toIso8601String()}
Existing pending tasks: [$tasksContext]
Relevant Memories: $memoryContext

# Task & Date Reasoning Rules
- When the user uses a natural language date (e.g., "tomorrow", "next Friday", "in 3 weeks") to create or edit a task, you MUST calculate the exact date based on the 'Current time' and pass it strictly as an ISO8601 string in the parameters.
- You have full access to the user's 'Existing pending tasks' including due dates and priorities. If the user asks "What should I work on first?" or "What's overdue?", analyze the tasks and reply intelligently using the 'core' tool 'other' action. Do not use get_overdue_tasks, just answer directly.

Return ONLY a valid JSON array of action objects matching this schema:
[
  {
    "tool": "string (task_tool, memory_tool, document_tool, core)",
    "action": "string (create_task, remember_fact, create_document, search_documents, read_document, other)",
    "parameters": { ...key-value pairs depending on action... },
    "reply": "string (optional, use this for natural language replies)"
  }
]

For 'task_tool':
- 'create_task': 'title' (string), 'dueDate' (ISO8601 string), 'description' (string), 'priority' (low, medium, high)
- 'edit_task': 'id' (integer), and fields to update
- 'delete_task': 'id' (integer)
- 'get_overdue_tasks' / 'get_workload'

For 'memory_tool':
- 'remember_fact': 'fact' (string), 'importance' (float 0.0 to 1.0)
- 'forget_fact': 'id' (integer)

For 'document_tool':
- 'create_document': 'title' (string), 'content' (markdown string), 'tags' (array of strings), 'folder' (string)
- 'search_documents': 'keyword' (string)
- 'read_document': 'id' (integer)

For general chat or asking clarifying questions, use tool 'core', action 'other', and provide the 'reply' field.
If you detect a user preference or fact, you can add a 'remember_fact' action silently alongside your reply.
''';

      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: apiKey,
        systemInstruction: Content.system(systemInstruction),
        generationConfig: GenerationConfig(responseMimeType: "application/json"),
      );

      final pastMessages = messages.where((m) => m.id != messages.last.id).toList();
      final chatHistory = pastMessages.skip(math.max(0, pastMessages.length - 10)).map((m) {
        if (m.attachmentPath != null && File(m.attachmentPath!).existsSync()) {
          final bytes = File(m.attachmentPath!).readAsBytesSync();
          return Content(m.isUser ? 'user' : 'model', [
            TextPart(m.content),
            DataPart('image/jpeg', bytes),
          ]);
        }
        return Content(m.isUser ? 'user' : 'model', [TextPart(m.content)]);
      }).toList();

      final chatSession = model.startChat(history: chatHistory);
      
      final lastMsg = messages.last;
      Content requestContent;
      if (lastMsg.attachmentPath != null && File(lastMsg.attachmentPath!).existsSync()) {
        final bytes = File(lastMsg.attachmentPath!).readAsBytesSync();
        requestContent = Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', bytes),
        ]);
      } else {
        requestContent = Content.text(prompt);
      }
      
      final response = await chatSession.sendMessage(requestContent);
      final responseText = response.text?.trim();

      if (responseText != null && responseText.isNotEmpty) {
        String executedAction = 'unknown';
        String status = 'success';
        
        try {
          final List<dynamic> data = jsonDecode(responseText);
          final actions = data.map((e) => AgentAction.fromJson(e)).toList();
          executedAction = actions.map((a) => a.action).join(", ");

          final dispatchMessages = await ActionDispatcher.dispatchAll(actions);
          for (var msg in dispatchMessages) {
             if (msg != "Done.") {
               await _addAssistantMessage(msg);
             }
          }

        } catch (e) {
          status = 'failure: $e';
          final errorMsg = e.toString();
          if (errorMsg.startsWith("Exception:")) {
            await _addAssistantMessage(errorMsg.replaceAll("Exception: ", "").trim());
          } else {
            await _addAssistantMessage("I couldn't understand that request. Let's try again.");
          }
        } finally {
          await db!.insert('interaction_logs', {
            'userMessage': prompt,
            'geminiResponse': responseText,
            'executedAction': executedAction,
            'status': status,
            'timestamp': DateTime.now().toIso8601String(),
          });
        }
      } else {
        setError("Received empty response from Gemini.");
        notifyListeners();
      }
    } catch (e) {
      setError("Error: $e");
    } finally {
      isGenerating = false;
      notifyListeners();
    }
  }

  Future<void> _addAssistantMessage(String text) async {
    ChatMessage assistantMessage = ChatMessage(
      sessionId: currentSession?.id,
      content: text,
      isUser: false,
      timestamp: DateTime.now(),
    );
    final id = await db!.insert('messages', assistantMessage.toMap());
    assistantMessage.id = id;
    messages.add(assistantMessage);
    notifyListeners();
  }

  Future<void> loadMessages() async {
    if (currentSession == null) return;
    await loadDB();
    final result = await db!.query('messages', where: 'sessionId = ?', whereArgs: [currentSession!.id]);
    messages = result.map((e) => ChatMessage.fromMap(e)).toList();
    notifyListeners();
  }

  String? selectedImagePath; // used for OCR loading UI
  bool isProcessingImage = false;
  
  String? pendingAttachmentPath; // used for standard attachments

  void attachImage(String path) {
    pendingAttachmentPath = path;
    notifyListeners();
  }

  void removeAttachment() {
    pendingAttachmentPath = null;
    notifyListeners();
  }

  Future<String?> processImageAttachment(String imagePath) async {
    selectedImagePath = imagePath;
    isProcessingImage = true;
    notifyListeners();

    try {
      final extractedText = await OCRService.extractTextFromImage(imagePath);
      return "I have scanned a document. Text extracted via OCR:\n\n$extractedText\n\nPlease analyze this document, summarize it, and save it to the knowledge base using the DocumentTool.";
    } catch (e) {
      setError("OCR Error: $e");
      return null;
    } finally {
      selectedImagePath = null;
      isProcessingImage = false;
      notifyListeners();
    }
  }

  Future<void> updateMessages(
    int id,
    String content,
    bool isUser,
    DateTime timestamp,
  ) async {
    await loadDB();
    if (content.isEmpty) {
      throw Exception("Mandatory fields must not be empty");
    }

    ChatMessage message = ChatMessage(
      sessionId: currentSession?.id,
      content: content,
      isUser: isUser,
      timestamp: timestamp,
    );
    message.id = id;

    await db!.update(
      'messages',
      message.toMap(),
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> clearChat() async {
    if (currentSession == null) return;
    await loadDB();
    await db!.delete('messages', where: 'sessionId = ?', whereArgs: [currentSession!.id]);

    messages.clear();

    notifyListeners();
  }

  Future<void> deleteMessage(int id) async {
    await loadDB();
    await db!.delete('messages', where: 'id = ?', whereArgs: [id]);
    messages.removeWhere((m) => m.id == id);
    notifyListeners();
  }
}

