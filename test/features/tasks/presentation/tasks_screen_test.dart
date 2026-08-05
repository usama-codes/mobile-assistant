import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_assistant/features/tasks/presentation/tasks_provider.dart';
import 'package:mobile_assistant/features/tasks/presentation/tasks_screen.dart';
import 'package:mobile_assistant/l10n/app_localizations.dart';
import 'package:mobile_assistant/shared/models/priority.dart';
import 'package:mobile_assistant/shared/models/task_item.dart';

class MockTasksNotifier extends TasksNotifier {
  MockTasksNotifier(this.tasks);
  final List<TaskItem> tasks;

  @override
  Stream<List<TaskItem>> build() => Stream.value(tasks);
}

void main() {
  group('TasksScreen Widget Tests', () {
    testWidgets('renders empty state when no tasks exist', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [tasksProvider.overrideWith(() => MockTasksNotifier([]))],
          child: const MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: [Locale('en', '')],
            home: TasksScreen(),
          ),
        ),
      );

      // Need to wait for AsyncValue to yield data
      await tester.pumpAndSettle();

      expect(find.text('No tasks yet'), findsOneWidget);
    });

    testWidgets('renders a list of tasks', (tester) async {
      final task1 = TaskItem(
        title: 'Mock Task 1',
        description: 'Description',
        dueDate: DateTime.now().add(const Duration(days: 1)),
        completed: false,
        priority: Priority.high,
      )..id = 1;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tasksProvider.overrideWith(() => MockTasksNotifier([task1])),
          ],
          child: const MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: [Locale('en', '')],
            home: TasksScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Mock Task 1'), findsOneWidget);
      expect(find.text('ACTIVE TASKS'), findsOneWidget);
    });
  });
}
