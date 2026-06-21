import 'package:flutter/scheduler.dart';

class TaskItem {
  String id;
  String title;
  String description;
  DateTime? dueDate;
  bool completed;
  Priority priority;

  TaskItem({
    required this.id,
    required this.title,
    required this.description,
    required this.completed,
    required this.priority,
  });
}
