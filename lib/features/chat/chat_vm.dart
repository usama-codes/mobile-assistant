import 'dart:io';
import 'package:flutter/material.dart' hide ActionDispatcher;
import 'dart:math' as math;
import 'package:mobile_assistant/core/db/app_database.dart';
import 'package:mobile_assistant/shared/models/chat_session.dart';
import 'package:mobile_assistant/shared/models/chat_message.dart';
import 'package:mobile_assistant/shared/models/task_item.dart';
import 'package:mobile_assistant/shared/models/agent_step.dart';
import 'package:mobile_assistant/core/services/action_dispatcher.dart';
import 'package:mobile_assistant/core/agent/tools/memory_tool.dart';
import 'package:mobile_assistant/core/agent/tools/document_tool.dart';
import 'package:google_generative_ai/google_generative_ai.dart' hide ChatSession;
import 'package:google_generative_ai/google_generative_ai.dart' as gen_ai show ChatSession;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mobile_assistant/core/services/ocr_service.dart';
import 'package:sqflite/sqflite.dart';

class ChatVM extends ChangeNotifier {
  Database? db;
  List<ChatSession> sessions = [];
  ChatSession? currentSession;
  List<ChatMessage> messages = [];

  bool isGenerating = false;
  String? modelError;
  bool get hasError => modelError != null;

  List<AgentStep> currentPlan = [];

