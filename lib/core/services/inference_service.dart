import 'dart:async';
import 'dart:io';

import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart' hide Tool;
import 'package:flutter_gemma_mediapipe/flutter_gemma_mediapipe.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:mobile_assistant/core/services/analytics_service.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum InferenceStrategy { cloudOnly, localOnly, hybrid }

class InferenceResponse {
  InferenceResponse({
    this.text,
    this.functionCalls = const [],
    this.isLocal = false,
    this.cloudSession,
  });
  final String? text;
  final List<FunctionCall> functionCalls;
  final bool isLocal;

  /// Used to continue function-call loops (cloud only).
  final ChatSession? cloudSession;
}

/// Owns the on-device Gemma model (download, install, load, delete, generate)
/// and the cloud Gemini calls.
class InferenceService {
  InferenceService._internal();
  static final InferenceService instance = InferenceService._internal();

  static const modelFileName = 'gemma-2b-it-cpu-int4.bin';
  static const modelUrl =
      'https://github.com/usama-codes/gemma-model-hosting/releases/download/v1.0.0/$modelFileName';

  /// Context window the local model is created with. Gemma 2B handles this
  /// comfortably on mid-range phones; prompts are trimmed to fit it.
  static const _localMaxTokens = 2048;

  /// Rough budget for the prompt we send to the local model, in characters
  /// (~4 chars per token), leaving room for the reply.
  static const _localPromptCharBudget = (_localMaxTokens - 512) * 4;

  InferenceStrategy strategy = InferenceStrategy.hybrid;

  /// Whether a usable local model is installed. Widgets can listen to this to
  /// rebuild when the model is installed or deleted.
  final ValueNotifier<bool> localModelReady = ValueNotifier(false);
  bool get isLocalModelLoaded => localModelReady.value;

  InferenceModel? _model;
  Future<void> _localQueue = Future.value();

  Future<void> initialize() async {
    try {
      await _clearIncompatibleGemmaPrefs();
      await FlutterGemma.initialize(
        inferenceEngines: [const MediaPipeEngine()],
      );
      final path = await _installedModelPath();
      if (path != null && !FlutterGemma.hasActiveModel()) {
        // The file is on disk but flutter_gemma lost track of it (e.g. its
        // prefs were cleared). Re-register instead of downloading again.
        await _registerModel(path);
      }
      localModelReady.value = path != null && FlutterGemma.hasActiveModel();
      logger.i('Gemma model available: $isLocalModelLoaded');
    } catch (e, st) {
      logger.e('Failed to initialize local Gemma', error: e, stackTrace: st);
      localModelReady.value = false;
    }
  }

  /// Older builds stored a `.task` model under these keys. Restoring that
  /// spec makes flutter_gemma pick an engine that can't load our `.bin` file.
  Future<void> _clearIncompatibleGemmaPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final fileType =
        prefs.getString('flutter.active_inference_file_type') ??
        prefs.getString('active_inference_file_type');
    if (fileType == null || fileType == 'binary') return;

