import 'package:mobile_assistant/core/db/app_database.dart';
import 'package:mobile_assistant/shared/models/note_item.dart';
import 'package:sqflite/sqflite.dart';
import 'package:stacked/stacked.dart';

class NoteVM extends BaseViewModel {
  Database? db;
  List<NoteItem> notes = [];

  Future<void> loadDB() async {
    db ??= await AppDatabase.instance.database;
  }

  Future<void> createNote(
    String title,
    String content,
    DateTime createdAt,
  ) async {
    await loadDB();
    if (title.isEmpty || content.isEmpty) {
      throw Exception("Mandatory fields cannot be empty");
    }

    NoteItem note = NoteItem(
      title: title,
      content: content,
      createdAt: createdAt,
    );

    await db!.insert('notes', note.toMap());

    notifyListeners();
  }

  Future<dynamic> getNotes() async {
    await loadDB();
    final result = await db!.query('notes');
    notes = result.map((e) => NoteItem.fromMap(e)).toList();
    notifyListeners();
  }

  Future<void> updateNote(
    int id,
    String title,
    String content,
    DateTime createdAt,
  ) async {
    await loadDB();
    if (title.isEmpty || content.isEmpty) {
      throw Exception("Mandatory fields must not be empty");
    }

    NoteItem note = NoteItem(
      title: title,
      content: content,
      createdAt: createdAt,
    );

    await db!.update(
      'notes',
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  Future<void> deleteNote(int id) async {
    await loadDB();
    await db!.delete('notes', where: 'id = ?', whereArgs: [id]);
    notifyListeners();
  }
}
