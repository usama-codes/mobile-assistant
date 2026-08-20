// ignore_for_file: unused_local_variable, unnecessary_null_comparison

import 'dart:async';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart'
    as gen_ai
    show ChatSession;
import 'package:google_generative_ai/google_generative_ai.dart'
    hide ChatSession;
import 'package:mobile_assistant/core/agent/action_extractor.dart';
import 'package:mobile_assistant/core/agent/agent_service.dart';
import 'package:mobile_assistant/core/agent/tools/document_tool.dart';
import 'package:mobile_assistant/core/agent/tools/memory_tool.dart';
import 'package:mobile_assistant/core/services/analytics_service.dart';
import 'package:mobile_assistant/core/services/voice_service.dart';
import 'package:mobile_assistant/core/services/inference_service.dart';
import 'package:mobile_assistant/core/services/ocr_service.dart';
import 'package:mobile_assistant/features/chat/data/chat_repository.dart';
import 'package:mobile_assistant/features/memory/presentation/providers/memory_providers.dart';
import 'package:mobile_assistant/features/settings/presentation/settings_provider.dart';
import 'package:mobile_assistant/features/tasks/presentation/tasks_provider.dart';
import 'package:mobile_assistant/shared/models/action_proposal.dart';
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
    this.pendingAction,
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

  /// A proposed action awaiting user confirmation before any write.
  final ActionProposal? pendingAction;

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
    ActionProposal? pendingAction,
    bool clearError = false,
    bool clearAttachment = false,
    bool clearSelectedImage = false,
    bool clearPendingAction = false,
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
      pendingAction: clearPendingAction
          ? null
          : (pendingAction ?? this.pendingAction),
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
    
    var current = ChatSession(title: 'New Chat', createdAt: DateTime.now());
    current = await _repository.insertSession(current);
    
    final allSessions = [current, ...sessions];

    state = state.copyWith(
      sessions: allSessions,
      currentSession: current,
      messages: [],
      currentPlan: [],
    );
  }


  void setError(String err) {
    state = state.copyWith(modelError: err);
  }

  void clearErrors() {
    state = state.copyWith(clearError: true);
  }

  // ── Action confirmation gate ─────────────────────────────────────────────
  Completer<ActionProposal?>? _confirmationCompleter;

  /// Show the confirmation card and suspend execution until the user decides.
  Future<ActionProposal?> _awaitConfirmation(ActionProposal proposal) async {
    _confirmationCompleter = Completer<ActionProposal?>();
    state = state.copyWith(pendingAction: proposal);
    final confirmed = await _confirmationCompleter!.future;
    _confirmationCompleter = null;
    state = state.copyWith(clearPendingAction: true);
    return confirmed;
  }

  /// User tapped ✅ Confirm on the action card — deliver proposal upstream.
  void confirmAction(ActionProposal confirmed) {
    _confirmationCompleter?.complete(confirmed);
  }

  /// User tapped ❌ Cancel on the action card — discard the proposal.
  void cancelAction() {
    _confirmationCompleter?.complete(null);
  }

  /// Build an [ActionProposal] from a cloud model function call so it can be
  /// reviewed before any calendar write.
  ActionProposal? _proposalFromFunctionCall(FunctionCall call) {
    final args = call.args;
    final title = args['title'] as String?;
    if (title == null || title.trim().isEmpty) return null;

    final start = _parseDateArg(args['startDate']);
    final end = _parseDateArg(args['endDate']) ??
        (start?.add(const Duration(hours: 1)));
    return ActionProposal(
      action: call.name,
      title: title.trim(),
      startDate: start,
      endDate: end,
      description: args['description'] as String?,
      location: args['location'] as String?,
      confidence: 0.85, // model-initiated calls are explicit intents
    );
  }

  DateTime? _parseDateArg(dynamic value) {
    if (value == null) return null;
    try {
      return DateTime.parse(value as String);
    } catch (_) {
      return null;
    }
  }

  /// Execute a confirmed proposal through the agent tool registry.
  Future<Map<String, Object?>> _executeProposal(
    ActionProposal proposal,
  ) async {
    final agentService = ref.read(agentServiceProvider);
    switch (proposal.action) {
      case 'create_calendar_event':
        return agentService.dispatchFunctionCall(
          FunctionCall('create_calendar_event', proposal.toCalendarParams()),
        );
      case 'create_task':
        return agentService.dispatchFunctionCall(
          FunctionCall('create_task', proposal.toTaskParams()),
        );
      case 'log_expense':
        return agentService.dispatchFunctionCall(
          FunctionCall('log_expense', proposal.toExpenseParams()),
        );
      default:
        return {'error': 'Unknown action: ${proposal.action}'};
    }
  }

  /// Run a confirmed proposal, tracking progress as a plan step.
  Future<void> _executeProposalAndRecord(ActionProposal proposal) async {
    final plan = List<AgentStep>.from(state.currentPlan);
    plan.add(AgentStep('Executing ${proposal.action}...'));
    state = state.copyWith(currentPlan: plan);

    final result = await _executeProposal(proposal);

    final updatedPlan = List<AgentStep>.from(state.currentPlan);
    updatedPlan.last.isCompleted = true;
    updatedPlan.last.result =
        result['result']?.toString() ?? result['error']?.toString();
    state = state.copyWith(currentPlan: updatedPlan);
  }

  Future<void> createNewSession() async {
    var newSession = ChatSession(title: 'New Chat', createdAt: DateTime.now());
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
        'gemini-2.5-flash',
        'gemini-2.0-flash',
        'gemini-2.5-flash-lite-preview-06-17',
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
      // Lazy-load Gemma on first inference (deferred from startup).
      await InferenceService.instance.warmUp();

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
        setError(
          'API Key not found. Add your GEMINI_API_KEY to the .env file.',
        );
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

      // ── PRIVACY BOUNDARY ────────────────────────────────────────────────
      // Retrieved document content must NEVER reach a cloud API. If relevant
      // documents were found, the answer is generated on-device regardless of
      // the configured strategy. If the local model isn't available, tell the
      // user why rather than silently leaking content to the cloud.
      final hasDocContext = documentContext.isNotEmpty;
      if (hasDocContext && !svc.isLocalModelLoaded) {
        setError(
          'This question references your saved documents. '
          'Document-aware answers are generated on-device for privacy — '
          'enable the local Gemma model in Settings to continue.',
        );
        return;
      }
      final mustUseLocal = isLocalOnly || hasDocContext;

      final systemInstruction =
          '''
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
- Proactively use calendar tools to manage the user's schedule and events.
- Proactively use expense tools to track financial transactions when mentioned.
- Only invoke tools if an action is requested. If the user asks a general question, just reply.
- Use `ask_user` if a request is highly ambiguous (e.g., "Schedule a meeting on Friday" when there are multiple Fridays).
- Always calculate relative dates accurately based on Current time.
''';

      final fallbackModels = [
        'gemini-2.5-flash',
        'gemini-2.0-flash',
        'gemini-2.5-flash-lite-preview-06-17',
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
            return Content(m.isUser ? 'user' : 'model', [TextPart(m.content)]);
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

      if (mustUseLocal) {
        // Force local generation — either the user chose local-only, or
        // document context requires on-device answers for privacy.
        final previous = svc.strategy;
        if (!isLocalOnly) svc.strategy = InferenceStrategy.localOnly;
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
        } finally {
          if (!isLocalOnly) svc.strategy = previous;
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
              setError(
                'Cloud failed (${lastException.toString()}) AND Local fallback failed: $e',
              );
              return;
            }
          } else {
            setError(
              'Cloud models failed (e.g. quota exceeded) and Local Gemma model is not loaded. Download it in Settings to enable offline fallback.',
            );
            return;
          }
        } else {
          final errStr = lastException?.toString() ?? 'Unknown error';
          if (errStr.toLowerCase().contains('spike') ||
              errStr.contains('503') ||
              errStr.toLowerCase().contains('overloaded')) {
            setError(
              'All cloud models are currently overloaded. Please try again later or switch to local inference.',
            );
          } else {
            // Show the real error so we can diagnose it
            setError('API Error: $errStr');
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

          // ── Confirm gate: no calendar write without explicit user OK ────
          if (call.name == 'create_calendar_event') {
            final proposal = _proposalFromFunctionCall(call);
            if (proposal != null) {
              final confirmed = await _awaitConfirmation(proposal);
              if (confirmed == null) {
                functionResponses.add(
                  FunctionResponse(call.name, {
                    'result': 'cancelled',
                    'message':
                        'The user declined to create this calendar event.',
                  }),
                );
                continue;
              }
              final gatePlan = List<AgentStep>.from(state.currentPlan);
              gatePlan.add(AgentStep('Creating calendar event...'));
              state = state.copyWith(currentPlan: gatePlan);

              final gateResult = await ref
                  .read(agentServiceProvider)
                  .dispatchFunctionCall(
                    FunctionCall(call.name, confirmed.toCalendarParams()),
                  );

              final gateUpdated = List<AgentStep>.from(state.currentPlan);
              gateUpdated.last.isCompleted = true;
              gateUpdated.last.result = gateResult['result']?.toString() ??
                  gateResult['error']?.toString();
              state = state.copyWith(currentPlan: gateUpdated);

              functionResponses.add(FunctionResponse(call.name, gateResult));
              continue;
            }
            // Fall through to normal execution if proposal parsing failed
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
          if (e.toString().toLowerCase().contains('spike') ||
              e.toString().contains('503') ||
              e.toString().toLowerCase().contains('overloaded')) {
            setError(
              'The cloud model is currently experiencing high traffic spikes. Please try again later or switch to local inference.',
            );
          } else {
            setError(
              'An error occurred while calling tools. Please try again.',
            );
          }
          return;
        }
      }

      // Local-only path: Gemma returns plain text (no function calls), so the
      // extraction → confirm pipeline is the sole mechanism for tool actions.
      if (inferenceResponse.isLocal) {
        try {
          final proposal = await ActionExtractor.extract(
            userMessage: prompt,
            documentContext: documentContext,
            memoryContext: memoryContext,
          );
          if (proposal != null) {
            final confirmed = await _awaitConfirmation(proposal);
            if (confirmed != null) {
              await _executeProposalAndRecord(confirmed);
            }
          }
        } catch (e) {
          logger.w('Local action extraction failed', error: e);
        }
      }

      final finalResponseText = responseText?.trim();
      if (finalResponseText != null && finalResponseText.isNotEmpty) {
        await _addAssistantMessage(finalResponseText);
        final settings = await ref.read(settingsProvider.future);
        if (settings.isTtsEnabled) {
          VoiceService.instance.speak(finalResponseText);
        }
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
      return 'I have scanned a document. Raw OCR text:\n\n$extractedText\n\nPlease do the following based on the document content:\n1. If it looks like a **receipt or invoice**: extract the total amount, vendor name, date, and category (food/transport/shopping/etc) and call log_expense to record it.\n2. If it looks like a **general document, note, or article**: create a clean, well-structured summary that captures the key information, then call create_document to save that summary (NOT the raw text) to the knowledge base with an appropriate title and folder.\n3. Tell me what you found and what you did.';
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