  final TextEditingController messageController = TextEditingController();

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }

  Future<void> loadDB() async {
    db ??= await AppDatabase.instance.database;
  }

  void setError(String err) {
    modelError = err;
    notifyListeners();
  }

  void clearErrors() {
    modelError = null;
    notifyListeners();
  }

  Future<void> loadSessions() async {
    await loadDB();
    final result = await db!.query('chat_sessions', orderBy: 'createdAt DESC');
    sessions = result.map((e) => ChatSession.fromMap(e)).toList();
    if (currentSession == null) {
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
    currentPlan.clear();
    notifyListeners();
  }

  Future<void> switchSession(ChatSession session) async {
    currentSession = session;
    currentPlan.clear();
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
      if (apiKey == null || apiKey.isEmpty) return;
      final fallbackModels = ['gemini-2.5-flash', 'gemini-2.5-pro', 'gemini-1.5-pro', 'gemini-1.5-flash'];
      GenerateContentResponse? response;
      
      for (final modelName in fallbackModels) {
        try {
          final model = GenerativeModel(model: modelName, apiKey: apiKey);
          response = await model.generateContent([
            Content.text("Generate a short, 2-4 word title for this chat based on the user's first message: '$firstMessage'. Only return the title.")
          ]);
          break;
        } catch (e) {
          debugPrint("Chat Title Model $modelName failed: $e");
        }
      }

      if (response == null) return;
      
      final title = response.text?.trim() ?? "New Chat";
      currentSession!.title = title;
      await db!.update('chat_sessions', currentSession!.toMap(), where: 'id = ?', whereArgs: [currentSession!.id]);
      int index = sessions.indexWhere((s) => s.id == currentSession!.id);
      if (index != -1) sessions[index] = currentSession!;
      notifyListeners();
    } catch (e) {
      // ignore
    }
  }

  Future<void> sendMessage(
    String content,
    DateTime timestamp, {
    required bool isUser,
  }) async {
    clearErrors();
    await loadDB();
    if (content.trim().isEmpty) return;
    if (currentSession == null) await createNewSession();

    ChatMessage message = ChatMessage(
      sessionId: currentSession!.id,
      content: content,
      isUser: isUser,
      timestamp: timestamp,
      attachmentPath: isUser ? pendingAttachmentPath : null,
    );
    
    if (isUser) pendingAttachmentPath = null;
    currentPlan.clear();

    final id = await db!.insert('messages', message.toMap());
    message.id = id;
    messages.add(message);
    notifyListeners();

    if (isUser) {
      if (messages.length == 1 || currentSession!.title == 'New Chat') {
        _generateChatTitle(content);
      }
      await _generateAssistantResponse();
    }
  }

  Tool _getAgentTools() {
    return Tool(functionDeclarations: [
      FunctionDeclaration(
        'create_execution_plan',
        'State a multi-step execution plan before executing complex requests',
        Schema(SchemaType.object, properties: {
          'steps': Schema(SchemaType.array, items: Schema(SchemaType.string)),
        }, requiredProperties: ['steps']),
      ),
      FunctionDeclaration(
        'create_task',
        'Create a new task',
        Schema(SchemaType.object, properties: {
          'title': Schema(SchemaType.string),
          'description': Schema(SchemaType.string),
          'dueDate': Schema(SchemaType.string, description: 'ISO8601 string'),
          'priority': Schema(SchemaType.string, description: 'low, medium, high'),
        }, requiredProperties: ['title']),
      ),
      FunctionDeclaration(
        'edit_task',
        'Edit an existing task',
        Schema(SchemaType.object, properties: {
          'id': Schema(SchemaType.integer),
          'title': Schema(SchemaType.string),
          'dueDate': Schema(SchemaType.string),
        }, requiredProperties: ['id']),
      ),
      FunctionDeclaration(
        'delete_task',
        'Delete a task',
        Schema(SchemaType.object, properties: {'id': Schema(SchemaType.integer)}, requiredProperties: ['id']),
      ),
      FunctionDeclaration(
        'remember_fact',
        'Save a fact to long-term memory',
        Schema(SchemaType.object, properties: {
          'fact': Schema(SchemaType.string),
          'importance': Schema(SchemaType.number),
          'is_sensitive': Schema(SchemaType.boolean),
        }, requiredProperties: ['fact']),
      ),
      FunctionDeclaration(
        'create_document',
        'Save a document',
        Schema(SchemaType.object, properties: {
          'title': Schema(SchemaType.string),
          'content': Schema(SchemaType.string),
          'folder': Schema(SchemaType.string),
          'is_sensitive': Schema(SchemaType.boolean),
        }, requiredProperties: ['title', 'content']),
      ),
      FunctionDeclaration(
        'process_nlp',
        'Process document with NLP',
        Schema(SchemaType.object, properties: {
          'id': Schema(SchemaType.integer),
          'operation': Schema(SchemaType.string, description: 'summarize, translate, extract_entities, extract_keywords, generate_flashcards, generate_study_guide, extract_tasks'),
        }, requiredProperties: ['id', 'operation']),
      ),
      FunctionDeclaration(
        'ask_user',
        'Ask the user a clarifying question to resolve a conflict or ambiguity',
        Schema(SchemaType.object, properties: {
          'question': Schema(SchemaType.string),
        }, requiredProperties: ['question']),
      )
    ]);
  }

  Future<void> _generateAssistantResponse() async {
    isGenerating = true;
    notifyListeners();

    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        setError("API Key not found.");
        return;
      }

      await loadDB();
      final tasksResult = await db!.query('tasks', where: 'completed = 0');
      final currentTasks = tasksResult.map((e) => TaskItem.fromMap(e)).toList();
      final tasksContext = currentTasks.map((t) => "{id: ${t.id}, title: '${t.title}', priority: '${t.priority.name}', dueDate: '${t.dueDate.toIso8601String()}'}").join(",\n");

      final prompt = messages.last.content;
      final memoryTool = MemoryTool();
      final documentTool = DocumentTool();
      
      final memoryContext = await memoryTool.searchMemories(prompt);
      final documentContext = await documentTool.searchDocumentsRAG(prompt);

      final logsResult = await db!.query('interaction_logs', orderBy: 'timestamp DESC', limit: 5);
      final recentLogs = logsResult.reversed.map((l) => "- Called ${l['executedAction']} during message '${l['userMessage']}'. Result: ${l['status']}").join('\n');

      final systemInstruction = '''
You are a proactive local agent. Use the provided tools to fulfill requests.
Current time: ${DateTime.now().toIso8601String()}
Pending tasks: [$tasksContext]

Recent Actions Context (Use this to resolve "it" references):
$recentLogs

Relevant Memories: 
$memoryContext

Relevant Documents:
$documentContext

- For highly complex or multi-part requests, call the `create_execution_plan` tool FIRST to state your plan before executing the actual actions.
- You may execute multiple tool calls simultaneously if the user asks you to perform multiple actions at once.
- Proactively use the `remember_fact` tool to save any user preferences, long-term goals, or recurring interests you notice in the conversation. Ask first using `ask_user` if the information seems highly sensitive.
- Only invoke tools if an action is requested. If the user asks a general question, just reply.
- Use `ask_user` if a request is highly ambiguous (e.g., "Schedule a meeting on Friday" when there are multiple Fridays).
- Always calculate relative dates accurately based on Current time.
''';

      final fallbackModels = ['gemini-2.5-flash', 'gemini-2.5-pro', 'gemini-1.5-pro', 'gemini-1.5-flash'];
      GenerateContentResponse? response;
      gen_ai.ChatSession? aiChatSession;
      Exception? lastException;

      for (final modelName in fallbackModels) {
        try {
          final model = GenerativeModel(
            model: modelName,
            apiKey: apiKey,
            systemInstruction: Content.system(systemInstruction),
            tools: [_getAgentTools()],
          );

          final chatHistory = messages.where((m) => m.id != messages.last.id).map((m) {
            if (m.attachmentPath != null && File(m.attachmentPath!).existsSync()) {
              final bytes = File(m.attachmentPath!).readAsBytesSync();
              return Content(m.isUser ? 'user' : 'model', [TextPart(m.content), DataPart('image/jpeg', bytes)]);
            }
            return Content(m.isUser ? 'user' : 'model', [TextPart(m.content)]);
          }).toList();

          aiChatSession = model.startChat(history: chatHistory);
          
          final lastMsg = messages.last;
          Content requestContent;
          if (lastMsg.attachmentPath != null && File(lastMsg.attachmentPath!).existsSync()) {
            final bytes = File(lastMsg.attachmentPath!).readAsBytesSync();
            requestContent = Content.multi([TextPart(prompt), DataPart('image/jpeg', bytes)]);
          } else {
            requestContent = Content.text(prompt);
          }

          response = await aiChatSession.sendMessage(requestContent);
          break; // Success
        } catch (e) {
          lastException = e is Exception ? e : Exception(e.toString());
          debugPrint("Assistant Model $modelName failed: $e");
        }
      }

      if (response == null || aiChatSession == null) {
        throw lastException ?? Exception("All fallback models failed.");
      }

      while (response!.functionCalls.isNotEmpty) {
        final calls = response!.functionCalls.toList();
        final List<FunctionResponse> functionResponses = [];
        
        for (final call in calls) {
          if (call.name == 'create_execution_plan') {
            final steps = call.args['steps'] as List<dynamic>? ?? [];
            for (var step in steps) {
              currentPlan.add(AgentStep("Plan: $step"));
            }
            notifyListeners();
            functionResponses.add(FunctionResponse(call.name, {'result': 'Plan acknowledged by user interface.'}));
            continue;
          }

          // Add step to UI
          currentPlan.add(AgentStep("Executing ${call.name}..."));
          notifyListeners();

          final result = await ActionDispatcher.dispatchFunctionCall(call);
          
          currentPlan.last.isCompleted = true;
          currentPlan.last.result = result['result']?.toString() ?? result['error']?.toString();
          notifyListeners();

          functionResponses.add(FunctionResponse(call.name, result));

          await db!.insert('interaction_logs', {
            'userMessage': prompt,
            'geminiResponse': '',
            'executedAction': call.name,
            'status': result['error'] != null ? 'Failure: ${result['error']}' : 'Success: ${result['result']}',
            'timestamp': DateTime.now().toIso8601String(),
          });
        }

        // Send results back to Gemini
        response = await aiChatSession.sendMessage(Content.functionResponses(functionResponses));
      }

      final responseText = response!.text?.trim();
      if (responseText != null && responseText.isNotEmpty) {
        await _addAssistantMessage(responseText);
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

  String? selectedImagePath;
  bool isProcessingImage = false;
  String? pendingAttachmentPath;

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

  Future<void> updateMessages(int id, String content, bool isUser, DateTime timestamp) async {
    await loadDB();
    ChatMessage message = ChatMessage(sessionId: currentSession?.id, content: content, isUser: isUser, timestamp: timestamp);
    message.id = id;
    await db!.update('messages', message.toMap(), where: 'id = ?', whereArgs: [id]);
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
