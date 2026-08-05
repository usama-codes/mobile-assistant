// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Mobile Assistant';

  @override
  String get chatTab => 'Chat';

  @override
  String get tasksTab => 'Tasks';

  @override
  String get documentsTab => 'Docs';

  @override
  String get settingsTab => 'Settings';

  @override
  String get newChat => 'New Chat';

  @override
  String get typeMessage => 'Type a message...';

  @override
  String get addTask => 'Add Task';

  @override
  String get taskTitle => 'Task Title';

  @override
  String get addDocument => 'Add Document';

  @override
  String get uploadPdf => 'Upload PDF';

  @override
  String get settings => 'Settings';

  @override
  String get preferences => 'Preferences';

  @override
  String get privacySecurity => 'Privacy & Security';

  @override
  String get inferenceModel => 'Inference Model (Gemma)';

  @override
  String get appLock => 'App Lock (Biometrics)';

  @override
  String get description => 'Description';

  @override
  String get noDescription => 'No description';

  @override
  String get due => 'Due';

  @override
  String get createNewTask => 'Create New Task';

  @override
  String get taskName => 'Task Name';

  @override
  String get descriptionOptional => 'Description (Optional)';

  @override
  String get dueDate => 'Due Date';

  @override
  String get priority => 'Priority';

  @override
  String get saveTask => 'Save Task';

  @override
  String get editTask => 'Edit Task';

  @override
  String get updateTask => 'Update Task';

  @override
  String get active => 'active';

  @override
  String get completed => 'completed';

  @override
  String get addNewTask => 'Add a new task...';

  @override
  String get noTasksYet => 'No tasks yet';

  @override
  String get noTasksYetSubtitle =>
      'Add a task above or ask the assistant to create one for you.';

  @override
  String get activeTasks => 'Active Tasks';

  @override
  String get completedTasks => 'Completed';
}
