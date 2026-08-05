class ChatSession {

  ChatSession({
    required this.title, required this.createdAt, this.id,
  });

  factory ChatSession.fromMap(Map<String, dynamic> map) {
    return ChatSession(
      id: map['id'] as int?,
      title: map['title'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
  int? id;
  String title;
  DateTime createdAt;

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
