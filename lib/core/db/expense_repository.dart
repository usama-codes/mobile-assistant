import 'package:mobile_assistant/core/db/app_database.dart';
import 'package:mobile_assistant/shared/models/expense_item.dart';

class ExpenseRepository {
  Future<List<ExpenseItem>> getAllExpenses() async {
    final db = await AppDatabase.instance.database;
    final results = await db.query('expenses', orderBy: 'createdAt DESC');
    return results.map((e) => ExpenseItem.fromMap(e)).toList();
  }

  Future<void> addExpense(ExpenseItem item) async {
    final db = await AppDatabase.instance.database;
    await db.insert('expenses', item.toMap());
  }
}
