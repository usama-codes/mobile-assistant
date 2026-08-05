import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
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
  setUpAll(() async {
    await loadAppFonts();
  });

  testGoldens('TasksScreen should look correct', (tester) async {
    final task1 = TaskItem(
      title: 'Buy Groceries',
      description: 'Milk, Bread, Cheese',
      dueDate: DateTime(2025),
      completed: false,
      priority: Priority.high,
    )..id = 1;

    final task2 = TaskItem(
      title: 'Call Doctor',
      description: 'Schedule annual checkup',
      dueDate: DateTime(2025, 1, 2),
      completed: false,
      priority: Priority.medium,
    )..id = 2;

    final builder = DeviceBuilder()
      ..overrideDevicesForAllScenarios(devices: [
        Device.phone,
        Device.iphone11,
      ])
      ..addScenario(
        widget: ProviderScope(
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
        name: 'default_tasks_list',
      );

    await tester.pumpDeviceBuilder(builder);

    // Provide a small delay to ensure rendering completes
    await tester.pumpAndSettle();

    await screenMatchesGolden(tester, 'tasks_screen_golden');
  });
}
