import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:mobile_assistant/core/agent/agent_tool.dart';
import 'package:mobile_assistant/features/tasks/data/task_repository.dart';
import 'package:mobile_assistant/shared/models/priority.dart';
import 'package:mobile_assistant/shared/models/task_item.dart';

class TaskTool implements AgentTool {
  TaskTool(this._repo);
  final TaskRepository _repo;

  @override
  List<FunctionDeclaration> get declarations => [
    FunctionDeclaration(
      'create_task',
      'Create a new task for the user',
      Schema(
        SchemaType.object,
        properties: {
          'title': Schema(SchemaType.string, description: 'Task title'),
          'description': Schema(
            SchemaType.string,
            description: 'Optional details',
          ),
          'dueDate': Schema(
            SchemaType.string,
            description: 'ISO8601 datetime string',
          ),
          'priority': Schema(
            SchemaType.string,
            description: 'low, medium, high, or critical',
          ),
          'recurrenceRule': Schema(
            SchemaType.string,
            description:
                'RRULE string e.g. FREQ=DAILY, FREQ=WEEKLY, FREQ=MONTHLY',
          ),
        },
        requiredProperties: ['title'],
      ),
    ),
    FunctionDeclaration(
      'edit_task',
      'Edit an existing task by id',
      Schema(
        SchemaType.object,
        properties: {
          'id': Schema(SchemaType.integer, description: 'Task id'),
          'title': Schema(SchemaType.string),
          'description': Schema(SchemaType.string),
          'dueDate': Schema(
            SchemaType.string,
            description: 'ISO8601 datetime string',
          ),
          'priority': Schema(
            SchemaType.string,
            description: 'low, medium, high, or critical',
          ),
        },
        requiredProperties: ['id'],
      ),
    ),
    FunctionDeclaration(
      'complete_task',
      'Mark a task as completed',
      Schema(
        SchemaType.object,
        properties: {'id': Schema(SchemaType.integer)},
        requiredProperties: ['id'],
      ),
    ),
    FunctionDeclaration(
      'delete_task',
      'Permanently delete a task',
      Schema(
        SchemaType.object,
        properties: {'id': Schema(SchemaType.integer)},
        requiredProperties: ['id'],
      ),
    ),
    FunctionDeclaration(
      'get_overdue_tasks',
      'List all overdue incomplete tasks',
      Schema(SchemaType.object, properties: {}),
    ),
    FunctionDeclaration(
      'get_workload',
      'Get total number of pending tasks',
      Schema(SchemaType.object, properties: {}),
    ),
  ];

  @override
  bool canHandle(String functionName) {
    const handled = {
      'create_task',
      'edit_task',
      'complete_task',
      'delete_task',
      'get_overdue_tasks',
      'get_workload',
    };
    return handled.contains(functionName);
  }

  @override
  String get name => 'task_tool';

  @override
  String get description =>
      'Perform CRUD operations on tasks and query tasks (overdue, workload).';

  @override
  Future<String> execute(String action, Map<String, dynamic> parameters) async {
    switch (action) {
      case 'create_task':
        final title = parameters['title']?.toString().trim();
        if (title == null || title.isEmpty)
          throw Exception('Task title is required.');

        var dueDate = DateTime.now().add(const Duration(hours: 2));
        final dueDateStr = parameters['dueDate'];
        if (dueDateStr != null) {
          final parsed = DateTime.tryParse(dueDateStr.toString());
          if (parsed != null) dueDate = parsed;
        }

        final priority = _parsePriority(parameters['priority']);
        final newTask = TaskItem(
          title: title,
          description: parameters['description']?.toString() ?? '',
          dueDate: dueDate,
          completed: false,
          priority: priority,
          recurrenceRule: parameters['recurrenceRule']?.toString(),
        );
        await _repo.insertTask(newTask);
        return "Created task: '$title'";

      case 'edit_task':
        final id = parameters['id'];
        if (id == null) throw Exception('Task id is required.');
        final all = await _repo.getAllTasks();
        final existing = all.firstWhere(
          (t) => t.id == id,
          orElse: () => throw Exception('Task $id not found.'),
        );
        final updated = TaskItem(
          title: parameters['title']?.toString() ?? existing.title,
          description:
              parameters['description']?.toString() ?? existing.description,
          dueDate: parameters['dueDate'] != null
              ? (DateTime.tryParse(parameters['dueDate'].toString()) ??
                    existing.dueDate)
              : existing.dueDate,
          completed: existing.completed,
          priority: parameters['priority'] != null
              ? _parsePriority(parameters['priority'])
              : existing.priority,
          recurrenceRule: existing.recurrenceRule,
        )..id = existing.id;
        await _repo.updateTask(updated);
        return "Updated task: '${updated.title}'";

      case 'complete_task':
        final id = parameters['id'];
        if (id == null) throw Exception('Task id is required.');
        final all = await _repo.getAllTasks();
        final existing = all.firstWhere(
          (t) => t.id == id,
          orElse: () => throw Exception('Task $id not found.'),
        );
        final completed = TaskItem(
          title: existing.title,
          description: existing.description,
          dueDate: existing.dueDate,
          completed: true,
          priority: existing.priority,
          recurrenceRule: existing.recurrenceRule,
        )..id = existing.id;
        await _repo.updateTask(completed);
        return "Marked task '${existing.title}' as complete.";

      case 'delete_task':
        final id = parameters['id'];
        if (id == null) throw Exception('Task id is required.');
        await _repo.deleteTask(id as int);
        return 'Task deleted.';

      case 'get_overdue_tasks':
        final tasks = await _repo.getAllTasks();
        final now = DateTime.now();
        final overdue = tasks
            .where((t) => !t.completed && t.dueDate.isBefore(now))
            .toList();
        if (overdue.isEmpty) return 'No overdue tasks.';
        return 'Overdue (${overdue.length}): ${overdue.map((t) => "'${t.title}' (id:${t.id})").join(', ')}';

      case 'get_workload':
        final tasks = await _repo.getAllTasks();
        final pending = tasks.where((t) => !t.completed).length;
        return pending == 0
            ? 'No pending tasks.'
            : 'You have $pending pending task(s).';

      default:
        throw Exception("Unknown action '$action' for TaskTool.");
    }
  }

  Priority _parsePriority(dynamic raw) {
    if (raw == null) return Priority.medium;
    switch (raw.toString().toLowerCase()) {
      case 'low':
        return Priority.low;
      case 'high':
        return Priority.high;
      case 'critical':
        return Priority.critical;
      default:
        return Priority.medium;
    }
  }
}
