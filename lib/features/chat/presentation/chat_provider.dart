// ignore_for_file: unused_local_variable, unnecessary_null_comparison

import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart'
    as gen_ai
    show ChatSession;
import 'package:google_generative_ai/google_generative_ai.dart'
    hide ChatSession;
import 'package:mobile_assistant/core/agent/agent_service.dart';
import 'package:mobile_assistant/core/agent/tools/document_tool.dart';
import 'package:mobile_assistant/core/agent/tools/memory_tool.dart';
import 'package:mobile_assistant/core/services/analytics_service.dart';
import 'package:mobile_assistant/core/services/inference_service.dart';
import 'package:mobile_assistant/core/services/ocr_service.dart';
import 'package:mobile_assistant/features/chat/data/chat_repository.dart';
import 'package:mobile_assistant/features/memory/presentation/providers/memory_providers.dart';
import 'package:mobile_assistant/features/tasks/presentation/tasks_provider.dart';
import 'package:mobile_assistant/shared/models/agent_step.dart';
import 'package:mobile_assistant/shared/models/chat_message.dart';
import 'package:mobile_assistant/shared/models/chat_session.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'chat_provider.g.dart';

class ChatState {

  ChatState({
    this.sessions = const [],
    this.currentSession,
    this.messages = const [],
    this.isGenerating = false,
    this.modelError,
    this.currentPlan = const [],
    this.pendingAttachmentPath,
    this.selectedImagePath,
    this.isProcessingImage = false,
  });
  final List<ChatSession> sessions;
  final ChatSession? currentSession;
  final List<ChatMessage> messages;
  final bool isGenerating;
  final String? modelError;
  final List<AgentStep> currentPlan;
  final String? pendingAttachmentPath;
  final String? selectedImagePath;
  final bool isProcessingImage;

  ChatState copyWith({
    List<ChatSession>? sessions,
    ChatSession? currentSession,
    List<ChatMessage>? messages,
    bool? isGenerating,
    String? modelError,
    List<AgentStep>? currentPlan,
    String? pendingAttachmentPath,
    String? selectedImagePath,
    bool? isProcessingImage,
    bool clearError = false,
    bool clearAttachment = false,
    bool clearSelectedImage = false,
  }) {
    return ChatState(
      sessions: sessions ?? this.sessions,
      currentSession: currentSession ?? this.currentSession,
      messages: messages ?? this.messages,
      isGenerating: isGenerating ?? this.isGenerating,
      modelError: clearError ? null : (modelError ?? this.modelError),
      currentPlan: currentPlan ?? this.currentPlan,
      pendingAttachmentPath: clearAttachment
          ? null
          : (pendingAttachmentPath ?? this.pendingAttachmentPath),
      selectedImagePath: clearSelectedImage
          ? null
          : (selectedImagePath ?? this.selectedImagePath),
      isProcessingImage: isProcessingImage ?? this.isProcessingImage,
    );
  }
}

// Backwards-compatible aliases for older provider names
final ChatNotifierProvider chatNotifierProvider = chatProvider;

@riverpod
class ChatNotifier extends _$ChatNotifier {
  late ChatRepository _repository;

  @override
  ChatState build() {
    _repository = ref.watch(chatRepositoryProvider);
    _init();
    return ChatState();
  }

  Future<void> _init() async {
    final sessions = await _repository.getSessions();
    ChatSession current;
    List<ChatSession> allSessions;

    if (sessions.isNotEmpty) {
      current = sessions.first;
      allSessions = sessions;
    } else {
      current = ChatSession(title: 'New Chat', createdAt: DateTime.now());
      current = await _repository.insertSession(current);
      allSessions = [current];
    }

    state = state.copyWith(
      sessions: allSessions,
      currentSession: current,
      messages: [],
      currentPlan: [],
    );

    if (sessions.isNotEmpty) {
      await loadMessages();
      await _cleanupAndResume();
    }
  }

  Future<void> _cleanupAndResume() async {
    final messages = state.messages;
    if (messages.isEmpty) return;

    final hiMessages = messages.where((m) => m.content.toLowerCase().trim() == 'hi' && m.isUser).toList();
    if (hiMessages.length > 1) {
      for (int i = 0; i < hiMessages.length - 1; i++) {
        if (hiMessages[i].id != null) {
          await _repository.deleteMessage(hiMessages[i].id!);
        }
      }
      await loadMessages();
    }

    if (state.messages.isNotEmpty && state.messages.last.isUser) {
      _generateAssistantResponse();
    }
  }

