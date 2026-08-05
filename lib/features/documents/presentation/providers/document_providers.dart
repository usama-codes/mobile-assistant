import 'package:mobile_assistant/core/providers/database_provider.dart';
import 'package:mobile_assistant/features/documents/data/repositories/document_repository_impl.dart';
import 'package:mobile_assistant/features/documents/domain/models/document_item.dart';
import 'package:mobile_assistant/features/documents/domain/repositories/document_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'document_providers.g.dart';

@riverpod
DocumentRepository documentRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return DocumentRepositoryImpl(db);
}

// Backwards-compatible alias for older provider name
final DocumentNotifierProvider documentNotifierProvider = documentProvider;

@riverpod
class DocumentNotifier extends _$DocumentNotifier {
  @override
  FutureOr<List<DocumentItem>> build() async {
    final repo = ref.watch(documentRepositoryProvider);
    return repo.getAllDocuments();
  }

  Future<void> loadDocuments() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(documentRepositoryProvider).getAllDocuments(),
    );
  }

  Future<void> deleteDocument(int id) async {
    state = const AsyncValue.loading();
    await ref.read(documentRepositoryProvider).deleteDocument(id);
    await loadDocuments();
  }
}
