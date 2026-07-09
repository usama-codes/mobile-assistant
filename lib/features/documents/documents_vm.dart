import 'dart:io';
import 'package:mobile_assistant/core/db/app_database.dart';
import 'package:mobile_assistant/core/services/crypto_service.dart';
import 'package:sqflite/sqflite.dart';
import 'package:stacked/stacked.dart';

class DocumentsVM extends BaseViewModel {
  Database? db;
  List<Map<String, dynamic>> documents = [];

  Future<void> loadDB() async {
    db ??= await AppDatabase.instance.database;
  }

  Future<void> getDocuments() async {
    setBusy(true);
    await loadDB();
    final result = await db!.query('documents', orderBy: 'createdAt DESC');
    documents = result.toList();
    setBusy(false);
  }

  Future<void> deleteDocument(int id) async {
    await loadDB();
    await db!.delete('documents', where: 'id = ?', whereArgs: [id]);
    await getDocuments();
  }

  Future<String> getDocumentContent(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      return "Document file missing on disk.";
    }
    try {
      String content = await file.readAsString();
      if (content.contains(':') && content.length > 24) {
        try {
          content = await CryptoService.decrypt(content);
        } catch (e) {
          // maybe it was just a regular string with a colon
        }
      }
      return content;
    } catch (e) {
      return "Error reading document: $e";
    }
  }
}