  void setError(String err) {
    state = state.copyWith(modelError: err);
  }

  void clearErrors() {
    state = state.copyWith(clearError: true);
  }

  Future<void> createNewSession() async {
    var newSession = ChatSession(
      title: 'New Chat',
      createdAt: DateTime.now(),
    );
    newSession = await _repository.insertSession(newSession);
    final sessions = [newSession, ...state.sessions];
    state = state.copyWith(
      sessions: sessions,
      currentSession: newSession,
      messages: [],
      currentPlan: [],
    );
  }

  Future<void> switchSession(ChatSession session) async {
    state = state.copyWith(currentSession: session, currentPlan: []);
    await loadMessages();
  }

  Future<void> deleteSession(int sessionId) async {
    await _repository.deleteSession(sessionId);
    final sessions = state.sessions.where((s) => s.id != sessionId).toList();
    if (state.currentSession?.id == sessionId) {
      if (sessions.isNotEmpty) {
        state = state.copyWith(
          sessions: sessions,
          currentSession: sessions.first,
        );
        await loadMessages();
      } else {
        state = state.copyWith(sessions: sessions);
        await createNewSession();
      }
    } else {
      state = state.copyWith(sessions: sessions);
    }
  }

  Future<void> _generateChatTitle(String firstMessage) async {
    if (state.currentSession == null ||
        state.currentSession!.title != 'New Chat' ||
        InferenceService.instance.strategy == InferenceStrategy.localOnly) {
      return;
    }
    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) return;
      final fallbackModels = [
        'gemini-2.5-flash-lite-preview-06-17',
        'gemini-2.5-flash',
        'gemini-2.5-pro',
      ];
      GenerateContentResponse? response;

      for (final modelName in fallbackModels) {
        try {
          final model = GenerativeModel(model: modelName, apiKey: apiKey);
          response = await model.generateContent([
            Content.text(
              "Generate a short, 2-4 word title for this chat based on the user's first message: '$firstMessage'. Only return the title.",
            ),
          ]);
          break;
        } catch (e) {
          logger.e('Chat Title Model $modelName failed', error: e);
        }
      }

      if (response == null) return;

      final title = response.text?.trim() ?? 'New Chat';
      final session = state.currentSession!;
      session.title = title;
      await _repository.updateSession(session);

      final sessions = state.sessions
          .map((s) => s.id == session.id ? session : s)
          .toList();
      state = state.copyWith(sessions: sessions, currentSession: session);
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
    if (content.trim().isEmpty) return;
    if (state.currentSession == null) await createNewSession();

    var message = ChatMessage(
      sessionId: state.currentSession!.id,
      content: content,
      isUser: isUser,
      timestamp: timestamp,
      attachmentPath: isUser ? state.pendingAttachmentPath : null,
    );

    if (isUser) {
      state = state.copyWith(clearAttachment: true, currentPlan: []);
    } else {
      state = state.copyWith(currentPlan: []);
    }

    message = await _repository.insertMessage(message);
    state = state.copyWith(messages: [...state.messages, message]);

