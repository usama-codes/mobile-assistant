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

Widget _buildApp(List<TaskItem> tasks) {
  return ProviderScope(
    overrides: [tasksProvider.overrideWith(() => MockTasksNotifier(tasks))],
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
  );
}

void main() {
  group('TasksScreen Widget Tests', () {
    testWidgets('renders empty state when no tasks exist', (tester) async {
      await tester.pumpWidget(_buildApp([]));
      await tester.pumpAndSettle();

      // Empty state shows 'Nothing due' (not 'No tasks yet')
      expect(find.text('Nothing due'), findsOneWidget);
    });

    testWidgets('renders a list of tasks', (tester) async {
      final task1 = TaskItem(
        title: 'Mock Task 1',
        description: 'Description',
        // Use a future date to land in 'Later' bucket
        dueDate: DateTime.now().add(const Duration(days: 30)),
        completed: false,
        priority: Priority.high,
      )..id = 1;

      await tester.pumpWidget(_buildApp([task1]));
      await tester.pumpAndSettle();

      expect(find.text('Mock Task 1'), findsOneWidget);
      // Tasks are grouped under 'Today', 'This Week', or 'Later'
      expect(find.text('Later'), findsOneWidget);
    });
  });
}
