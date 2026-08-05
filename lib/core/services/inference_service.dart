import 'package:flutter_gemma/flutter_gemma.dart' hide Tool;
import 'package:flutter_gemma_mediapipe/flutter_gemma_mediapipe.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:mobile_assistant/core/services/analytics_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum InferenceStrategy { cloudOnly, localOnly, hybrid }

class InferenceResponse {
  // Used to continue function call loops

  InferenceResponse({
    this.text,
    this.functionCalls = const [],
    this.isLocal = false,
    this.cloudSession,
  });
  final String? text;
  final List<FunctionCall> functionCalls;
  final bool isLocal;
  final ChatSession? cloudSession;
}

class InferenceService {
  InferenceService._internal();
  static final InferenceService instance = InferenceService._internal();

  InferenceStrategy strategy = InferenceStrategy.hybrid;
  bool isLocalModelLoaded = false;

  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentFileType =
          prefs.getString('flutter.active_inference_file_type') ??
          prefs.getString('active_inference_file_type');
      if (currentFileType != 'binary') {
        logger.w(
          'Found incompatible active_inference_file_type=$currentFileType in SharedPreferences. Clearing before initialization.',
        );
        await prefs.remove('active_inference_file_type');
        await prefs.remove('flutter.active_inference_file_type');
        await prefs.remove('flutter.active_inference_model_type');
        await prefs.remove('active_inference_filename');
        await prefs.remove('flutter.active_inference_filename');
        await prefs.remove('active_inference_source');
        await prefs.remove('flutter.active_inference_source');
      }

      await FlutterGemma.initialize(
        inferenceEngines: [const MediaPipeEngine()],
      );

      isLocalModelLoaded = FlutterGemma.hasActiveModel();
      logger.i('Gemma model loaded: $isLocalModelLoaded');
    } catch (e, st) {
      logger.e(
        'Failed to initialize local Gemma model',
        error: e,
        stackTrace: st,
      );
      isLocalModelLoaded = false;
    }
  }

  Future<InferenceResponse> generateChatResponse({
    required List<Content> chatHistory,
    required Content prompt,
    required String systemInstruction,
    required String cloudModelName,
    required String cloudApiKey,
    List<Tool>? tools,
    ChatSession? existingCloudSession,
  }) async {
    final useLocal =
        strategy == InferenceStrategy.localOnly ||
        (strategy == InferenceStrategy.hybrid && isLocalModelLoaded);

    if (useLocal && isLocalModelLoaded) {
      try {
        final localText = await _generateLocalResponse(
          chatHistory,
          prompt,
          systemInstruction,
        );
        return InferenceResponse(text: localText, isLocal: true);
      } catch (e) {
        if (strategy == InferenceStrategy.localOnly) rethrow;
        logger.w('Local inference failed, falling back to cloud.', error: e);
      }
    } else if (strategy == InferenceStrategy.localOnly) {
      throw Exception(
        'Local Gemma model is not loaded. Download it in settings or switch to Hybrid/Cloud mode.',
      );
    }

    return _generateCloudResponse(
      chatHistory,
      prompt,
      systemInstruction,
      cloudModelName,
      cloudApiKey,
      tools,
      existingCloudSession,
    );
  }

  Future<String> _generateLocalResponse(
    List<Content> chatHistory,
    Content prompt,
    String systemInstruction,
  ) async {
    if (!FlutterGemma.hasActiveModel()) return '';

    final model = await FlutterGemma.getActiveModel();
    final chat = await model.createChat();

    final messages = <Message>[];
    bool firstUser = true;
    for (final content in chatHistory) {
      final text = content.parts
          .whereType<TextPart>()
          .map((e) => e.text)
          .join(' ')
          .trim();
      if (text.isNotEmpty) {
        final isUser = content.role == 'user';
        if (isUser && firstUser) {
          messages.add(
            Message(
              text: 'System instruction: $systemInstruction\n\n$text',
              isUser: true,
            ),
          );
          firstUser = false;
        } else {
          messages.add(Message(text: text, isUser: isUser));
        }
      }
    }

    final promptText = prompt.parts
        .whereType<TextPart>()
        .map((e) => e.text)
        .join(' ')
        .trim();
    if (firstUser) {
      messages.add(
        Message(
          text: 'System instruction: $systemInstruction\n\n$promptText',
          isUser: true,
        ),
      );
    } else {
      messages.add(Message(text: promptText, isUser: true));
    }

    logger.i(
      'Running local inference with Gemma (prompt length: ${promptText.length})',
    );

    try {
      for (final msg in messages) {
        await chat.addQueryChunk(msg);
      }
      final response = await chat.generateChatResponse();
      if (response is TextResponse) {
        return response.token;
      }
      return '';
    } finally {
      await chat.close();
    }
  }

  Future<InferenceResponse> _generateCloudResponse(
    List<Content> chatHistory,
    Content prompt,
    String systemInstruction,
    String modelName,
    String apiKey,
    List<Tool>? tools,
    ChatSession? existingSession,
  ) async {
    final session =
        existingSession ??
        GenerativeModel(
          model: modelName,
          apiKey: apiKey,
          systemInstruction: Content.system(systemInstruction),
          tools: tools,
        ).startChat(history: chatHistory);

    logger.i('Running cloud inference with $modelName');
    final response = await session.sendMessage(prompt);

    return InferenceResponse(
      text: response.text,
      functionCalls: response.functionCalls.toList(),
      cloudSession: session,
    );
  }
}
