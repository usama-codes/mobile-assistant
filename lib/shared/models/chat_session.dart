class ChatSession {
  int? id;
  String title;
  DateTime createdAt;

  ChatSession({
    this.id,
    required this.title,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ChatSession.fromMap(Map<String, dynamic> map) {
    return ChatSession(
      id: map['id'],
      title: map['title'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
