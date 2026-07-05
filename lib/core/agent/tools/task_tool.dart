import 'package:mobile_assistant/core/agent/agent_tool.dart';
import 'package:mobile_assistant/core/db/app_database.dart';
import 'package:mobile_assistant/shared/models/task_item.dart';
import 'package:mobile_assistant/shared/models/priority.dart';

class TaskTool implements AgentTool {
  @override
  String get name => 'task_tool';

  @override
  String get description => 'Perform CRUD operations on tasks and query tasks (overdue, workload).';

  @override
  Future<String> execute(String action, Map<String, dynamic> parameters) async {
    final db = await AppDatabase.instance.database;

    switch (action) {
      case 'create_task':
        final title = parameters['title'];
        if (title == null || title.toString().trim().isEmpty) {
          throw Exception("Task title is required.");
        }
        
        final description = parameters['description'] ?? '';
        final dueDateStr = parameters['dueDate'];
        final priorityStr = parameters['priority'];

        DateTime dueDate = DateTime.now().add(const Duration(hours: 2));
        if (dueDateStr != null) {
          final parsedDate = DateTime.tryParse(dueDateStr);
          if (parsedDate != null) dueDate = parsedDate;
        }

        Priority priority = Priority.medium;
        if (priorityStr != null) {
          final p = priorityStr.toString().toLowerCase();
          if (p == 'high') priority = Priority.high;
          if (p == 'low') priority = Priority.low;
        }

        final newTask = TaskItem(
          title: title,
          description: description,
          dueDate: dueDate,
          completed: false,
          priority: priority,
        );

        await db.insert('tasks', newTask.toMap());
        return "Created task: '$title'";

      case 'edit_task':
        final id = parameters['id'];
        if (id == null) {
          throw Exception("Could not identify which task to edit. Task ID is required.");
        }

        final tasksResult = await db.query('tasks', where: 'id = ?', whereArgs: [id]);
        if (tasksResult.isEmpty) {
          throw Exception("Task with ID $id not found.");
        }

        final existingTaskMap = tasksResult.first;
        final updatedTask = Map<String, dynamic>.from(existingTaskMap);

        if (parameters.containsKey('title')) updatedTask['title'] = parameters['title'];
        if (parameters.containsKey('description')) updatedTask['description'] = parameters['description'];
        if (parameters.containsKey('dueDate')) {
          final parsedDate = DateTime.tryParse(parameters['dueDate'].toString());
          if (parsedDate != null) updatedTask['dueDate'] = parsedDate.toIso8601String();
        }
        if (parameters.containsKey('priority')) {
          final p = parameters['priority'].toString().toLowerCase();
          updatedTask['priority'] = (p == 'low' ? Priority.low : (p == 'high' ? Priority.high : Priority.medium)).index;
        }

        await db.update('tasks', updatedTask, where: 'id = ?', whereArgs: [id]);
        return "Updated task: '${updatedTask['title']}'";

      case 'delete_task':
        final id = parameters['id'];
        if (id == null) {
          throw Exception("Could not identify which task to delete. Task ID is required.");
        }
        await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
        return "Deleted task successfully.";
        
      case 'get_overdue_tasks':
        final now = DateTime.now().toIso8601String();
        final tasks = await db.query('tasks', where: 'dueDate < ? AND completed = 0', whereArgs: [now]);
        if (tasks.isEmpty) return "No overdue tasks.";
        return "Found ${tasks.length} overdue tasks: ${tasks.map((t) => t['title']).join(', ')}";

      case 'get_workload':
        final tasks = await db.query('tasks', where: 'completed = 0');
        if (tasks.isEmpty) return "You have no pending tasks.";
        return "You have ${tasks.length} pending tasks.";

      default:
        throw Exception("Unknown action '$action' for TaskTool.");
    }
  }
}
