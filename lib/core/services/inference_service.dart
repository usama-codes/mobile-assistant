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
  bool _warmedUp = false;

  /// Lightweight check — does NOT load Gemma. Used at startup to see if the
  /// model happens to be cached from a prior session.
  Future<void> initialize() async {
    isLocalModelLoaded = FlutterGemma.hasActiveModel();
    logger.i('Gemma model cached: $isLocalModelLoaded');
  }

  /// Load Gemma on first chat use. Called lazily so the app starts fast.
  /// Subsequent calls are no-ops once the model is loaded.
  Future<void> warmUp() async {
    if (_warmedUp) return;
    _warmedUp = true;

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

      logger.i('Loading Gemma model (first use)...');
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

  /// Run a single local generation with a system instruction and prompt,
  /// returning the raw text. Used by structured extraction (ActionExtractor).
  ///
  /// Always local — never touches cloud APIs. Returns null when the model
  /// is not loaded or generation fails.
  Future<String?> generateLocalOnly({
    required String systemInstruction,
    required String prompt,
  }) async {
    if (!isLocalModelLoaded || !FlutterGemma.hasActiveModel()) {
      logger.w('generateLocalOnly: no active local model');
      return null;
    }

    try {
      final model = await FlutterGemma.getActiveModel();
      final chat = await model.createChat();
      try {
        await chat.addQueryChunk(
          Message(text: 'System instruction: $systemInstruction\n\n$prompt', isUser: true),
        );
        final response = await chat.generateChatResponse();
        if (response is TextResponse) {
          return response.token;
        }
        return null;
      } finally {
        await chat.close();
      }
    } catch (e, st) {
      logger.e('generateLocalOnly failed', error: e, stackTrace: st);
      return null;
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
