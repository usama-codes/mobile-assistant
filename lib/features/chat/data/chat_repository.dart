import 'package:drift/drift.dart';
import 'package:mobile_assistant/core/db/database.dart';
import 'package:mobile_assistant/core/providers/database_provider.dart';
import 'package:mobile_assistant/shared/models/chat_message.dart' as dom;
import 'package:mobile_assistant/shared/models/chat_session.dart' as dom;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'chat_repository.g.dart';

@riverpod
ChatRepository chatRepository(Ref ref) {
  return ChatRepository(ref.watch(appDatabaseProvider));
}

class ChatRepository {
  ChatRepository(this._db);
  final AppDatabase _db;

  Stream<List<dom.ChatSession>> watchSessions() {
    return _db.select(_db.chatSessions).watch().map((rows) {
      return rows.map((row) => row.toDomain()).toList();
    });
  }

  Future<List<dom.ChatSession>> getSessions() async {
    final rows = await _db.select(_db.chatSessions).get();
    return rows.map((row) => row.toDomain()).toList();
  }

  Future<dom.ChatSession> insertSession(dom.ChatSession session) async {
    final id = await _db
        .into(_db.chatSessions)
        .insert(
          ChatSessionsCompanion.insert(
            title: Value(session.title),
            createdAt: Value(session.createdAt.toIso8601String()),
          ),
        );
    session.id = id;
    return session;
  }

  Future<void> updateSession(dom.ChatSession session) async {
    await _db
        .update(_db.chatSessions)
        .replace(
          ChatSession(
            id: session.id!,
            title: session.title,
            createdAt: session.createdAt.toIso8601String(),
          ),
        );
  }

  Future<void> deleteSession(int id) async {
    // Delete associated messages first
    await (_db.delete(_db.messages)..where((m) => m.sessionId.equals(id))).go();
    await (_db.delete(_db.chatSessions)..where((s) => s.id.equals(id))).go();
  }

  Stream<List<dom.ChatMessage>> watchMessages(int sessionId) {
    final query = _db.select(_db.messages)
      ..where((m) => m.sessionId.equals(sessionId));
    return query.watch().map((rows) {
      return rows.map((row) => row.toDomain()).toList();
    });
  }

  Future<List<dom.ChatMessage>> getMessages(int sessionId) async {
    final query = _db.select(_db.messages)
      ..where((m) => m.sessionId.equals(sessionId));
    final rows = await query.get();
    return rows.map((row) => row.toDomain()).toList();
  }

  Future<dom.ChatMessage> insertMessage(dom.ChatMessage message) async {
    final id = await _db
        .into(_db.messages)
        .insert(
          MessagesCompanion.insert(
            sessionId: Value(message.sessionId),
            content: Value(message.content),
            isUser: Value(message.isUser ? 1 : 0),
            timestamp: Value(message.timestamp.toIso8601String()),
            attachmentPath: Value(message.attachmentPath),
          ),
        );
    message.id = id;
    return message;
  }

  Future<void> clearMessagesForSession(int sessionId) async {
    await (_db.delete(
      _db.messages,
    )..where((m) => m.sessionId.equals(sessionId))).go();
  }

  Future<void> deleteMessage(int id) async {
    await (_db.delete(_db.messages)..where((m) => m.id.equals(id))).go();
  }
}

extension ChatSessionExtension on ChatSession {
  dom.ChatSession toDomain() {
    return dom.ChatSession(
      id: id,
      title: title ?? 'Untitled',
      createdAt: createdAt != null
          ? DateTime.parse(createdAt!)
          : DateTime.now(),
    );
  }
}

extension MessageDataExtension on Message {
  dom.ChatMessage toDomain() {
    return dom.ChatMessage(
      sessionId: sessionId,
      content: content ?? '',
      isUser: isUser == 1,
      timestamp: timestamp != null
          ? DateTime.parse(timestamp!)
          : DateTime.now(),
      attachmentPath: attachmentPath,
    )..id = id;
  }
}
