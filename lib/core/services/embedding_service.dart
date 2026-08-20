import 'dart:math';

import 'package:mobile_assistant/core/services/local_embedding_service.dart';

/// Document embedding service.
///
/// All embeddings are computed **fully on-device** via the local ONNX
/// MiniLM model — document content never leaves the device. This is the
/// privacy boundary behind the app's "local RAG" selling point.
class EmbeddingService {
  /// Embed [text] into a 384-dimensional vector locally.
  ///
  /// Returns `null` when the local model is not available yet (first-use
  /// download pending, or inference failure). Callers must degrade
  /// gracefully (e.g. keyword fallback) instead of throwing — never fall
  /// back to a cloud embedder.
  static Future<List<double>?> getEmbedding(String text) async {
    return LocalEmbeddingService.instance.embed(text);
  }

  static double cosineSimilarity(List<double> a, List<double> b) {
    if (a.length != b.length) return 0;
    double dotProduct = 0;
    double normA = 0;
    double normB = 0;
    for (var i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }
    if (normA == 0 || normB == 0) return 0;
    return dotProduct / (sqrt(normA) * sqrt(normB));
  }
}
