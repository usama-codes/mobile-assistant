import 'package:mobile_assistant/core/db/objectbox.dart';
import 'package:mobile_assistant/core/providers/database_provider.dart';
import 'package:mobile_assistant/features/memory/data/repositories/memory_repository_impl.dart';
import 'package:mobile_assistant/features/memory/domain/models/memory_fact.dart'
    as dom;
import 'package:mobile_assistant/features/memory/domain/repositories/memory_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'memory_providers.g.dart';

@riverpod
MemoryRepository memoryRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  final obx = ref.watch(objectBoxProvider);
  return MemoryRepositoryImpl(obx, db);
}

// Backwards-compatible alias for older provider name
final MemoryNotifierProvider memoryNotifierProvider = memoryProvider;

@riverpod
class MemoryNotifier extends _$MemoryNotifier {
  @override
  FutureOr<List<dom.MemoryFact>> build() async {
    final repo = ref.watch(memoryRepositoryProvider);
    return repo.getAllMemories();
  }

  Future<void> loadMemories() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(memoryRepositoryProvider).getAllMemories(),
    );
  }

  Future<void> addMemory(
    String fact, {
    double importance = 0.5,
    bool isSensitive = false,
  }) async {
    state = const AsyncValue.loading();
    await ref
        .read(memoryRepositoryProvider)
        .addMemory(fact, importance: importance, isSensitive: isSensitive);
    await loadMemories();
  }

  Future<void> deleteMemory(int id) async {
    state = const AsyncValue.loading();
    await ref.read(memoryRepositoryProvider).deleteMemory(id);
    await loadMemories();
  }
}
