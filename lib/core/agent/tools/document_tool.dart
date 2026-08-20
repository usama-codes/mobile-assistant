import 'dart:convert';
import 'dart:io';

import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:mobile_assistant/core/agent/agent_tool.dart';
import 'package:mobile_assistant/core/db/app_database.dart';
import 'package:mobile_assistant/core/services/analytics_service.dart';
import 'package:mobile_assistant/core/services/embedding_service.dart';
import 'package:mobile_assistant/core/services/inference_service.dart';
import 'package:mobile_assistant/core/services/vault_service.dart';
import 'package:path_provider/path_provider.dart';

class DocumentTool implements AgentTool {
  @override
  List<FunctionDeclaration> get declarations => [
    FunctionDeclaration(
      'create_document',
      'Save a document to the knowledge base',
      Schema(
        SchemaType.object,
        properties: {
          'title': Schema(SchemaType.string),
          'content': Schema(SchemaType.string),
          'folder': Schema(
            SchemaType.string,
            description: 'Category folder, e.g. general, work, personal',
          ),
          'is_sensitive': Schema(
            SchemaType.boolean,
            description: 'Encrypt file if true',
          ),
        },
        requiredProperties: ['title', 'content'],
      ),
    ),
    FunctionDeclaration(
      'search_documents',
      'Search saved documents by keyword or topic',
      Schema(
        SchemaType.object,
        properties: {
          'keyword': Schema(SchemaType.string, description: 'Search keyword'),
        },
        requiredProperties: ['keyword'],
      ),
    ),
    FunctionDeclaration(
      'read_document',
      'Read the full content of a saved document by id',
      Schema(
        SchemaType.object,
        properties: {
          'id': Schema(SchemaType.integer, description: 'Document id'),
        },
        requiredProperties: ['id'],
      ),
    ),
    FunctionDeclaration(
      'process_nlp',
      'Run an NLP operation on a saved document',
      Schema(
        SchemaType.object,
        properties: {
          'id': Schema(SchemaType.integer),
          'operation': Schema(
            SchemaType.string,
            description:
                'summarize, translate, extract_entities, extract_keywords, generate_flashcards, generate_study_guide, extract_tasks',
          ),
        },
        requiredProperties: ['id', 'operation'],
      ),
    ),
  ];

  @override
  bool canHandle(String functionName) {
    const handled = {
      'create_document',
      'search_documents',
      'read_document',
      'process_nlp',
    };
    return handled.contains(functionName);
  }

  @override
  String get name => 'document_tool';

  @override
  String get description =>
      'Create, read, and search markdown documents in the knowledge base.';

