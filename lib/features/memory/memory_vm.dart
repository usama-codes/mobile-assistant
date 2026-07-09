import 'package:stacked/stacked.dart';
import 'package:mobile_assistant/core/db/app_database.dart';
import 'package:mobile_assistant/core/services/crypto_service.dart';

class MemoryVM extends BaseViewModel {
  List<Map<String, dynamic>> memories = [];

  Future<void> loadMemories() async {
    setBusy(true);
    final db = await AppDatabase.instance.database;
    final results = await db.query('memories', orderBy: 'createdAt DESC');
    
    List<Map<String, dynamic>> decoded = [];
    for (var row in results) {
      String fact = row['fact'].toString();
      if (fact.contains(':') && fact.length > 24) {
        try {
          fact = await CryptoService.decrypt(fact);
        } catch (e) {
          // ignore
        }
      }
      decoded.add({
        'id': row['id'],
        'fact': fact,
        'importance': row['importance'],
        'createdAt': row['createdAt'],
      });
    }
    memories = decoded;
    setBusy(false);
  }

  Future<void> deleteMemory(int id) async {
    final db = await AppDatabase.instance.database;
    await db.delete('memories', where: 'id = ?', whereArgs: [id]);
    await loadMemories();
  }

  Future<void> addMemory(String fact) async {
    setBusy(true);
    final encryptedFact = await CryptoService.encrypt(fact);
    final db = await AppDatabase.instance.database;
    await db.insert('memories', {
      'fact': encryptedFact,
      'importance': 5.0,
      'createdAt': DateTime.now().toIso8601String(),
    });
    await loadMemories();
  }
}
