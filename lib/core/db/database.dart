import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

class Tasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().nullable()();
  TextColumn get description => text().nullable()();
  TextColumn get dueDate => text().nullable()();
  IntColumn get completed => integer().nullable()(); // 0 or 1
  TextColumn get priority => text().nullable()();
  TextColumn get recurrenceRule => text().nullable()(); // RRULE string
  TextColumn get lastCompletedAt => text().nullable()(); // ISO8601
}

class ChatSessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().nullable()();
  TextColumn get createdAt => text().nullable()();
}

class Messages extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get sessionId => integer().nullable()();
  TextColumn get content => text().nullable()();
  IntColumn get isUser => integer().nullable()(); // 0 or 1
  TextColumn get timestamp => text().nullable()();
  TextColumn get attachmentPath => text().nullable()();
}

// Memories table removed (now uses ObjectBox)
class Documents extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().nullable()();
  TextColumn get folder => text().nullable()();
  TextColumn get tags => text().nullable()();
  TextColumn get originalSource => text().named('original_source').nullable()();
  TextColumn get documentType => text().named('document_type').nullable()();
  TextColumn get filePath => text().named('file_path').nullable()();
  TextColumn get createdAt => text().nullable()();
  TextColumn get embedding => text().nullable()();
}

class InteractionLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get userMessage => text().nullable()();
  TextColumn get geminiResponse => text().nullable()();
  TextColumn get executedAction => text().nullable()();
  TextColumn get status => text().nullable()();
  TextColumn get timestamp => text().nullable()();
}

@DriftDatabase(tables: [Tasks, ChatSessions, Messages, Documents, InteractionLogs])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 9;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) async {
        await m.createAll();
        final now = DateTime.now().toIso8601String();
        await into(chatSessions).insert(
          ChatSessionsCompanion.insert(
            title: const Value('Default Chat'),
            createdAt: Value(now),
          ),
        );
      },
      onUpgrade: (m, from, to) async {
        if (from < 9) {
          // Add recurrence columns to tasks table
          try {
            await m.addColumn(tasks, tasks.recurrenceRule);
          } catch (_) {}
          try {
            await m.addColumn(tasks, tasks.lastCompletedAt);
          } catch (_) {}
        }
      },
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getDatabasesPath();
    final file = File(p.join(dbFolder, 'app.db'));
    
    // We are migrating from sqflite. Sqflite stores databases in getDatabasesPath.
    // For Drift with Native, we just point to the same file.
    return NativeDatabase.createInBackground(file);
  });
}

// Helper to get sqflite's database path equivalent in pure dart
Future<String> getDatabasesPath() async {
  if (Platform.isAndroid) {
    final dir = await getApplicationSupportDirectory();
    final databasesDir = Directory(p.join(dir.parent.path, 'databases'));
    if (!await databasesDir.exists()) {
      await databasesDir.create(recursive: true);
    }
    return databasesDir.path;
  } else if (Platform.isIOS || Platform.isMacOS) {
    final dir = await getLibraryDirectory();
    return dir.path;
  }
  final dir = await getApplicationDocumentsDirectory();
  return dir.path;
}


