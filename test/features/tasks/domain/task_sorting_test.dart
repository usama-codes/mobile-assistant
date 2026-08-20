import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_assistant/shared/models/priority.dart';
import 'package:mobile_assistant/shared/models/task_item.dart';

void main() {
  group('TaskItem Sorting Logic', () {
    test('should sort tasks by earliest deadline first', () {
      final now = DateTime.now();
      final tasks = [
        TaskItem(
          title: 'Task C',
          description: 'Due in 3 days',
          dueDate: now.add(const Duration(days: 3)),
          completed: false,
          priority: Priority.medium,
        ),
        TaskItem(
          title: 'Task A',
          description: 'Due in 1 day',
          dueDate: now.add(const Duration(days: 1)),
          completed: false,
          priority: Priority.medium,
        ),
        TaskItem(
          title: 'Task B',
          description: 'Due in 2 days',
          dueDate: now.add(const Duration(days: 2)),
          completed: false,
          priority: Priority.medium,
        ),
      ];

      tasks.sort((a, b) {
        final dateCompare = a.dueDate.compareTo(b.dueDate);
        if (dateCompare != 0) return dateCompare;
        return b.priority.index.compareTo(a.priority.index);
      });

      expect(tasks[0].title, 'Task A');
      expect(tasks[1].title, 'Task B');
      expect(tasks[2].title, 'Task C');
    });

    test('should sort by priority when deadlines are equal', () {
      final now = DateTime.now();
      final sameDeadline = now.add(const Duration(days: 1));

      final tasks = [
        TaskItem(
          title: 'Low Priority',
          description: 'Test',
          dueDate: sameDeadline,
          completed: false,
          priority: Priority.low,
        ),
        TaskItem(
          title: 'Critical Priority',
          description: 'Test',
          dueDate: sameDeadline,
          completed: false,
          priority: Priority.critical,
        ),
        TaskItem(
          title: 'High Priority',
          description: 'Test',
          dueDate: sameDeadline,
          completed: false,
          priority: Priority.high,
        ),
      ];

      tasks.sort((a, b) {
        final dateCompare = a.dueDate.compareTo(b.dueDate);
        if (dateCompare != 0) return dateCompare;
        return b.priority.index.compareTo(a.priority.index);
      });

      expect(tasks[0].title, 'Critical Priority');
      expect(tasks[1].title, 'High Priority');
      expect(tasks[2].title, 'Low Priority');
    });

    test('should compute next due date for daily recurring task', () {
      final now = DateTime.now();
      final task = TaskItem(
        title: 'Daily Task',
        description: 'Test',
        dueDate: now,
        completed: false,
        priority: Priority.medium,
        recurrenceRule: 'FREQ=DAILY',
      );

      final nextDate = task.nextDueDate();
      expect(nextDate.difference(now).inDays, 1);
    });

    test('should compute next due date for weekly recurring task', () {
      final now = DateTime.now();
      final task = TaskItem(
        title: 'Weekly Task',
        description: 'Test',
        dueDate: now,
        completed: false,
        priority: Priority.medium,
        recurrenceRule: 'FREQ=WEEKLY',
      );

      final nextDate = task.nextDueDate();
      expect(nextDate.difference(now).inDays, 7);
    });

    test('should compute next due date for monthly recurring task', () {
      final task = TaskItem(
        title: 'Monthly Task',
        description: 'Test',
        dueDate: DateTime(2026, 1, 15),
        completed: false,
        priority: Priority.medium,
        recurrenceRule: 'FREQ=MONTHLY',
      );

      final nextDate = task.nextDueDate();
      expect(nextDate.year, 2026);
      expect(nextDate.month, 2);
      expect(nextDate.day, 15);
    });

    test('should identify recurring tasks correctly', () {
      final recurringTask = TaskItem(
        title: 'Recurring',
        description: 'Test',
        dueDate: DateTime.now(),
        completed: false,
        priority: Priority.medium,
        recurrenceRule: 'FREQ=DAILY',
      );

      final oneTimeTask = TaskItem(
        title: 'One Time',
        description: 'Test',
        dueDate: DateTime.now(),
        completed: false,
        priority: Priority.medium,
      );

      expect(recurringTask.isRecurring, true);
      expect(oneTimeTask.isRecurring, false);
    });

    test('should provide correct recurrence labels', () {
      final dailyTask = TaskItem(
        title: 'Daily',
        description: 'Test',
        dueDate: DateTime.now(),
        completed: false,
        priority: Priority.medium,
        recurrenceRule: 'FREQ=DAILY',
      );

      final weeklyTask = TaskItem(
        title: 'Weekly',
        description: 'Test',
        dueDate: DateTime.now(),
        completed: false,
        priority: Priority.medium,
        recurrenceRule: 'FREQ=WEEKLY',
      );

      final monthlyTask = TaskItem(
        title: 'Monthly',
        description: 'Test',
        dueDate: DateTime.now(),
        completed: false,
        priority: Priority.medium,
        recurrenceRule: 'FREQ=MONTHLY',
      );

      expect(dailyTask.recurrenceLabel, 'Daily');
      expect(weeklyTask.recurrenceLabel, 'Weekly');
      expect(monthlyTask.recurrenceLabel, 'Monthly');
    });
  });
}
