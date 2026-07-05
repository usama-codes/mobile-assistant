import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._init();

  static Database? _database;

  AppDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB('app.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 6,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''CREATE TABLE chat_sessions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        createdAt TEXT
      )''');
      
      await db.execute('ALTER TABLE messages ADD COLUMN sessionId INTEGER');
      
      final now = DateTime.now().toIso8601String();
      await db.execute('INSERT INTO chat_sessions (title, createdAt) VALUES ("Default Chat", "$now")');
      
      await db.execute('UPDATE messages SET sessionId = 1');
    }
    
    if (oldVersion < 3) {
      await db.execute('''CREATE TABLE interaction_logs(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userMessage TEXT,
        geminiResponse TEXT,
        executedAction TEXT,
        status TEXT,
        timestamp TEXT
      )''');
    }

    if (oldVersion < 4) {
      await db.execute('ALTER TABLE memories ADD COLUMN embedding TEXT');
    }

    if (oldVersion < 5) {
      await db.execute('''CREATE TABLE documents(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        folder TEXT,
        tags TEXT,
        original_source TEXT,
        document_type TEXT,
        file_path TEXT,
        createdAt TEXT
      )''');
    }

    if (oldVersion < 6) {
      await db.execute('ALTER TABLE messages ADD COLUMN attachmentPath TEXT');
    }
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''CREATE TABLE users(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT,
      email TEXT
    )''');
    
    await db.execute('''CREATE TABLE tasks(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT,
      description TEXT,
      dueDate TEXT,
      completed INTEGER,
      priority TEXT
    )''');
    
    await db.execute('''CREATE TABLE reminders(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      taskId INTEGER,
      reminderTime TEXT,
      FOREIGN KEY(taskId) REFERENCES tasks(id)
    )''');
    
    await db.execute('''CREATE TABLE notes(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT,
      content TEXT,
      createdAt TEXT
    )''');
    
    await db.execute('''CREATE TABLE memories(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      fact TEXT,
      importance REAL,
      createdAt TEXT,
      embedding TEXT
    )''');
    
    await db.execute('''CREATE TABLE messages(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      sessionId INTEGER,
      content TEXT,
      isUser INTEGER,
      timestamp TEXT,
      attachmentPath TEXT
    )''');
    
    await db.execute('''CREATE TABLE chat_sessions(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT,
      createdAt TEXT
    )''');
    
    await db.execute('''CREATE TABLE interaction_logs(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      userMessage TEXT,
      geminiResponse TEXT,
      executedAction TEXT,
      status TEXT,
      timestamp TEXT
    )''');
    
    await db.execute('''CREATE TABLE documents(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT,
      folder TEXT,
      tags TEXT,
      original_source TEXT,
      document_type TEXT,
      file_path TEXT,
      createdAt TEXT
    )''');
  }
}
