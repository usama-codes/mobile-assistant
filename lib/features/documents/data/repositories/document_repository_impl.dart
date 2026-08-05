import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:mobile_assistant/core/db/database.dart';
import 'package:mobile_assistant/core/services/vault_service.dart';
import 'package:mobile_assistant/features/documents/domain/models/document_item.dart';
import 'package:mobile_assistant/features/documents/domain/repositories/document_repository.dart';

class DocumentRepositoryImpl implements DocumentRepository {
  DocumentRepositoryImpl(this._db);
  final AppDatabase _db;

  @override
  Future<List<DocumentItem>> getAllDocuments() async {
    final results =
        await (_db.select(_db.documents)..orderBy([
              (t) => drift.OrderingTerm(
                expression: t.createdAt,
                mode: drift.OrderingMode.desc,
              ),
            ]))
            .get();

    return results.map((row) {
      var tags = <String>[];
      if (row.tags != null && row.tags!.isNotEmpty) {
        try {
          tags = List<String>.from(jsonDecode(row.tags!) as Iterable);
        } catch (e) {
          tags = [row.tags!];
        }
      }
      return DocumentItem(
        id: row.id,
        title: row.title ?? 'Untitled',
        folder: row.folder ?? 'Uncategorized',
        tags: tags,
        originalSource: row.originalSource ?? '',
        documentType: row.documentType ?? 'text',
        filePath: row.filePath ?? '',
        createdAt: DateTime.parse(
          row.createdAt ?? DateTime.now().toIso8601String(),
        ),
      );
    }).toList();
  }

  @override
  Future<void> deleteDocument(int id) async {
    // We should also delete the file on disk if it exists, but matching original behavior for now.
    await (_db.delete(_db.documents)..where((t) => t.id.equals(id))).go();
  }

  @override
  Future<String> readDocumentContent(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      return 'Document file missing on disk.';
    }
    try {
      var content = await file.readAsString();
      if (VaultService.instance.isEncrypted(content)) {
        try {
          content = await VaultService.instance.decrypt(content);
        } catch (e) {
          // ignore
        }
      }
      return content;
    } catch (e) {
      return 'Error reading document: $e';
    }
  }
}
