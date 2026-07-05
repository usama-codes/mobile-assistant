class MemoryFact {
  int? id;
  String fact;
  double importance;
  DateTime createdAt;

  MemoryFact({
    required this.fact,
    required this.importance,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'fact': fact,
      'importance': importance,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory MemoryFact.fromMap(Map<String, dynamic> map) {
    return MemoryFact(
      fact: map['fact'] as String,
      importance: (map['importance'] as num).toDouble(),
      createdAt: DateTime.parse(map['createdAt'] as String),
    )..id = map['id'] as int?;
  }
}
