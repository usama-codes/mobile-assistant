// ignore_for_file: unused_local_variable

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_assistant/features/tasks/data/task_repository.dart';
import 'package:mobile_assistant/features/tasks/presentation/tasks_provider.dart';
import 'package:mobile_assistant/shared/models/priority.dart';
import 'package:mobile_assistant/shared/models/task_item.dart';
import 'package:mocktail/mocktail.dart';

class MockTaskRepository extends Mock implements TaskRepository {}

void main() {
  group('TasksNotifier Logic Tests', () {
    late MockTaskRepository mockRepo;
    late ProviderContainer container;

    setUp(() {
      mockRepo = MockTaskRepository();
      container = ProviderContainer(
        overrides: [taskRepositoryProvider.overrideWithValue(mockRepo)],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('build() filters out completed tasks and sorts correctly', () async {
      final now = DateTime.now();

      final task1 = TaskItem(
        title: 'Task 1 (Completed)',
        description: '',
        dueDate: now.add(const Duration(days: 1)),
        completed: true,
        priority: Priority.high,
      )..id = 1;

      final task2 = TaskItem(
        title: 'Task 2 (High, Tomorrow)',
        description: '',
        dueDate: now.add(const Duration(days: 1)),
        completed: false,
        priority: Priority.high,
      )..id = 2;

      final task3 = TaskItem(
        title: 'Task 3 (Critical, Tomorrow)',
        description: '',
        dueDate: now.add(const Duration(days: 1)),
        completed: false,
        priority: Priority.critical,
      )..id = 3;

      final task4 = TaskItem(
        title: 'Task 4 (Low, Today)',
        description: '',
        dueDate: now,
        completed: false,
        priority: Priority.low,
      )..id = 4;

      when(
        () => mockRepo.watchTasks(),
      ).thenAnswer((_) => Stream.value([task1, task2, task3, task4]));

      final subscription = container.listen(
        tasksProvider,
        (_, _) {},
        fireImmediately: true,
      );

      // Read the current state of tasksProvider (which is an AsyncValue)
      final asyncValue = container.read(tasksProvider);

      // We expect the state to eventually be data
      final tasks = await container.read(tasksProvider.future);

      expect(tasks.length, 3, reason: 'Completed task should be filtered out');

      // Expected order:
      // 1. Task 4 (earliest due date: Today)
      // 2. Task 3 (Tomorrow, Critical priority)
      // 3. Task 2 (Tomorrow, High priority)
      expect(tasks[0].id, 4);
      expect(tasks[1].id, 3);
      expect(tasks[2].id, 2);

      subscription.close();
    });
  });
}