  @override
  Future<String> execute(String action, Map<String, dynamic> parameters) async {
    final db = await AppDatabase.instance.database;

    switch (action) {
      case 'create_document':
        final title = parameters['title'];
        final content = parameters['content'];
        final isSensitive = parameters['is_sensitive'] == true;

        if (title == null || title.toString().trim().isEmpty) {
          throw Exception('Document title is required.');
        }
        if (content == null) {
          throw Exception('Document content is required.');
        }

        final folder = parameters['folder'] ?? 'general';
        final tags = parameters['tags'] ?? [];
        final tagsStr = jsonEncode(tags);
        final documentType = parameters['document_type'] ?? 'markdown';
        final originalSource = parameters['original_source'] ?? 'assistant';

        final extDir = await getExternalStorageDirectory();
        final docDir = Directory(
          '${extDir?.path ?? (await getApplicationDocumentsDirectory()).path}/documents',
        );
        if (!await docDir.exists()) {
          await docDir.create(recursive: true);
        }

        final safeTitle = title.toString().replaceAll(
          RegExp('[^a-zA-Z0-9]'),
          '_',
        );
        final fileName =
            '${safeTitle}_${DateTime.now().millisecondsSinceEpoch}.md';
        final file = File('${docDir.path}/$fileName');

        var textToSave = content.toString();
        if (isSensitive) {
          textToSave = await VaultService.instance.encrypt(textToSave);
        }

        await file.writeAsString(textToSave);

        // Embed locally (privacy boundary). May be null while the ONNX model
        // downloads on first use — rows still save with a NULL embedding and
        // search degrades to keyword fallback until the model is ready.
        var textToEmbed = content.toString();
        if (textToEmbed.length > 2000) {
          textToEmbed = textToEmbed.substring(0, 2000);
        }
        final embedding = await EmbeddingService.getEmbedding(textToEmbed);
        final embeddingStr = embedding == null ? null : jsonEncode(embedding);

        final docId = await db.insert('documents', {
          'title': title,
          'folder': folder,
          'tags': tagsStr,
          'original_source': originalSource,
          'document_type': documentType,
          'file_path': file.path,
          'createdAt': DateTime.now().toIso8601String(),
          'embedding': embeddingStr,
          'is_encrypted': isSensitive ? 1 : 0,
        });

        final chunks = _chunkText(content.toString());
        for (var i = 0; i < chunks.length; i++) {
          final plainChunk = chunks[i];
          final chunkEmb = await EmbeddingService.getEmbedding(plainChunk);
          var chunkToSave = plainChunk;
          if (isSensitive) {
             chunkToSave = await VaultService.instance.encrypt(chunkToSave);
          }
          await db.insert('document_chunks', {
            'documentId': docId,
            'chunkIndex': i,
            'content': chunkToSave,
            'embedding': chunkEmb == null ? null : jsonEncode(chunkEmb),
          });
        }

        return "Created document '$title' successfully.";

      case 'search_documents':
        final keyword = parameters['keyword']?.toString().toLowerCase();
        if (keyword == null || keyword.isEmpty) {
          return 'No keyword provided for search.';
        }

        final results = await db.query('documents');
        final matches = results.where((doc) {
          final t = doc['title'].toString().toLowerCase();
          final tags = doc['tags'].toString().toLowerCase();
          return t.contains(keyword) || tags.contains(keyword);
        }).toList();

        if (matches.isEmpty) return "No documents found matching '$keyword'.";
        return matches
            .map((d) => "ID: ${d['id']} - Title: ${d['title']}")
            .join('\n');

      case 'read_document':
        final id = parameters['id'];
        if (id == null) return 'Document ID required.';

        final results = await db.query(
          'documents',
          where: 'id = ?',
          whereArgs: [id],
        );
        if (results.isEmpty) return 'Document not found.';

        final doc = results.first;
        final file = File(doc['file_path'].toString());
        if (!await file.exists()) return 'Document file missing on disk.';

        var content = await file.readAsString();
        if (VaultService.instance.isEncrypted(content)) {
          try {
            content = await VaultService.instance.decrypt(content);
          } catch (e) {
            // maybe it was just a regular string with a colon
          }
        }
        return "--- ${doc['title']} ---\n$content";

      case 'process_nlp':
        final id = parameters['id'];
        final operation = parameters['operation'];
        final language = parameters['language'];

        if (id == null || operation == null) {
          return "Missing 'id' or 'operation'.";
        }

        final results = await db.query(
          'documents',
          where: 'id = ?',
          whereArgs: [id],
        );
        if (results.isEmpty) return 'Document not found.';

        final doc = results.first;
        final file = File(doc['file_path'].toString());
        if (!await file.exists()) return 'Document file missing on disk.';

        var content = await file.readAsString();
        if (VaultService.instance.isEncrypted(content)) {
          try {
            content = await VaultService.instance.decrypt(content);
          } catch (e) {
            // ignore
          }
        }

        // PRIVACY BOUNDARY: document content is processed entirely on-device
        // by the local Gemma model — never sent to a cloud API.
        const systemInstruction = 'You are an expert NLP processor. '
            'Perform the requested operation on the provided document content '
            'and return only the result, nothing else.';
        final prompt = '''
Perform the following operation on the provided document content: $operation
${language != null ? 'Target language: $language\n' : ''}
DOCUMENT TITLE: ${doc['title']}

CONTENT:
$content
''';

        final generatedText = await InferenceService.instance.generateLocalOnly(
          systemInstruction: systemInstruction,
          prompt: prompt,
        );

        if (generatedText == null || generatedText.trim().isEmpty) {
          return 'NLP operation failed to generate content. '
              'Document processing runs on the local model — enable it in Settings.';
        }

        final newTitle = "$operation result for: ${doc['title']}";
        return execute('create_document', {
          'title': newTitle,
          'content': generatedText,
          'folder': 'nlp_results',
          'tags': [operation],
          'original_source': 'nlp_pipeline',
        });

      default:
        return 'Unknown action: $action in DocumentTool';
    }
  }

