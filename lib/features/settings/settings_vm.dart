import 'dart:io';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:archive/archive_io.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:mobile_assistant/core/db/app_database.dart';
import 'package:sqflite/sqflite.dart';

class SettingsVM extends BaseViewModel {
  final storage = const FlutterSecureStorage();
  
  bool isAppLockEnabled = false;
  ThemeMode themeMode = ThemeMode.system;

  Future<void> init() async {
    isAppLockEnabled = await storage.read(key: 'app_lock_enabled') == 'true';
    
    final themeStr = await storage.read(key: 'theme_mode');
    if (themeStr == 'light') themeMode = ThemeMode.light;
    else if (themeStr == 'dark') themeMode = ThemeMode.dark;
    else themeMode = ThemeMode.system;
    
    notifyListeners();
  }

  Future<void> toggleAppLock(bool value) async {
    isAppLockEnabled = value;
    await storage.write(key: 'app_lock_enabled', value: value.toString());
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode = mode;
    String val = 'system';
    if (mode == ThemeMode.light) val = 'light';
    if (mode == ThemeMode.dark) val = 'dark';
    await storage.write(key: 'theme_mode', value: val);
    notifyListeners();
  }

  Future<void> exportData(BuildContext context) async {
    setBusy(true);
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final dbPath = await getDatabasesPath();
      
      final dbFile = File(p.join(dbPath, 'app.db'));
      final extDir = await getExternalStorageDirectory();
      final docsDir = Directory('${extDir?.path ?? appDir.path}/documents');

      var encoder = ZipFileEncoder();
      final zipPath = p.join(appDir.path, 'export.zip');
      encoder.create(zipPath);
      
      if (await dbFile.exists()) {
        encoder.addFile(dbFile);
      }
      if (await docsDir.exists()) {
        encoder.addDirectory(docsDir);
      }
      encoder.close();

      // ignore: deprecated_member_use
      await Share.shareXFiles([XFile(zipPath)], text: 'Mobile Assistant Backup');
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      setBusy(false);
    }
  }

  Future<void> deleteAllData(BuildContext context) async {
    setBusy(true);
    try {
      final dbPath = await getDatabasesPath();
      final path = p.join(dbPath, 'app.db');
      
      // Delete DB
      await deleteDatabase(path);
      // Re-init empty

      // Delete documents
      final appDir = await getApplicationDocumentsDirectory();
      final extDir = await getExternalStorageDirectory();
      final docsDir = Directory('${extDir?.path ?? appDir.path}/documents');
      if (await docsDir.exists()) {
        await docsDir.delete(recursive: true);
      }

      // Re-init empty
      await AppDatabase.instance.database;

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All data deleted.')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      setBusy(false);
    }
  }
}
