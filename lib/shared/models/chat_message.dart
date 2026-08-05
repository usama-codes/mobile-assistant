class ChatMessage {
  ChatMessage({
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.sessionId,
    this.attachmentPath,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      sessionId: map['sessionId'] as int?,
      content: map['content'] as String,
      isUser: map['isUser'] == 1,
      timestamp: DateTime.parse(map['timestamp'] as String),
      attachmentPath: map['attachmentPath'] as String?,
    )..id = map['id'] as int?;
  }
  int? id;
  int? sessionId;
  String content;
  bool isUser;
  DateTime timestamp;
  String? attachmentPath;

  Map<String, dynamic> toMap() {
    return {
      if (sessionId != null) 'sessionId': sessionId,
      'content': content,
      'isUser': isUser ? 1 : 0,
      'timestamp': timestamp.toIso8601String(),
      if (attachmentPath != null) 'attachmentPath': attachmentPath,
    };
  }
}
