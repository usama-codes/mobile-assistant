import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:mobile_assistant/core/agent/agent_tool.dart';
import 'package:mobile_assistant/core/db/app_database.dart';
import 'dart:convert';

class DocumentTool implements AgentTool {
  @override
  String get name => 'document_tool';

  @override
  String get description => 'Create, read, and search markdown documents in the knowledge base.';

  @override
  Future<String> execute(String action, Map<String, dynamic> parameters) async {
    final db = await AppDatabase.instance.database;

    switch (action) {
      case 'create_document':
        final title = parameters['title'];
        final content = parameters['content'];
        if (title == null || title.toString().trim().isEmpty) {
          throw Exception("Document title is required.");
        }
        if (content == null) {
          throw Exception("Document content is required.");
        }

        final folder = parameters['folder'] ?? 'general';
        final tags = parameters['tags'] ?? [];
        final tagsStr = jsonEncode(tags);
        final documentType = parameters['document_type'] ?? 'markdown';
        final originalSource = parameters['original_source'] ?? 'assistant';

        final appDir = await getApplicationDocumentsDirectory();
        final docDir = Directory('${appDir.path}/documents');
        if (!await docDir.exists()) {
          await docDir.create(recursive: true);
        }

        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${title.toString().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}.md';
        final file = File('${docDir.path}/$fileName');
        await file.writeAsString(content.toString());

        await db.insert('documents', {
          'title': title,
          'folder': folder,
          'tags': tagsStr,
          'original_source': originalSource,
          'document_type': documentType,
          'file_path': file.path,
          'createdAt': DateTime.now().toIso8601String(),
        });

        return "Created document '$title' successfully.";

      case 'search_documents':
        final keyword = parameters['keyword']?.toString().toLowerCase();
        if (keyword == null || keyword.isEmpty) {
          return "No keyword provided for search.";
        }

        final results = await db.query('documents');
        final matches = results.where((doc) {
          final t = doc['title'].toString().toLowerCase();
          final tags = doc['tags'].toString().toLowerCase();
          return t.contains(keyword) || tags.contains(keyword);
        }).toList();

        if (matches.isEmpty) return "No documents found matching '$keyword'.";
        
        final summary = matches.map((d) => "ID: ${d['id']} | Title: ${d['title']}").join("\n");
        return "Found ${matches.length} documents:\n$summary";

      case 'read_document':
        final id = parameters['id'];
        if (id == null) {
          throw Exception("Document ID is required.");
        }

        final results = await db.query('documents', where: 'id = ?', whereArgs: [id]);
        if (results.isEmpty) throw Exception("Document $id not found.");

        final doc = results.first;
        final path = doc['file_path'] as String;
        final file = File(path);

        if (!await file.exists()) {
          throw Exception("File not found on disk: $path");
        }

        final fileContent = await file.readAsString();
        return "Content of document '${doc['title']}':\n\n$fileContent";

      default:
        throw Exception("Unknown action '$action' for DocumentTool.");
    }
  }
}
