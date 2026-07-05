import 'package:mobile_assistant/core/db/app_database.dart';
import 'package:mobile_assistant/shared/models/memory_fact.dart';
import 'package:sqflite/sqflite.dart';
import 'package:stacked/stacked.dart';

class MemoryVM extends BaseViewModel {
  Database? db;
  List<MemoryFact> memories = [];

  Future<void> loadDB() async {
    db ??= await AppDatabase.instance.database;
  }

  Future<void> createMemory(
    String fact,
    double importance,
    DateTime createdAt,
  ) async {
    await loadDB();
    if (fact.isEmpty || importance < 0) {
      throw Exception("Mandatory fields cannot be empty");
    }
    
    MemoryFact memory = MemoryFact(
      fact: fact,
      importance: importance,
      createdAt: createdAt,
    );

    await db!.insert('memories', memory.toMap());

    notifyListeners();
  }

  Future<void> getMemories() async {
    await loadDB();
    final result = await db!.query('memories');
    memories = result.map((e) => MemoryFact.fromMap(e)).toList();
    notifyListeners();
  }

  Future<void> updateMemory(
    int id,
    String fact,
    double importance,
    DateTime createdAt,
  ) async {
    await loadDB();
    if (fact.isEmpty || importance < 0) {
      throw Exception("Mandatory fields must not be empty");
    }

    MemoryFact memory = MemoryFact(
      fact: fact,
      importance: importance,
      createdAt: createdAt,
    );

    await db!.update(
      'memories',
      memory.toMap(),
      where: 'id = ?',
      whereArgs: [memory.id],
    );

    notifyListeners();
  }

  Future<void> deleteMemory(int id) async {
    await loadDB();
    await db!.delete('memories', where: 'id = ?', whereArgs: [id]);
    notifyListeners();
  }
}
