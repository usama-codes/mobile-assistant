import 'package:mobile_assistant/features/memory/domain/models/memory_fact.dart';

abstract class MemoryRepository {
  Future<List<MemoryFact>> getAllMemories();
  Future<void> addMemory(String fact, {double importance = 0.5, bool isSensitive = false});
  Future<void> deleteMemory(int id);
  Future<List<MemoryFact>> searchMemories(String query, {int limit = 5});
}
