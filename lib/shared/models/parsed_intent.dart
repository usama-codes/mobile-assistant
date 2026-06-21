class ParsedIntent {
  final IntentType intentType;
  final String taskTitle;
  final DateTime? reminderTime;

  ParsedIntent({
    required this.intentType,
    required this.taskTitle,
    required this.reminderTime,
  });
}

class IntentType {
}