  Future<String> searchDocumentsRAG(String query) async {
    final db = await AppDatabase.instance.database;
    final queryEmbedding = await EmbeddingService.getEmbedding(query);

    // Local embeddings unavailable (model not yet downloaded) → degrade to
    // keyword search instead of failing or silently returning empty.
    if (queryEmbedding == null) {
      logger.i('RAG: local embedder unavailable, using keyword fallback.');
      return _keywordSearchContext(query);
    }

    final results = await db.rawQuery('''
      SELECT c.content, c.embedding, d.id as docId, d.title
      FROM document_chunks c
      JOIN documents d ON c.documentId = d.id
      WHERE c.embedding IS NOT NULL
    ''');
    final scoredChunks = <Map<String, dynamic>>[];

    for (final row in results) {
      if (row['embedding'] != null) {
        final embDynamic =
            jsonDecode(row['embedding'].toString()) as List<dynamic>;
        final emb = embDynamic.map((e) => (e as num).toDouble()).toList();
        final score = EmbeddingService.cosineSimilarity(queryEmbedding, emb);
        scoredChunks.add({
          'docId': row['docId'],
          'title': row['title'],
          'score': score,
          'content': row['content'],
        });
      }
    }

    scoredChunks.sort(
      (a, b) => (b['score'] as double).compareTo(a['score'] as double),
    );
    final topChunks = scoredChunks
        .take(5)
        .where((m) => (m['score'] as double) > 0.6)
        .toList();

    if (topChunks.isEmpty) return '';

    final excerpts = <String>[];
    for (final c in topChunks) {
      var chunkContent = c['content'] as String;
      if (VaultService.instance.isEncrypted(chunkContent)) {
        try {
          chunkContent = await VaultService.instance.decrypt(chunkContent);
        } catch (e) {
          // ignore
        }
      }
      excerpts.add(
        "[Doc ${c['docId']}: ${c['title']} (Score: ${c['score']})]\\n$chunkContent",
      );
    }

    return excerpts.join(r'\n\n');
  }

  /// Keyword fallback for RAG when the local embedding model is unavailable.
  /// Searches document titles, tags, and folders — a coarse but functional
  /// retrieval so doc queries never silently fail offline.
  Future<String> _keywordSearchContext(String query) async {
    final db = await AppDatabase.instance.database;
    final keyword = query.trim().toLowerCase();
    if (keyword.isEmpty) return '';

    final results = await db.query('documents');
    final matches = results.where((doc) {
      final t = doc['title'].toString().toLowerCase();
      final tags = doc['tags'].toString().toLowerCase();
      final folder = doc['folder'].toString().toLowerCase();
      return t.contains(keyword) ||
          tags.contains(keyword) ||
          folder.contains(keyword);
    }).take(3).toList();

    if (matches.isEmpty) return '';

    final excerpts = <String>[];
    for (final doc in matches) {
      final file = File(doc['file_path'].toString());
      if (!await file.exists()) continue;

      var content = await file.readAsString();
      if (VaultService.instance.isEncrypted(content)) {
        try {
          content = await VaultService.instance.decrypt(content);
        } catch (e) {
          // ignore
        }
      }
      if (content.length > 2000) {
        content = content.substring(0, 2000);
      }
      excerpts.add(
        "[Doc ${doc['id']}: ${doc['title']} (keyword match)]\n$content",
      );
    }

    return excerpts.isEmpty ? '' : excerpts.join('\n\n');
  }

  List<String> _chunkText(String text, {int chunkSize = 1000, int overlap = 100}) {
    if (text.isEmpty) return [];
    final chunks = <String>[];
    int start = 0;
    while (start < text.length) {
      final end = (start + chunkSize < text.length) ? start + chunkSize : text.length;
      chunks.add(text.substring(start, end));
      if (end == text.length) break;
      start = end - overlap;
    }
    return chunks;
  }
}
