import 'dart:math';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class EmbeddingService {
  static Future<List<double>> getEmbedding(String text) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null) throw Exception('API Key not found.');

    final model = GenerativeModel(model: 'gemini-embedding-2', apiKey: apiKey);

    final content = Content.text(text);
    final result = await model.embedContent(content);
    return result.embedding.values;
  }

  static double cosineSimilarity(List<double> a, List<double> b) {
    if (a.length != b.length) return 0;
    var dotProduct = 0;
    var normA = 0;
    var normB = 0;
    for (var i = 0; i < a.length; i++) {
      dotProduct += (a[i] * b[i]) as int;
      normA += (a[i] * a[i]) as int;
      normB += (b[i] * b[i]) as int;
    }
    if (normA == 0 || normB == 0) return 0;
    return dotProduct / (sqrt(normA) * sqrt(normB));
  }
}
