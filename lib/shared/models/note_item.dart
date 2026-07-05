class NoteItem {
  int? id;
  String title;
  String content;
  DateTime createdAt;

  NoteItem({
    required this.title,
    required this.content,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory NoteItem.fromMap(Map<String, dynamic> map) {
    return NoteItem(
      title: map['title'] as String,
      content: map['content'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
    )..id = map['id'] as int?;
  }
}
