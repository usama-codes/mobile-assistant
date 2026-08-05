import 'package:mobile_assistant/features/documents/domain/models/document_item.dart';

abstract class DocumentRepository {
  Future<List<DocumentItem>> getAllDocuments();
  Future<void> deleteDocument(int id);
  Future<String> readDocumentContent(String filePath);
  // Creating a document is done by the DocumentTool, so we may not need it here unless UI allows uploading.
}
