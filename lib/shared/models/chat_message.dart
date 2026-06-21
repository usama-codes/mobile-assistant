class ChatMessage {
  final String id;
  String content;
  bool isUser;
  DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
  });
}