    if (isUser) {
      if (state.messages.length == 1 ||
          state.currentSession!.title == 'New Chat') {
        _generateChatTitle(content);
      }
      await _generateAssistantResponse();
    }
  }

  Future<void> _generateAssistantResponse() async {
    state = state.copyWith(isGenerating: true);

    try {
      final svc = InferenceService.instance;
      final isLocalOnly = svc.strategy == InferenceStrategy.localOnly;

      // For local-only, verify model is available before anything else
      if (isLocalOnly && !svc.isLocalModelLoaded) {
        setError(
          '⚠️ Local Gemma model is not loaded. Go to Settings → Inference Strategy and switch to Hybrid or Cloud mode.',
        );
        return;
      }

      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (!isLocalOnly && (apiKey == null || apiKey.isEmpty)) {
        setError('API Key not found. Add your GEMINI_API_KEY to the .env file.');
        return;
      }

      final tasksAsync = ref.read(tasksProvider);
      final currentTasks = tasksAsync.value ?? [];
      final tasksContext = currentTasks
          .map(
            (t) =>
                "{id: ${t.id}, title: '${t.title}', priority: '${t.priority.name}', dueDate: '${t.dueDate.toIso8601String()}'}",
          )
          .join(',\n');

      final prompt = state.messages.last.content;
      final memoryTool = MemoryTool(ref.read(memoryRepositoryProvider));
      final documentTool = DocumentTool();

      String memoryContext = '';
      String documentContext = '';
      try {
        memoryContext = await memoryTool.searchMemories(prompt);
        documentContext = await documentTool.searchDocumentsRAG(prompt);
      } catch (e) {
        logger.w('Failed to fetch RAG context (offline or error)', error: e);
      }

      final systemInstruction = '''
You are a proactive local agent. Use the provided tools to fulfill requests.
Current time: ${DateTime.now().toIso8601String()}
Pending tasks: [$tasksContext]

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

      final fallbackModels = [
        'gemini-2.5-flash-lite-preview-06-17',
        'gemini-2.5-flash',
        'gemini-2.5-pro',
      ];
      InferenceResponse? inferenceResponse;
      gen_ai.ChatSession? aiChatSession;
      Exception? lastException;

      final chatHistory = state.messages
          .where((m) => m.id != state.messages.last.id)
          .map((m) {
            if (m.attachmentPath != null &&
                File(m.attachmentPath!).existsSync()) {
              final bytes = File(m.attachmentPath!).readAsBytesSync();
              return Content(m.isUser ? 'user' : 'model', [
                TextPart(m.content),
                DataPart('image/jpeg', bytes),
              ]);
            }
            return Content(m.isUser ? 'user' : 'model', [
              TextPart(m.content),
            ]);
          })
          .toList();

      final lastMsg = state.messages.last;
      Content requestContent;
      if (lastMsg.attachmentPath != null &&
          File(lastMsg.attachmentPath!).existsSync()) {
        final bytes = File(lastMsg.attachmentPath!).readAsBytesSync();
        requestContent = Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', bytes),
        ]);
      } else {
        requestContent = Content.text(prompt);
      }

      // final isLocalOnly = svc.strategy == InferenceStrategy.localOnly;
      
      if (isLocalOnly) {
        try {
          inferenceResponse = await InferenceService.instance
              .generateChatResponse(
                chatHistory: chatHistory,
                prompt: requestContent,
                systemInstruction: systemInstruction,
                cloudModelName: '',
                cloudApiKey: '',
                tools: [ref.read(agentServiceProvider).getTools()],
              );
        } catch (e) {
          logger.w('Local Inference failed', error: e);
          setError('Local generation failed: $e');
          return;
        }
      } else {
        for (final modelName in fallbackModels) {
          try {
            inferenceResponse = await InferenceService.instance
                .generateChatResponse(
                  chatHistory: chatHistory,
                  prompt: requestContent,
                  systemInstruction: systemInstruction,
                  cloudModelName: modelName,
                  cloudApiKey: apiKey ?? '',
                  tools: [ref.read(agentServiceProvider).getTools()],
                );

            aiChatSession = inferenceResponse.cloudSession;
            break; // Success
          } on Exception catch (e) {
            lastException = e;
            logger.w('Inference failed for $modelName', error: e);
          }
        }
      }

      if (inferenceResponse == null) {
        // Cloud models failed. If we're in hybrid mode, attempt local fallback.
        if (!isLocalOnly && svc.strategy == InferenceStrategy.hybrid) {
          if (svc.isLocalModelLoaded) {
            try {
              // Re-route to generateChatResponse via local strategy trick
              // We'll temporarily set strategy to localOnly for this call
              final previous = svc.strategy;
              svc.strategy = InferenceStrategy.localOnly;
              inferenceResponse = await svc.generateChatResponse(
                chatHistory: chatHistory,
                prompt: requestContent,
                systemInstruction: systemInstruction,
                cloudModelName: '',
                cloudApiKey: '',
              );
              svc.strategy = previous;
            } catch (e) {
              setError('Cloud failed (${lastException.toString()}) AND Local fallback failed: $e');
              return;
            }
          } else {
            setError(
                'Cloud models failed (e.g. quota exceeded) and Local Gemma model is not loaded. Download it in Settings to enable offline fallback.');
            return;
          }
        } else {
          if (lastException.toString().toLowerCase().contains('spike') || lastException.toString().contains('503') || lastException.toString().toLowerCase().contains('overloaded')) {
            setError('All cloud models are currently overloaded. Please try again later or switch to local inference.');
          } else {
            setError('Failed to generate response. Please try again.');
          }
          return;
        }
      }

      if (inferenceResponse == null ||
          (inferenceResponse.text == null &&
           inferenceResponse.functionCalls.isEmpty)) {
        setError('Received empty response from assistant.');
        return;
      }

      var currentFunctionCalls = inferenceResponse.functionCalls;
      var responseText = inferenceResponse.text;

      while (currentFunctionCalls.isNotEmpty && aiChatSession != null) {
        final calls = currentFunctionCalls.toList();
        final functionResponses = <FunctionResponse>[];

        for (final call in calls) {
          if (call.name == 'create_execution_plan') {
            final steps = call.args['steps'] as List<dynamic>? ?? [];
            final plan = List<AgentStep>.from(state.currentPlan);
            for (final step in steps) {
              plan.add(AgentStep('Plan: $step'));
            }
            state = state.copyWith(currentPlan: plan);
            functionResponses.add(
              FunctionResponse(call.name, {
                'result': 'Plan acknowledged by user interface.',
              }),
            );
            continue;
          }

          // Add step to UI
          final plan = List<AgentStep>.from(state.currentPlan);
          plan.add(AgentStep('Executing ${call.name}...'));
          state = state.copyWith(currentPlan: plan);

          final result = await ref
              .read(agentServiceProvider)
              .dispatchFunctionCall(call);

          final updatedPlan = List<AgentStep>.from(state.currentPlan);
          updatedPlan.last.isCompleted = true;
          updatedPlan.last.result =
              result['result']?.toString() ?? result['error']?.toString();
          state = state.copyWith(currentPlan: updatedPlan);

          functionResponses.add(FunctionResponse(call.name, result));
        }

        // Send results back to Gemini
        try {
          final toolResponse = await aiChatSession.sendMessage(
            Content.functionResponses(functionResponses),
          );
          currentFunctionCalls = toolResponse.functionCalls.toList();
          responseText = toolResponse.text;
        } catch (e) {
          logger.w('Tool response failed', error: e);
          if (e.toString().toLowerCase().contains('spike') || e.toString().contains('503') || e.toString().toLowerCase().contains('overloaded')) {
            setError('The cloud model is currently experiencing high traffic spikes. Please try again later or switch to local inference.');
          } else {
            setError('An error occurred while calling tools. Please try again.');
          }
          return;
        }
      }

      final finalResponseText = responseText?.trim();
      if (finalResponseText != null && finalResponseText.isNotEmpty) {
        await _addAssistantMessage(finalResponseText);
      }
    } catch (e) {
      setError('Error: $e');
    } finally {
      state = state.copyWith(isGenerating: false);
    }
  }

  Future<void> _addAssistantMessage(String text) async {
    var assistantMessage = ChatMessage(
      sessionId: state.currentSession?.id,
      content: text,
      isUser: false,
      timestamp: DateTime.now(),
    );
    assistantMessage = await _repository.insertMessage(assistantMessage);
    state = state.copyWith(messages: [...state.messages, assistantMessage]);
  }

  Future<void> loadMessages() async {
    if (state.currentSession == null) return;
    final messages = await _repository.getMessages(state.currentSession!.id!);
    state = state.copyWith(messages: messages);
  }

  void attachImage(String path) {
    state = state.copyWith(pendingAttachmentPath: path);
  }

  void removeAttachment() {
    state = state.copyWith(clearAttachment: true);
  }

  Future<String?> processImageAttachment(String imagePath) async {
    state = state.copyWith(
      selectedImagePath: imagePath,
      isProcessingImage: true,
    );

    try {
      final extractedText = await OCRService.extractTextFromImage(imagePath);
      return 'I have scanned a document. Text extracted via OCR:\n\n$extractedText\n\nPlease analyze this document, summarize it, and save it to the knowledge base using the DocumentTool.';
    } catch (e) {
      setError('OCR Error: $e');
      return null;
    } finally {
      state = state.copyWith(
        clearSelectedImage: true,
        isProcessingImage: false,
      );
    }
  }

  Future<void> clearChat() async {
    if (state.currentSession == null) return;
    await _repository.clearMessagesForSession(state.currentSession!.id!);
    state = state.copyWith(messages: []);
  }

  Future<void> deleteMessage(int id) async {
    await _repository.deleteMessage(id);
    final messages = state.messages.where((m) => m.id != id).toList();
    state = state.copyWith(messages: messages);
  }
}
