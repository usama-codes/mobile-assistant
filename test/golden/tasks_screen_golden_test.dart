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
  testWidgets('TasksScreen renders tasks list correctly', (tester) async {
    final task1 = TaskItem(
      title: 'Buy Groceries',
      description: 'Milk, Bread, Cheese',
      dueDate: DateTime.now().add(const Duration(days: 30)),
      completed: false,
      priority: Priority.high,
    )..id = 1;

    final task2 = TaskItem(
      title: 'Call Doctor',
      description: 'Schedule annual checkup',
      dueDate: DateTime.now().add(const Duration(days: 31)),
      completed: false,
      priority: Priority.medium,
    )..id = 2;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tasksProvider.overrideWith(() => MockTasksNotifier([task1, task2])),
        ],
        child: const MaterialApp(
          debugShowCheckedModeBanner: false,
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

    expect(find.text('Buy Groceries'), findsOneWidget);
    expect(find.text('Call Doctor'), findsOneWidget);
    expect(find.text('Later'), findsOneWidget);
  });
}
