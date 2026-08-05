import 'package:mobile_assistant/shared/models/priority.dart';

class TaskItem {

  TaskItem({
    required this.title,
    required this.description,
    required this.dueDate,
    required this.completed,
    required this.priority,
    this.recurrenceRule,
    this.lastCompletedAt,
  });

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
      recurrenceRule: map['recurrenceRule'] as String?,
      lastCompletedAt: map['lastCompletedAt'] != null
          ? DateTime.tryParse(map['lastCompletedAt'] as String)
          : null,
    )..id = map['id'] as int?;
  }
  int? id;
  String title;
  String description;
  DateTime dueDate;
  bool completed;
  Priority priority;
  String? recurrenceRule;   // RRULE string: FREQ=DAILY, FREQ=WEEKLY, FREQ=MONTHLY
  DateTime? lastCompletedAt;

  bool get isRecurring => recurrenceRule != null && recurrenceRule!.isNotEmpty;

  String get recurrenceLabel {
    if (recurrenceRule == null) return '';
    if (recurrenceRule!.contains('DAILY')) return 'Daily';
    if (recurrenceRule!.contains('WEEKLY')) return 'Weekly';
    if (recurrenceRule!.contains('MONTHLY')) return 'Monthly';
    return 'Recurring';
  }

  /// Compute the next due date for a recurring task after completion.
  DateTime nextDueDate() {
    if (recurrenceRule == null) return dueDate;
    if (recurrenceRule!.contains('DAILY')) return dueDate.add(const Duration(days: 1));
    if (recurrenceRule!.contains('WEEKLY')) return dueDate.add(const Duration(days: 7));
    if (recurrenceRule!.contains('MONTHLY')) {
      return DateTime(dueDate.year, dueDate.month + 1, dueDate.day,
          dueDate.hour, dueDate.minute);
    }
    return dueDate.add(const Duration(days: 1));
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'dueDate': dueDate.toIso8601String(),
      'completed': completed ? 1 : 0,
      'priority': priority.name,
      'recurrenceRule': recurrenceRule,
      'lastCompletedAt': lastCompletedAt?.toIso8601String(),
    };
  }
}
