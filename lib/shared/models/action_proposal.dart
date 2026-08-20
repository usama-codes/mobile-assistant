/// A structured action proposal extracted from the user's message + RAG context.
/// This is the core data model for the extraction → confirm → write pipeline.
class ActionProposal {
  ActionProposal({
    required this.action,
    required this.title,
    this.startDate,
    this.endDate,
    this.description,
    this.location,
    this.sourceDocTitle,
    this.sourceDocId,
    this.confidence = 0.5,
    this.rawParams = const {},
  });

  /// The action type: 'create_calendar_event', 'create_task', 'log_expense', etc.
  final String action;

  /// Human-readable title for the action.
  final String title;

  /// Start date/time (for calendar events).
  DateTime? startDate;

  /// End date/time (for calendar events).
  DateTime? endDate;

  /// Optional description.
  String? description;

  /// Optional location (for calendar events).
  String? location;

  /// Title of the source document (if RAG-sourced).
  final String? sourceDocTitle;

  /// ID of the source document (if RAG-sourced).
  final int? sourceDocId;

  /// Extraction confidence score (0.0–1.0).
  final double confidence;

  /// Extra parameters passed through to the tool (e.g., amount for expenses).
  final Map<String, dynamic> rawParams;

  bool get isCalendarEvent => action == 'create_calendar_event';
  bool get isTask => action == 'create_task';
  bool get isExpense => action == 'log_expense';

  /// Whether the confidence is high enough to proceed without clarification.
  bool get isConfident => confidence >= 0.6;

  /// Map params suitable for CalendarTool.execute('create_calendar_event', params).
  Map<String, dynamic> toCalendarParams() {
    return {
      'title': title,
      if (startDate != null) 'startDate': startDate!.toIso8601String(),
      if (endDate != null) 'endDate': endDate!.toIso8601String(),
      if (description != null) 'description': description,
      if (location != null) 'location': location,
    };
  }

  /// Map params suitable for TaskTool.execute('create_task', params).
  Map<String, dynamic> toTaskParams() {
    return {
      'title': title,
      if (description != null) 'description': description,
      if (startDate != null) 'dueDate': startDate!.toIso8601String(),
      ...rawParams,
    };
  }

  /// Map params suitable for ExpenseTool.execute('log_expense', params).
  Map<String, dynamic> toExpenseParams() {
    return {
      ...rawParams,
      if (startDate != null) 'date': startDate!.toIso8601String(),
    };
  }

  ActionProposal copyWith({
    String? action,
    String? title,
    DateTime? startDate,
    DateTime? endDate,
    String? description,
    String? location,
    String? sourceDocTitle,
    int? sourceDocId,
    double? confidence,
    Map<String, dynamic>? rawParams,
    bool clearSourceDoc = false,
    bool clearStartDate = false,
    bool clearEndDate = false,
    bool clearDescription = false,
    bool clearLocation = false,
  }) {
    return ActionProposal(
      action: action ?? this.action,
      title: title ?? this.title,
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      description: clearDescription ? null : (description ?? this.description),
      location: clearLocation ? null : (location ?? this.location),
      sourceDocTitle: clearSourceDoc ? null : (sourceDocTitle ?? this.sourceDocTitle),
      sourceDocId: clearSourceDoc ? null : (sourceDocId ?? this.sourceDocId),
      confidence: confidence ?? this.confidence,
      rawParams: rawParams ?? this.rawParams,
    );
  }

  @override
  String toString() => 'ActionProposal($action: "$title", confidence: $confidence)';
}
