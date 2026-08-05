import 'package:drift/drift.dart';
import 'package:mobile_assistant/core/db/database.dart';
import 'package:mobile_assistant/core/providers/database_provider.dart';
import 'package:mobile_assistant/shared/models/priority.dart';
import 'package:mobile_assistant/shared/models/task_item.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'task_repository.g.dart';

class TaskRepository {
  TaskRepository(this._db);
  final AppDatabase _db;

  Stream<List<TaskItem>> watchTasks() {
    return _db.select(_db.tasks).watch().map((tasks) => tasks.map((t) => t.toDomain()).toList());
  }

  Future<List<TaskItem>> getAllTasks() async {
    final results = await _db.select(_db.tasks).get();
    return results.map((t) => t.toDomain()).toList();
  }

  Future<int> insertTask(TaskItem task) {
    return _db.into(_db.tasks).insert(
      TasksCompanion.insert(
        title: Value(task.title),
        description: Value(task.description),
        dueDate: Value(task.dueDate.toIso8601String()),
        completed: Value(task.completed ? 1 : 0),
        priority: Value(task.priority.name),
        recurrenceRule: Value(task.recurrenceRule),
        lastCompletedAt: Value(task.lastCompletedAt?.toIso8601String()),
      ),
    );
  }

  Future<bool> updateTask(TaskItem task) {
    return _db.update(_db.tasks).replace(
      TasksCompanion(
        id: Value(task.id!),
        title: Value(task.title),
        description: Value(task.description),
        dueDate: Value(task.dueDate.toIso8601String()),
        completed: Value(task.completed ? 1 : 0),
        priority: Value(task.priority.name),
        recurrenceRule: Value(task.recurrenceRule),
        lastCompletedAt: Value(task.lastCompletedAt?.toIso8601String()),
      ),
    );
  }

  Future<int> deleteTask(int id) {
    return (_db.delete(_db.tasks)..where((t) => t.id.equals(id))).go();
  }
}

extension TaskMapper on Task {
  TaskItem toDomain() {
    return TaskItem(
      title: title ?? '',
      description: description ?? '',
      dueDate: dueDate != null ? DateTime.parse(dueDate!) : DateTime.now(),
      completed: completed == 1,
      priority: priority != null
          ? Priority.values.firstWhere((e) => e.name == priority, orElse: () => Priority.medium)
          : Priority.medium,
      recurrenceRule: recurrenceRule,
      lastCompletedAt: lastCompletedAt != null ? DateTime.tryParse(lastCompletedAt!) : null,
    )..id = id;
  }
}

@riverpod
TaskRepository taskRepository(Ref ref) {
  return TaskRepository(ref.watch(appDatabaseProvider));
}
