class AgentAction {
  final String tool;
  final String action;
  final Map<String, dynamic> parameters;
  final String? reply;

  AgentAction({
    required this.tool,
    required this.action,
    required this.parameters,
    this.reply,
  });

  factory AgentAction.fromJson(Map<String, dynamic> json) {
    return AgentAction(
      tool: json['tool'] as String? ?? 'core',
      action: json['action'] as String? ?? 'other',
      parameters: json['parameters'] != null ? Map<String, dynamic>.from(json['parameters']) : {},
      reply: json['reply'] as String?,
    );
  }
}
