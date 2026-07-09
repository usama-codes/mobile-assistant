import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:mobile_assistant/core/agent/agent_tool.dart';
import 'package:mobile_assistant/core/db/app_database.dart';
import 'package:mobile_assistant/core/services/embedding_service.dart';
import 'package:mobile_assistant/core/services/crypto_service.dart';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

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
        final isSensitive = parameters['is_sensitive'] == true;
        
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

        final extDir = await getExternalStorageDirectory();
        final docDir = Directory('${extDir?.path ?? (await getApplicationDocumentsDirectory()).path}/documents');
        if (!await docDir.exists()) {
          await docDir.create(recursive: true);
        }

        final safeTitle = title.toString().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
        final fileName = '${safeTitle}_${DateTime.now().millisecondsSinceEpoch}.md';
        final file = File('${docDir.path}/$fileName');
        
        String textToSave = content.toString();
        if (isSensitive) {
          textToSave = await CryptoService.encrypt(textToSave);
        }
        
        await file.writeAsString(textToSave);

        // Generate embedding using the first 2000 chars of the document (unencrypted)
        String textToEmbed = "\\\n";
        if (textToEmbed.length > 2000) {
          textToEmbed = textToEmbed.substring(0, 2000);
        }
        final embedding = await EmbeddingService.getEmbedding(textToEmbed);
        final embeddingStr = jsonEncode(embedding);

        await db.insert('documents', {
          'title': title,
          'folder': folder,
          'tags': tagsStr,
          'original_source': originalSource,
          'document_type': documentType,
          'file_path': file.path,
          'createdAt': DateTime.now().toIso8601String(),
          'embedding': embeddingStr,
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
        return matches.map((d) => "ID: ${d['id']} - Title: ${d['title']}").join("\n");

      case 'read_document':
        final id = parameters['id'];
        if (id == null) return "Document ID required.";
        
        final results = await db.query('documents', where: 'id = ?', whereArgs: [id]);
        if (results.isEmpty) return "Document not found.";
        
        final doc = results.first;
        final file = File(doc['file_path'].toString());
        if (!await file.exists()) return "Document file missing on disk.";
        
        String content = await file.readAsString();
        if (content.contains(':') && content.length > 24) {
          try {
            content = await CryptoService.decrypt(content);
          } catch (e) {
            // maybe it was just a regular string with a colon
          }
        }
        return "--- ${doc['title']} ---\n$content";

      case 'process_nlp':
        final id = parameters['id'];
        final operation = parameters['operation'];
        final language = parameters['language'];
        
        if (id == null || operation == null) return "Missing 'id' or 'operation'.";

        final results = await db.query('documents', where: 'id = ?', whereArgs: [id]);
        if (results.isEmpty) return "Document not found.";
        
        final doc = results.first;
        final file = File(doc['file_path'].toString());
        if (!await file.exists()) return "Document file missing on disk.";
        
        String content = await file.readAsString();
        if (content.contains(':') && content.length > 24) {
          try {
            content = await CryptoService.decrypt(content);
          } catch (e) {
             // ignore
          }
        }
        
        final apiKey = dotenv.env['GEMINI_API_KEY'];
        if (apiKey == null) throw Exception("API Key not found.");
        
        String prompt = "You are an expert NLP processor.\\n";
        prompt += "Perform the following operation on the provided document content: $operation\\n";
        if (language != null) {
          prompt += "Target language: $language\\n";
        }
        prompt += "\\nDOCUMENT TITLE: ${doc['title']}\\n";
        prompt += "\\nCONTENT:\\n$content\\n";

        final fallbackModels = ['gemini-2.5-flash', 'gemini-2.5-pro', 'gemini-1.5-pro', 'gemini-1.5-flash'];
        GenerateContentResponse? response;
        for (final modelName in fallbackModels) {
          try {
            final model = GenerativeModel(model: modelName, apiKey: apiKey);
            response = await model.generateContent([Content.text(prompt)]);
            break;
          } catch (e) {
            print("NLP Model $modelName failed: $e");
          }
        }
        
        final generatedText = response?.text?.trim() ?? "";
        
        if (generatedText.isEmpty) return "NLP operation failed to generate content.";
        
        final newTitle = "$operation result for: ${doc['title']}";
        return await execute('create_document', {
          'title': newTitle,
          'content': generatedText,
          'folder': 'nlp_results',
          'tags': [operation],
          'original_source': 'nlp_pipeline',
        });

      default:
        return "Unknown action: $action in DocumentTool";
    }
  }

  Future<String> searchDocumentsRAG(String query) async {
    final db = await AppDatabase.instance.database;
    final queryEmbedding = await EmbeddingService.getEmbedding(query);
    
    final results = await db.query('documents');
    List<Map<String, dynamic>> scoredDocs = [];
    
    for (var row in results) {
      if (row['embedding'] != null) {
        final List<dynamic> embDynamic = jsonDecode(row['embedding'].toString());
        final emb = embDynamic.map((e) => (e as num).toDouble()).toList();
        final score = EmbeddingService.cosineSimilarity(queryEmbedding, emb);
        scoredDocs.add({
          'id': row['id'],
          'title': row['title'],
          'score': score,
          'file_path': row['file_path'],
        });
      }
    }
    
    scoredDocs.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));
    final topDocs = scoredDocs.take(3).where((m) => (m['score'] as double) > 0.6).toList();
    
    if (topDocs.isEmpty) return "No relevant documents found.";
    
    List<String> excerpts = [];
    for (var d in topDocs) {
      final file = File(d['file_path'].toString());
      if (await file.exists()) {
        String content = await file.readAsString();
        if (content.contains(':') && content.length > 24) {
          try {
            content = await CryptoService.decrypt(content);
          } catch (e) {
             // ignore
          }
        }
        
        if (content.length > 500) content = content.substring(0, 500) + '...';
        excerpts.add("[Doc ${d['id']}: ${d['title']} (Score: ${d['score']})]\\n${content}");
      }
    }
    
    return excerpts.join("\\n\\n");
  }
}
