import 'dart:io';

import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/services.dart';
import 'package:mobile_assistant/core/services/analytics_service.dart';
import 'package:onnxruntime/onnxruntime.dart';

/// Local embedding service using the all-MiniLM-L6-v2 ONNX model.
///
/// Runs entirely on-device — no content is sent to any cloud API.
/// Model (~23 MB quantised) is loaded from the app's documents directory.
/// The vocab.txt is bundled as a Flutter asset.
class LocalEmbeddingService {
  LocalEmbeddingService._();
  static final LocalEmbeddingService instance = LocalEmbeddingService._();

  /// Embedding dimension produced by all-MiniLM-L6-v2.
  static const int dimension = 384;

  /// Maximum sequence length for the tokenizer.
  static const int maxSequenceLength = 128;

  static const _modelName = 'model_quantized.onnx';
  static const _modelUrl =
      'https://huggingface.co/sentence-transformers/all-MiniLM-L6-v2'
      '/resolve/main/onnx/model_quantized.onnx';

  // ── State ──────────────────────────────────────────────────────────────
  Map<String, int>? _vocab;
  OrtSession? _session;
  bool _initialising = false;
  bool _ready = false;

  bool get isReady => _ready;

  // ── Public API ─────────────────────────────────────────────────────────

  /// Ensure the ONNX session is loaded.  Downloads the model on first use.
  /// The vocab is expected to be in `assets/minilm_vocab.txt`.
  Future<void> ensureReady({void Function(int percent)? onProgress}) async {
    if (_ready || _initialising) return;
    _initialising = true;

    try {
      // Use background_downloader's canonical path resolution (matches
      // the Gemma download pattern in onboarding_provider.dart).
      final task = DownloadTask(
        url: _modelUrl,
        filename: _modelName,
        directory: 'embeddings',
        baseDirectory: BaseDirectory.applicationDocuments,
        updates: Updates.statusAndProgress,
        retries: 3,
      );
      final modelFilePath = await task.filePath();
      final modelFile = File(modelFilePath);
      _modelPath = modelFilePath;

      // Download model if missing.
      if (!await modelFile.exists()) {
        logger.i('Downloading ONNX embedding model...');
        await FileDownloader().download(
          task,
          onProgress: (p) {
            if (onProgress != null && p > 0) onProgress((p * 100).toInt());
          },
        );
        logger.i('Embedding model downloaded to $modelFilePath');
      }

      // Load vocab from asset.
      _vocab = await _loadVocabAsset();

      // Create ONNX session.
      final options = OrtSessionOptions();
      options.setIntraOpNumThreads(2);
      options.setSessionGraphOptimizationLevel(
        GraphOptimizationLevel.ortEnableAll,
      );
      options.appendCPUProvider(CPUFlags.useArena);

      _session = OrtSession.fromFile(modelFile, options);
      _ready = true;
      logger.i(
        'Local embedding service ready '
        '(vocab=${_vocab?.length}, outputs=${_session?.outputNames})',
      );
    } catch (e, st) {
      logger.e('LocalEmbeddingService init failed', error: e, stackTrace: st);
    } finally {
      _initialising = false;
    }
  }

  /// Embed [text] into a 384-dimensional vector.
  ///
  /// Lazily initialises the model on first call (downloads it if missing).
  /// Returns `null` when the model is not available or inference fails.
  Future<List<double>?> embed(String text) async {
    if (!_ready && !_initialising) {
      await ensureReady();
    }
    if (!_ready || _session == null || _vocab == null) return null;

    try {
      final inputs = _tokenize(text);
      final runOptions = OrtRunOptions();

      final inputIdsTensor = OrtValueTensor.createTensorWithDataList(
        inputs.inputIds,
        [1, maxSequenceLength],
      );
      final attentionMaskTensor = OrtValueTensor.createTensorWithDataList(
        inputs.attentionMask,
        [1, maxSequenceLength],
      );
      final tokenTypeIdsTensor = OrtValueTensor.createTensorWithDataList(
        inputs.tokenTypeIds,
        [1, maxSequenceLength],
      );

      // runAsync runs in a background isolate — no main-thread jank.
      final outputs = await _session!.runAsync(runOptions, {
        'input_ids': inputIdsTensor,
        'attention_mask': attentionMaskTensor,
        'token_type_ids': tokenTypeIdsTensor,
      });

      inputIdsTensor.release();
      attentionMaskTensor.release();
      tokenTypeIdsTensor.release();
      runOptions.release();

      if (outputs == null || outputs.isEmpty) return null;
      final tensor = outputs.first;
      if (tensor == null) return null;

      final raw = tensor.value;
      final vector = _flattenToDouble(raw);
      if (vector.length != dimension) {
        logger.w('Embedding dim mismatch: ${vector.length} vs $dimension');
        return null;
      }
      return vector;
    } catch (e, st) {
      logger.e('Embedding inference failed', error: e, stackTrace: st);
      return null;
    }
  }

  void dispose() {
    _session?.release();
    _session = null;
    _ready = false;
    _vocab = null;
  }

  // ── Private: vocab loading ─────────────────────────────────────────────

  static String? _modelPath;

  /// Resolved path of the ONNX model on disk.
  static Future<String> get modelPath async {
    if (_modelPath != null) return _modelPath!;
    final task = DownloadTask(
      url: _modelUrl,
      filename: _modelName,
      directory: 'embeddings',
      baseDirectory: BaseDirectory.applicationDocuments,
    );
    _modelPath = await task.filePath();
    return _modelPath!;
  }

