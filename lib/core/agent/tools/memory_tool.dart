import 'package:mobile_assistant/core/agent/agent_tool.dart';
import 'package:mobile_assistant/core/db/app_database.dart';
import 'package:google_generative_ai/google_generative_ai.dart' hide ChatSession;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'dart:math';

class MemoryTool implements AgentTool {
  @override
  String get name => 'memory_tool';

  @override
  String get description => 'Store and retrieve semantic memories about the user using embeddings.';

  Future<List<double>> _getEmbedding(String text) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null) throw Exception("API Key not found.");
    
    final model = GenerativeModel(
      model: 'gemini-embedding-2',
      apiKey: apiKey,
    );
    
    final content = Content.text(text);
    final result = await model.embedContent(content);
    return result.embedding.values;
  }

  double _cosineSimilarity(List<double> a, List<double> b) {
    if (a.length != b.length) return 0.0;
    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;
    for (int i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }
    if (normA == 0 || normB == 0) return 0.0;
    return dotProduct / (sqrt(normA) * sqrt(normB));
  }

  @override
  Future<String> execute(String action, Map<String, dynamic> parameters) async {
    final db = await AppDatabase.instance.database;

    switch (action) {
      case 'remember_fact':
        final fact = parameters['fact'];
        if (fact == null || fact.toString().trim().isEmpty) {
          throw Exception("Fact is required.");
        }
        
        final embedding = await _getEmbedding(fact);
        
        await db.insert('memories', {
          'fact': fact,
          'importance': parameters['importance'] ?? 1.0,
          'createdAt': DateTime.now().toIso8601String(),
          'embedding': jsonEncode(embedding),
        });
        
        return "I will remember that.";

      case 'forget_fact':
        final id = parameters['id'];
        if (id == null) {
          throw Exception("Memory ID is required to forget.");
        }
        await db.delete('memories', where: 'id = ?', whereArgs: [id]);
        return "Memory forgotten.";

      case 'search_memory':
        final query = parameters['query'];
        if (query == null || query.toString().trim().isEmpty) {
          return "No search query provided.";
        }
        
        final queryEmbedding = await _getEmbedding(query);
        final results = await db.query('memories');
        
        List<Map<String, dynamic>> scoredMemories = [];
        for (var row in results) {
          final embStr = row['embedding'] as String?;
          if (embStr != null) {
            final List<dynamic> embList = jsonDecode(embStr);
            final List<double> emb = embList.map((e) => (e as num).toDouble()).toList();
            final score = _cosineSimilarity(queryEmbedding, emb);
            scoredMemories.add({
              'id': row['id'],
              'fact': row['fact'],
              'score': score,
            });
          }
        }
        
        scoredMemories.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));
        
        final topK = scoredMemories.take(5).where((m) => (m['score'] as double) > 0.5).toList();
        if (topK.isEmpty) return "No relevant memories found.";
        
        return "Found memories: ${topK.map((m) => m['fact']).join(' | ')}";

      default:
        throw Exception("Unknown action '$action' for MemoryTool.");
    }
  }
}
