import 'package:mobile_assistant/core/agent/agent_tool.dart';
import 'package:mobile_assistant/core/db/app_database.dart';
import 'package:mobile_assistant/core/services/embedding_service.dart';
import 'package:mobile_assistant/core/services/crypto_service.dart';
import 'dart:convert';

class MemoryTool implements AgentTool {
  @override
  String get name => 'memory_tool';

  @override
  String get description => 'Store and retrieve semantic memories about the user using embeddings.';

  @override
  Future<String> execute(String action, Map<String, dynamic> parameters) async {
    final db = await AppDatabase.instance.database;

    switch (action) {
      case 'remember_fact':
        final fact = parameters['fact']?.toString() ?? '';
        final importance = parameters['importance'] is num ? (parameters['importance'] as num).toDouble() : 0.5;
        final isSensitive = parameters['is_sensitive'] == true;
        
        final embedding = await EmbeddingService.getEmbedding(fact);
        final embeddingStr = jsonEncode(embedding);

        String textToSave = fact;
        if (isSensitive) {
          textToSave = await CryptoService.encrypt(fact);
        }

        await db.insert('memories', {
          'fact': textToSave,
          'importance': importance,
          'createdAt': DateTime.now().toIso8601String(),
          'embedding': embeddingStr,
        });
        return "Saved memory: '\' with importance \.";

      case 'forget_fact':
        final id = parameters['id'];
        if (id == null) return "Missing 'id' for forget_fact.";
        final count = await db.delete('memories', where: 'id = ?', whereArgs: [id]);
        return count > 0 ? "Deleted memory \." : "Memory \ not found.";

      case 'search_memory':
        final query = parameters['query']?.toString();
        if (query == null || query.isEmpty) return "No query provided.";
        return await searchMemories(query);

      default:
        return "Unknown action: \ in MemoryTool";
    }
  }

  Future<String> searchMemories(String query) async {
    final db = await AppDatabase.instance.database;
    final queryEmbedding = await EmbeddingService.getEmbedding(query);
    
    final results = await db.query('memories');
    List<Map<String, dynamic>> scoredMemories = [];
    
    for (var row in results) {
      if (row['embedding'] != null) {
        final List<dynamic> embDynamic = jsonDecode(row['embedding'].toString());
        final emb = embDynamic.map((e) => (e as num).toDouble()).toList();
        final score = EmbeddingService.cosineSimilarity(queryEmbedding, emb);
        
        String decryptedFact = row['fact'].toString();
        if (decryptedFact.contains(':')) {
           decryptedFact = await CryptoService.decrypt(decryptedFact);
        }

        scoredMemories.add({
          'id': row['id'],
          'fact': decryptedFact,
          'score': score,
          'createdAt': row['createdAt'],
        });
      }
    }
    
    scoredMemories.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));
    final topMemories = scoredMemories.take(5).where((m) => (m['score'] as double) > 0.6).toList();
    
    if (topMemories.isEmpty) return "No relevant memories found.";
    
    return topMemories.map((m) => "[Id: ${m['id']}, Score: ${m['score']}] ${m['fact']}").join("\n");
  }
}
