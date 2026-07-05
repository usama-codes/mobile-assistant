import 'package:mobile_assistant/shared/models/priority.dart';

class TaskItem {
  int? id;
  String title;
  String description;
  DateTime dueDate;
  bool completed;
  Priority priority;

  TaskItem({
    required this.title,
    required this.description,
    required this.dueDate,
    required this.completed,
    required this.priority,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'dueDate': dueDate.toIso8601String(),
      'completed': completed ? 1 : 0,
      'priority': priority.name,
    };
  }

  factory TaskItem.fromMap(Map<String, dynamic> map) {
    return TaskItem(
      title: map['title'] as String,
      description: map['description'] as String,
      dueDate: DateTime.parse(map['dueDate'] as String),
      completed: map['completed'] == 1,
      priority: Priority.values.firstWhere(
        (e) => e.name == map['priority'],
        orElse: () => Priority.medium,
      ),
    )..id = map['id'] as int?;
  }
}