  static Future<Map<String, int>> _loadVocabAsset() async {
    const assetPath = 'assets/minilm_vocab.txt';
    final raw = await rootBundle.loadString(assetPath);
    final lines = raw.split('\n');
    final vocab = <String, int>{};
    for (var i = 0; i < lines.length; i++) {
      final token = lines[i].trim();
      if (token.isNotEmpty) vocab[token] = i;
    }
    return vocab;
  }

  // ── Private: tokenizer ─────────────────────────────────────────────────

  _TokenizedInput _tokenize(String text) {
    final tokens = _basicTokenize(text);
    final wpTokens = <String>[];
    for (final t in tokens) {
      wpTokens.addAll(_wordpiece(t));
    }

    final ids = List.filled(maxSequenceLength, 0);
    final mask = List.filled(maxSequenceLength, 0);
    final types = List.filled(maxSequenceLength, 0);

    ids[0] = _vocab!['[CLS]'] ?? 101;
    mask[0] = 1;

    var idx = 1;
    for (final wp in wpTokens) {
      if (idx >= maxSequenceLength - 1) break;
      ids[idx] = _vocab![wp] ?? _vocab!['[UNK]'] ?? 100;
      mask[idx] = 1;
      idx++;
    }

    ids[idx] = _vocab!['[SEP]'] ?? 102;
    mask[idx] = 1;

    return _TokenizedInput(inputIds: ids, attentionMask: mask, tokenTypeIds: types);
  }

  List<String> _basicTokenize(String text) {
    final cleaned = text
        .replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), ' ')
        .replaceAll('\n', ' ')
        .replaceAll('\t', ' ')
        .toLowerCase()
        .trim();
    if (cleaned.isEmpty) return const [];

    final cjkReady = cleaned.replaceAllMapped(
      RegExp(r'([一-鿿㐀-䶿])'),
      (m) => ' ${m.group(1)} ',
    );

    final words =
        cjkReady.split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    final tokens = <String>[];
    for (final word in words) {
      tokens.addAll(_splitOnPunc(word));
    }
    return tokens;
  }

  static List<String> _splitOnPunc(String word) {
    final result = <String>[];
    final buf = <String>[];
    for (var i = 0; i < word.length; i++) {
      final ch = word[i];
      if (_isPunctuation(ch)) {
        if (buf.isNotEmpty) {
          result.add(buf.join());
          buf.clear();
        }
        result.add(ch);
      } else {
        final stripped = _stripAccent(ch);
        if (stripped.isNotEmpty) {
          buf.add(stripped);
        }
      }
    }
    if (buf.isNotEmpty) result.add(buf.join());
    return result;
  }

  static bool _isPunctuation(String ch) {
    final cp = ch.codeUnitAt(0);
    if (cp <= 0x2F) return true;
    if (cp >= 0x3A && cp <= 0x40) return true;
    if (cp >= 0x5B && cp <= 0x60) return true;
    if (cp >= 0x7B && cp <= 0x7E) return true;
    if (cp >= 0x3000 && cp <= 0x303F) return true;
    if (cp >= 0xFF01 && cp <= 0xFF0F) return true;
    if (cp >= 0xFF1A && cp <= 0xFF20) return true;
    if (cp >= 0xFF3B && cp <= 0xFF40) return true;
    if (cp >= 0xFF5B && cp <= 0xFF65) return true;
    return false;
  }

  static final _accentMap = <String, String>{
    'à': 'a', 'á': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', 'å': 'a',
    'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e',
    'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i',
    'ò': 'o', 'ó': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o',
    'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u',
    'ñ': 'n', 'ç': 'c', 'ÿ': 'y',
  };

  static String _stripAccent(String ch) {
    final cp = ch.codeUnitAt(0);
    if ((cp >= 0x0300 && cp <= 0x036F) || (cp >= 0x1AB0 && cp <= 0x1AFF)) {
      return '';
    }
    return _accentMap[ch] ?? ch;
  }

  List<String> _wordpiece(String token) {
    if (token.isEmpty) return const [];
    final chars = token.split('');
    if (chars.length > 200) return const ['[UNK]'];

    final subTokens = <String>[];
    var start = 0;
    while (start < chars.length) {
      var end = chars.length;
      String? found;
      while (start < end) {
        var substr = chars.sublist(start, end).join();
        if (start > 0) substr = '##$substr';
        if (_vocab!.containsKey(substr)) {
          found = substr;
          break;
        }
        end--;
      }
      if (found == null) return const ['[UNK]'];
      subTokens.add(found);
      start = end;
    }
    return subTokens;
  }

  // ── Helpers ────────────────────────────────────────────────────────────

  static List<double> _flattenToDouble(dynamic v) {
    final out = <double>[];
    _flatten(v, out);
    return out;
  }

  static void _flatten(dynamic v, List<double> out) {
    if (v is List) {
      for (final item in v) {
        _flatten(item, out);
      }
    } else if (v is num) {
      out.add(v.toDouble());
    }
  }
}

class _TokenizedInput {
  final List<int> inputIds;
  final List<int> attentionMask;
  final List<int> tokenTypeIds;
  const _TokenizedInput({
    required this.inputIds,
    required this.attentionMask,
    required this.tokenTypeIds,
  });
}
