import 'package:mobile_assistant/shared/models/priority.dart';
import 'package:mobile_assistant/shared/models/task_item.dart';
import 'package:sqflite/sqlite_api.dart';
import 'package:stacked/stacked.dart';
import 'package:mobile_assistant/core/db/app_database.dart';

class TaskVM extends BaseViewModel {
  Database? db;
  List<TaskItem> tasks = [];

  Future<void> loadDB() async {
    db ??= await AppDatabase.instance.database;
  }

  Future<void> createTask({
    required String title,
    required String description,
    required DateTime dueDate,
    required bool completed,
    required Priority priority,
  }) async {
    await loadDB();
    if (title.isEmpty) {
      throw Exception("Title cannot be empty");
    }

    TaskItem task = TaskItem(
      title: title,
      description: description,
      dueDate: dueDate,
      completed: completed,
      priority: priority,
    );

    await db!.insert('tasks', task.toMap());

    await loadTasks();
  }

  Future<dynamic> loadTasks() async {
    await loadDB();
    final result = await db!.query('tasks');
    var allTasks = result.map((e) => TaskItem.fromMap(e)).toList();
    
    // Filter out completed tasks
    tasks = allTasks.where((t) => !t.completed).toList();
    
    // Sort tasks: earliest deadline first, then highest priority
    tasks.sort((a, b) {
      int dateCompare = a.dueDate.compareTo(b.dueDate);
      if (dateCompare != 0) return dateCompare;
      
      // priority: critical(3) > high(2) > medium(1) > low(0)
      return b.priority.index.compareTo(a.priority.index);
    });
    
    notifyListeners();
  }

  Future<void> updateTask(
    int id,
    String title,
    String description,
    DateTime dueDate,
    bool completed,
    Priority priority,
  ) async {
    await loadDB();
    if (title.isEmpty) {
      throw Exception("Title cannot be empty");
    }

    TaskItem task = TaskItem(
      title: title,
      description: description,
      dueDate: dueDate,
      completed: completed,
      priority: priority,
    );

    await db!.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [id],
    );
    await loadTasks();
  }

  Future<void> deleteTask(int id) async {
    await loadDB();
    await db!.delete('tasks', where: 'id = ?', whereArgs: [id]);
    await loadTasks();
  }

  Future<void> toggleTask(TaskItem task) async {
    await loadDB();
    task.completed = !task.completed;

    await db!.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );

    await loadTasks();
  }
}
