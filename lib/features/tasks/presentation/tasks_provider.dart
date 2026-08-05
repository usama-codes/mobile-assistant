import 'package:mobile_assistant/core/services/notification_service.dart';
import 'package:mobile_assistant/features/tasks/data/task_repository.dart';
import 'package:mobile_assistant/shared/models/priority.dart';
import 'package:mobile_assistant/shared/models/task_item.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'tasks_provider.g.dart';

/// Returns reminder duration before due date based on priority.
Duration _reminderOffset(Priority priority) {
  switch (priority) {
    case Priority.critical:
      return const Duration(hours: 1);
    case Priority.high:
      return const Duration(minutes: 30);
    case Priority.medium:
      return const Duration(minutes: 15);
    case Priority.low:
      return const Duration(minutes: 5);
  }
}

// Backwards-compatible alias for older provider name
final TasksNotifierProvider tasksNotifierProvider = tasksProvider;

@riverpod
class TasksNotifier extends _$TasksNotifier {
  @override
  Stream<List<TaskItem>> build() {
    final repo = ref.watch(taskRepositoryProvider);
    return repo.watchTasks().map((tasks) {
      // Filter out completed tasks (show all in provider; screen filters)
      final activeTasks = tasks.where((t) => !t.completed).toList();

      // Sort: earliest deadline first, then highest priority
      activeTasks.sort((a, b) {
        final dateCompare = a.dueDate.compareTo(b.dueDate);
        if (dateCompare != 0) return dateCompare;
        return b.priority.index.compareTo(a.priority.index);
      });

      return activeTasks;
    });
  }

  Future<void> createTask({
    required String title,
    required String description,
    required DateTime dueDate,
    required bool completed,
    required Priority priority,
    String? recurrenceRule,
  }) async {
    if (title.isEmpty) throw Exception('Title cannot be empty');

    final repo = ref.read(taskRepositoryProvider);
    final task = TaskItem(
      title: title,
      description: description,
      dueDate: dueDate,
      completed: completed,
      priority: priority,
      recurrenceRule: recurrenceRule,
    );
    final insertedId = await repo.insertTask(task);

    if (!completed) {
      await _scheduleNotification(insertedId, title, dueDate, priority);
    }
  }

  Future<void> updateTask(
    int id,
    String title,
    String description,
    DateTime dueDate,
    bool completed,
    Priority priority, {
    String? recurrenceRule,
  }) async {
    if (title.isEmpty) throw Exception('Title cannot be empty');

    final repo = ref.read(taskRepositoryProvider);
    final task = TaskItem(
      title: title,
      description: description,
      dueDate: dueDate,
      completed: completed,
      priority: priority,
      recurrenceRule: recurrenceRule,
    )..id = id;
    await repo.updateTask(task);

    await NotificationService.instance.cancelTaskReminder(id);
    if (!completed) {
      await _scheduleNotification(id, title, dueDate, priority);
    }
  }

  Future<void> deleteTask(int id) async {
    final repo = ref.read(taskRepositoryProvider);
    await repo.deleteTask(id);
    await NotificationService.instance.cancelTaskReminder(id);
  }

  Future<void> toggleTask(TaskItem task) async {
    final repo = ref.read(taskRepositoryProvider);
    final nowCompleting = !task.completed;

    if (nowCompleting && task.isRecurring) {
      // Mark current instance done and immediately create the next recurrence
      final completedTask = TaskItem(
        title: task.title,
        description: task.description,
        dueDate: task.dueDate,
        completed: true,
        priority: task.priority,
        recurrenceRule: task.recurrenceRule,
        lastCompletedAt: DateTime.now(),
      )..id = task.id;
      await repo.updateTask(completedTask);
      await NotificationService.instance.cancelTaskReminder(task.id!);

      // Create next occurrence
      final nextTask = TaskItem(
        title: task.title,
        description: task.description,
        dueDate: task.nextDueDate(),
        completed: false,
        priority: task.priority,
        recurrenceRule: task.recurrenceRule,
      );
      final newId = await repo.insertTask(nextTask);
      await _scheduleNotification(
        newId,
        nextTask.title,
        nextTask.dueDate,
        nextTask.priority,
      );
    } else {
      final updatedTask = TaskItem(
        title: task.title,
        description: task.description,
        dueDate: task.dueDate,
        completed: nowCompleting,
        priority: task.priority,
        recurrenceRule: task.recurrenceRule,
      )..id = task.id;
      await repo.updateTask(updatedTask);

      if (nowCompleting) {
        await NotificationService.instance.cancelTaskReminder(task.id!);
      } else {
        await _scheduleNotification(
          task.id!,
          task.title,
          task.dueDate,
          task.priority,
        );
      }
    }
  }

  Future<void> _scheduleNotification(
    int taskId,
    String title,
    DateTime dueDate,
    Priority priority,
  ) async {
    final offset = _reminderOffset(priority);
    final reminderTime = dueDate.subtract(offset);
    if (reminderTime.isAfter(DateTime.now())) {
      final body = 'Due in ${_offsetLabel(priority)}';
      await NotificationService.instance.scheduleTaskReminder(
        taskId,
        'Task: $title',
        body,
        reminderTime,
      );
    }
  }

  String _offsetLabel(Priority priority) {
    switch (priority) {
      case Priority.critical:
        return '1 hour';
      case Priority.high:
        return '30 minutes';
      case Priority.medium:
        return '15 minutes';
      case Priority.low:
        return '5 minutes';
    }
  }
}
