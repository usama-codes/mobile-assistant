class ExpenseItem {
  ExpenseItem({
    this.id,
    required this.amount,
    required this.vendor,
    required this.date,
    required this.category,
    this.rawText = '',
    this.createdAt,
  });

  final int? id;
  final double amount;
  final String vendor;
  final String date;
  final String category;
  final String rawText;
  final DateTime? createdAt;

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'amount': amount,
      'vendor': vendor,
      'date': date,
      'category': category,
      'rawText': rawText,
      'createdAt': (createdAt ?? DateTime.now()).toIso8601String(),
    };
  }

  factory ExpenseItem.fromMap(Map<String, dynamic> map) {
    return ExpenseItem(
      id: map['id'] as int?,
      amount: (map['amount'] as num).toDouble(),
      vendor: map['vendor'] as String,
      date: map['date'] as String,
      category: map['category'] as String,
      rawText: map['rawText'] as String? ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : null,
    );
  }
}