    logger.w('Clearing incompatible active_inference_file_type=$fileType');
    for (final key in const [
      'active_inference_file_type',
      'active_inference_model_type',
      'active_inference_filename',
      'active_inference_source',
    ]) {
      await prefs.remove(key);
      await prefs.remove('flutter.$key');
    }
  }

  Future<String> _downloadTargetPath() => _downloadTask().filePath();

  DownloadTask _downloadTask() => DownloadTask(
    url: modelUrl,
    filename: modelFileName,
    directory: 'models',
    baseDirectory: BaseDirectory.applicationSupport,
    updates: Updates.statusAndProgress,
    retries: 5,
    allowPause: true,
  );

  Future<String> _legacyPath() async =>
      p.join((await getApplicationDocumentsDirectory()).path, modelFileName);

  /// Path of a fully downloaded model file, or null if there is none.
  Future<String?> _installedModelPath() async {
    for (final path in [await _legacyPath(), await _downloadTargetPath()]) {
      if (File(path).existsSync()) return path;
    }
    return null;
  }

  /// Downloads (if needed) and installs the local model, making it active.
  /// [onProgress] receives 0-100. Throws on failure.
  Future<void> downloadAndInstallLocalModel({
    void Function(int percent)? onProgress,
  }) async {
    var path = await _installedModelPath();

    if (path == null) {
      try {
        await FileDownloader().cancelAll();
      } catch (_) {}
      // Needed for the Android 13+ foreground-service notification.
      await Permission.notification.request();

      FileDownloader().configureNotification(
        running: const TaskNotification(
          'Downloading AI Model',
          // {progress} already includes the % sign.
          'Progress: {progress}',
        ),
        complete: const TaskNotification(
          'Model Downloaded',
          'The AI model is ready.',
        ),
        error: const TaskNotification('Download Failed', 'Please try again.'),
        paused: const TaskNotification(
          'Download Paused',
          'Waiting for connection...',
        ),
        progressBar: true,
      );

      final task = _downloadTask();
      final result = await FileDownloader().download(
        task,
        onProgress: (progress) {
          if (progress >= 0) onProgress?.call((progress * 100).toInt());
        },
      );
      if (result.status != TaskStatus.complete) {
        final reason = result.exception?.description;
        throw Exception(
          'Download ${result.status.name}${reason != null ? ': $reason' : ''}',
        );
      }
      path = await task.filePath();
    }

    await _registerModel(path);

    // Load it once now so a broken file shows up here and not on the first
    // chat message. Delete it so the next attempt downloads a fresh copy.
    await _closeModel();
    try {
      await _getModel();
    } catch (_) {
      await deleteLocalModel();
      rethrow;
    }
    localModelReady.value = true;
  }

  Future<void> _registerModel(String path) async {
    await FlutterGemma.installModel(
      modelType: ModelType.gemmaIt,
      fileType: ModelFileType.binary,
    ).fromFile(path).install();
  }

  Future<void> deleteLocalModel() async {
    await _closeModel();
    try {
      await FlutterGemma.uninstallModel(modelFileName);
    } catch (e) {
      logger.w('uninstallModel failed (already removed?)', error: e);
    }
    await FlutterGemmaPlugin.instance.modelManager.clearModelCache();

    // Models installed with fromFile() are not deleted by flutter_gemma.
    for (final path in [await _legacyPath(), await _downloadTargetPath()]) {
      final file = File(path);
      if (file.existsSync()) await file.delete();
    }
    localModelReady.value = false;
  }

  Future<InferenceModel> _getModel() async {
    return _model ??= await FlutterGemma.getActiveModel(
      maxTokens: _localMaxTokens,
      preferredBackend: PreferredBackend.cpu,
    );
  }

  Future<void> _closeModel() async {
    final model = _model;
    _model = null;
    if (model != null) {
      try {
        await model.close();
      } catch (_) {}
    }
  }

  /// Picks local or cloud per [strategy]:
  /// - cloudOnly: cloud.
  /// - localOnly: on-device model.
  /// - hybrid: cloud first (it supports tools), on-device if cloud fails or
  ///   no API key is set.
  Future<InferenceResponse> generateChatResponse({
    required List<Content> chatHistory,
    required Content prompt,
    required String systemInstruction,
    required List<String> cloudModelNames,
    required String? cloudApiKey,
    List<Tool>? tools,

    /// Shorter instruction for the on-device model, which has a small
    /// context and no tool support. Defaults to [systemInstruction].
    String? localSystemInstruction,
  }) async {
    final localInstruction = localSystemInstruction ?? systemInstruction;
    if (strategy == InferenceStrategy.localOnly) {
      return generateLocalResponse(
        chatHistory: chatHistory,
        prompt: prompt,
        systemInstruction: localInstruction,
      );
    }

    final hasKey = cloudApiKey != null && cloudApiKey.isNotEmpty;
    final canFallBack =
        strategy == InferenceStrategy.hybrid && isLocalModelLoaded;

    if (!hasKey) {
      if (canFallBack) {
        return generateLocalResponse(
          chatHistory: chatHistory,
          prompt: prompt,
          systemInstruction: localInstruction,
        );
      }
      throw const InferenceException(
        'API Key not found. Add your GEMINI_API_KEY to the .env file, '
        'or download the on-device model in Settings.',
      );
    }

    Object? lastError;
    for (final modelName in cloudModelNames) {
      try {
        return await _generateCloudResponse(
          chatHistory,
          prompt,
          systemInstruction,
          modelName,
          cloudApiKey,
          tools,
        );
      } catch (e) {
        lastError = e;
        logger.w('Cloud inference failed for $modelName', error: e);
      }
    }

    if (canFallBack) {
      logger.i('All cloud models failed, using on-device model.');
      return generateLocalResponse(
        chatHistory: chatHistory,
        prompt: prompt,
        systemInstruction: localInstruction,
      );
    }

    throw InferenceException(_describeCloudError(lastError), cause: lastError);
  }

  String _describeCloudError(Object? e) {
    final msg = e.toString().toLowerCase();
    if (e is SocketException ||
        msg.contains('socket') ||
        msg.contains('failed host lookup')) {
      return 'No internet connection. Download the on-device model in '
          'Settings to keep chatting offline.';
    }
    if (msg.contains('spike') ||
        msg.contains('503') ||
        msg.contains('overloaded')) {
      return 'All cloud models are currently overloaded. Please try again '
          'later or switch to local inference.';
    }
    if (msg.contains('quota') || msg.contains('429')) {
      return 'Cloud quota exceeded. Download the on-device model in Settings '
          'to keep chatting.';
    }
    return 'Failed to generate response. Please try again.';
  }

  /// Runs the on-device model. Calls are queued, since the native session
  /// can only process one request at a time.
  Future<InferenceResponse> generateLocalResponse({
    required List<Content> chatHistory,
    required Content prompt,
    required String systemInstruction,
  }) {
    if (!isLocalModelLoaded) {
      return Future.error(
        const InferenceException(
          'The on-device model is not installed. Download it in Settings or '
          'switch to Hybrid/Cloud mode.',
        ),
      );
    }

    final completer = Completer<InferenceResponse>();
    _localQueue = _localQueue.then((_) async {
      try {
        final text = await _runLocal(chatHistory, prompt, systemInstruction);
        completer.complete(InferenceResponse(text: text, isLocal: true));
      } catch (e, st) {
        completer.completeError(e, st);
      }
    });
    return completer.future;
  }

  Future<String> _runLocal(
    List<Content> chatHistory,
    Content prompt,
    String systemInstruction,
  ) async {
    final messages = buildLocalMessages(
      chatHistory: chatHistory,
      prompt: prompt,
      systemInstruction: systemInstruction,
      charBudget: _localPromptCharBudget,
    );

    InferenceChat? chat;
    try {
      final model = await _getModel();
      // A fresh chat per request: history is rebuilt from the app's own
      // message list, so nothing leaks between sessions.
      chat = await model.createChat(temperature: 0.7, topK: 40);
      for (final msg in messages) {
        await chat.addQueryChunk(msg);
      }
      final response = await chat.generateChatResponse();
      final text = response is TextResponse ? response.token.trim() : '';
      if (text.isEmpty) {
        throw const InferenceException(
          'The on-device model returned an empty reply. Try rephrasing.',
        );
      }
      return text;
    } on InferenceException {
      rethrow;
    } catch (e, st) {
      logger.e('Local inference failed', error: e, stackTrace: st);
      // The native model can be left in a bad state; reload it next time.
      await _closeModel();
      throw InferenceException('On-device model failed: $e', cause: e);
    } finally {
      try {
        await chat?.close();
      } catch (_) {}
    }
  }

  /// Turns the chat into a Gemma conversation that fits [charBudget].
  /// The system instruction is merged into the first user turn (Gemma has no
  /// system role), and the oldest turns are dropped first.
  @visibleForTesting
  static List<Message> buildLocalMessages({
    required List<Content> chatHistory,
    required Content prompt,
    required String systemInstruction,
    required int charBudget,
  }) {
    String textOf(Content c) =>
        c.parts.whereType<TextPart>().map((e) => e.text).join(' ').trim();

    String clip(String text, int max) =>
        text.length > max ? text.substring(0, max) : text;

    final system = clip(systemInstruction.trim(), charBudget ~/ 2);
    final promptText = clip(textOf(prompt), charBudget - system.length);

    var remaining = charBudget - system.length - promptText.length;
    final history = <Message>[];
    for (final content in chatHistory.reversed) {
      final text = textOf(content);
      if (text.isEmpty) continue;
      if (text.length > remaining) break;
      remaining -= text.length;
      history.insert(0, Message(text: text, isUser: content.role == 'user'));
    }
    // Gemma expects the conversation to start with a user turn.
    while (history.isNotEmpty && !history.first.isUser) {
      history.removeAt(0);
    }

    final turns = [...history, Message(text: promptText, isUser: true)];
    final first = turns.first;
    turns[0] = Message(
      text: 'System instruction: $system\n\n${first.text}',
      isUser: true,
    );
    return turns;
  }

  Future<InferenceResponse> _generateCloudResponse(
    List<Content> chatHistory,
    Content prompt,
    String systemInstruction,
    String modelName,
    String apiKey,
    List<Tool>? tools,
  ) async {
    final session = GenerativeModel(
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

class InferenceException implements Exception {
  const InferenceException(this.message, {this.cause});
  final String message;
  final Object? cause;

  @override
  String toString() => message;
}
