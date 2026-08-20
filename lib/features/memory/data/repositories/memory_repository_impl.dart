import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:mobile_assistant/core/db/database.dart';
import 'package:mobile_assistant/core/db/objectbox.dart';
import 'package:mobile_assistant/core/services/embedding_service.dart';
import 'package:mobile_assistant/core/services/vault_service.dart';
import 'package:mobile_assistant/features/memory/data/entities/memory_entity.dart';
import 'package:mobile_assistant/features/memory/domain/models/memory_fact.dart'
    as dom;
import 'package:mobile_assistant/features/memory/domain/repositories/memory_repository.dart';
import 'package:mobile_assistant/objectbox.g.dart';

class MemoryRepositoryImpl implements MemoryRepository {
  MemoryRepositoryImpl(this._objectBox, this._db) {
    _box = _objectBox.store.box<MemoryEntity>();
    _migrateFromDriftIfNeeded();
  }
  final ObjectBox _objectBox;
  final AppDatabase _db; // Used for migration
  late final Box<MemoryEntity> _box;

  Future<void> _migrateFromDriftIfNeeded() async {
    try {
      // Check if memories table exists
      final check = await _db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type='table' AND name='memories';",
          )
          .get();
      if (check.isEmpty) return; // Already dropped or never existed

      final results = await _db.customSelect('SELECT * FROM memories').get();
      if (results.isNotEmpty) {
        final toInsert = <MemoryEntity>[];
        for (final row in results) {
          final data = row.data;
          final fact = (data['fact'] as String?) ?? '';

          List<double>? embedding;
          if (data['embedding'] != null) {
            try {
              final embDynamic =
                  jsonDecode(data['embedding'] as String) as List<dynamic>;
              embedding = embDynamic.map((e) => (e as num).toDouble()).toList();
            } catch (e) {
              // ignore
            }
          }

          toInsert.add(
            MemoryEntity(
              fact: fact,
              importance: (data['importance'] as num?)?.toDouble() ?? 0.5,
              createdAt: DateTime.parse(
                (data['createdAt'] as String?) ??
                    DateTime.now().toIso8601String(),
              ),
              embedding: embedding,
            ),
          );
        }

        if (toInsert.isNotEmpty) {
          _box.putMany(toInsert);
          debugPrint(
            'Migrated ${toInsert.length} memories from Drift to ObjectBox',
          );
        }
      }

      // Delete old memories table from Drift
      await _db.customStatement('DROP TABLE memories;');
      debugPrint('Dropped legacy memories table from Drift.');
    } catch (e) {
      debugPrint('Migration from Drift failed or already completed: $e');
    }
  }

  @override
  Future<List<dom.MemoryFact>> getAllMemories() async {
    final results = _box.getAll();
    final memories = <dom.MemoryFact>[];

    for (final entity in results) {
      var fact = entity.fact;
      if (VaultService.instance.isEncrypted(fact)) {
        try {
          fact = await VaultService.instance.decrypt(fact);
        } catch (e) {
          // Ignore decryption errors for now
        }
      }

      memories.add(
        dom.MemoryFact(
          id: entity.id,
          fact: fact,
          importance: entity.importance,
          createdAt: entity.createdAt,
        ),
      );
    }

    memories.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return memories;
  }

  @override
  Future<void> addMemory(
    String fact, {
    double importance = 0.5,
    bool isSensitive = false,
  }) async {
    final embedding = await EmbeddingService.getEmbedding(fact);

    var textToSave = fact;
    if (isSensitive) {
      textToSave = await VaultService.instance.encrypt(fact);
    }

    final entity = MemoryEntity(
      fact: textToSave,
      importance: importance,
      createdAt: DateTime.now(),
      embedding: embedding,
    );

    _box.put(entity);
  }

  @override
  Future<void> deleteMemory(int id) async {
    _box.remove(id);
  }

  @override
  Future<List<dom.MemoryFact>> searchMemories(
    String query, {
    int limit = 5,
  }) async {
    final queryEmbedding = await EmbeddingService.getEmbedding(query);

    // Local embeddings unavailable (model not yet downloaded) → keyword
    // fallback over memory text so search never silently returns nothing.
    if (queryEmbedding == null) {
      return _keywordSearchMemories(query, limit);
    }

    // Use ObjectBox native vector search
    // We request a bit more limit, then rerank with recency/importance
    final qb = _box.query(
      MemoryEntity_.embedding.nearestNeighborsF32(queryEmbedding, limit * 2),
    );
    final queryObj = qb.build();
    final results = queryObj.findWithScores();
    queryObj.close();

    final scoredMemories = <Map<String, dynamic>>[];

    for (final match in results) {
      final entity = match.object;

      // ObjectBox returns distance. Closer to 0 is better.
      // We convert distance to similarity score approx (1 - distance) or using exponential decay
      // Using simple conversion here
      // ObjectBox returns score.
      final distance = match.score;
      final semanticScore = distance;

      final recency = DateTime.now().difference(entity.createdAt).inDays;
      final recencyScore = 1.0 / (1.0 + recency);

      final importanceScore = entity.importance;

      final finalScore =
          (semanticScore * 0.6) +
          (recencyScore * 0.2) +
          (importanceScore * 0.2);

      var decryptedFact = entity.fact;
      if (VaultService.instance.isEncrypted(decryptedFact)) {
        try {
          decryptedFact = await VaultService.instance.decrypt(decryptedFact);
        } catch (e) {
          // ignore
        }
      }

      scoredMemories.add({
        'fact': dom.MemoryFact(
          id: entity.id,
          fact: decryptedFact,
          importance: importanceScore,
          createdAt: entity.createdAt,
        ),
        'score': finalScore,
      });
    }

    scoredMemories.sort(
      (a, b) => (b['score'] as double).compareTo(a['score'] as double),
    );
    return scoredMemories
        .take(limit)
        .map((m) => m['fact'] as dom.MemoryFact)
        .toList();
  }

  /// Keyword fallback when the local embedding model is unavailable.
  /// Substring-matches decrypted memory facts, newest first.
  Future<List<dom.MemoryFact>> _keywordSearchMemories(
    String query,
    int limit,
  ) async {
    final needle = query.trim().toLowerCase();
    final matches = <dom.MemoryFact>[];
    for (final entity in _box.getAll()) {
      var fact = entity.fact;
      if (VaultService.instance.isEncrypted(fact)) {
        try {
          fact = await VaultService.instance.decrypt(fact);
        } catch (e) {
          continue;
        }
      }
      if (needle.isEmpty || fact.toLowerCase().contains(needle)) {
        matches.add(
          dom.MemoryFact(
            id: entity.id,
            fact: fact,
            importance: entity.importance,
            createdAt: entity.createdAt,
          ),
        );
      }
    }
    matches.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return matches.take(limit).toList();
  }
}
