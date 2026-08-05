import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:mobile_assistant/core/agent/agent_tool.dart';
import 'package:mobile_assistant/features/memory/domain/repositories/memory_repository.dart';

class MemoryTool implements AgentTool {
  MemoryTool(this._repo);
  final MemoryRepository _repo;

  @override
  List<FunctionDeclaration> get declarations => [
    FunctionDeclaration(
      'remember_fact',
      'Save a fact or user preference to long-term memory',
      Schema(
        SchemaType.object,
        properties: {
          'fact': Schema(
            SchemaType.string,
            description: 'The fact to remember',
          ),
          'importance': Schema(
            SchemaType.number,
            description: '0.0 to 1.0, default 0.5',
          ),
          'is_sensitive': Schema(
            SchemaType.boolean,
            description: 'Encrypt if true',
          ),
        },
        requiredProperties: ['fact'],
      ),
    ),
    FunctionDeclaration(
      'forget_fact',
      'Delete a previously saved memory by its id',
      Schema(
        SchemaType.object,
        properties: {
          'id': Schema(SchemaType.integer, description: 'Memory id to delete'),
        },
        requiredProperties: ['id'],
      ),
    ),
    FunctionDeclaration(
      'search_memory',
      'Semantically search saved memories for a query',
      Schema(
        SchemaType.object,
        properties: {
          'query': Schema(
            SchemaType.string,
            description: 'Natural language query',
          ),
        },
        requiredProperties: ['query'],
      ),
    ),
  ];

  @override
  bool canHandle(String functionName) {
    const handled = {'remember_fact', 'forget_fact', 'search_memory'};
    return handled.contains(functionName);
  }

  @override
  String get name => 'memory_tool';

  @override
  String get description =>
      'Store and retrieve semantic memories about the user using embeddings.';

  @override
  Future<String> execute(String action, Map<String, dynamic> parameters) async {
    switch (action) {
      case 'remember_fact':
        final fact = parameters['fact']?.toString().trim() ?? '';
        if (fact.isEmpty) throw Exception('Fact cannot be empty.');
        final importance = parameters['importance'] is num
            ? (parameters['importance'] as num).toDouble()
            : 0.5;
        final isSensitive = parameters['is_sensitive'] == true;
        await _repo.addMemory(
          fact,
          importance: importance,
          isSensitive: isSensitive,
        );
        return "Saved memory: '$fact'";

      case 'forget_fact':
        final id = parameters['id'];
        if (id == null) throw Exception('Memory id is required.');
        await _repo.deleteMemory(id as int);
        return 'Deleted memory $id.';

      case 'search_memory':
        final query = parameters['query']?.toString().trim() ?? '';
        if (query.isEmpty) throw Exception('Search query cannot be empty.');
        final results = await _repo.searchMemories(query);
        if (results.isEmpty) return 'No relevant memories found.';
        return results
            .map(
              (m) =>
                  '[id:${m.id}, importance:${m.importance.toStringAsFixed(2)}] ${m.fact}',
            )
            .join('\n');

      default:
        throw Exception("Unknown action '$action' for MemoryTool.");
    }
  }

  Future<String> searchMemories(String query) async {
    final results = await _repo.searchMemories(query);
    if (results.isEmpty) return 'No relevant memories found.';
    return results
        .map(
          (m) =>
              '[id:${m.id}, importance:${m.importance.toStringAsFixed(2)}] ${m.fact}',
        )
        .join('\n');
  }
}
