import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:mobile_assistant/core/agent/agent_tool.dart';
import 'package:mobile_assistant/core/db/expense_repository.dart';
import 'package:mobile_assistant/shared/models/expense_item.dart';

class ExpenseTool implements AgentTool {
  ExpenseTool(this._repo);
  final ExpenseRepository _repo;

  @override
  String get name => 'expense_tool';

  @override
  String get description => 'Log and query expenses or receipts.';

  @override
  List<FunctionDeclaration> get declarations => [
    FunctionDeclaration(
      'log_expense',
      'Log an expense to the database',
      Schema(SchemaType.object, properties: {
        'amount': Schema(SchemaType.number),
        'vendor': Schema(SchemaType.string),
        'date': Schema(SchemaType.string, description: 'ISO 8601 date'),
        'category': Schema(SchemaType.string),
      }, requiredProperties: ['amount', 'vendor', 'date', 'category']),
    ),
    FunctionDeclaration(
      'get_expenses',
      'Get a list of logged expenses',
      Schema(SchemaType.object, properties: {}),
    ),
  ];

  @override
  bool canHandle(String functionName) =>
      {'log_expense', 'get_expenses'}.contains(functionName);

  @override
  Future<String> execute(String action, Map<String, dynamic> params) async {
    if (action == 'log_expense') {
      final item = ExpenseItem(
        amount: (params['amount'] as num).toDouble(),
        vendor: params['vendor'] as String,
        date: params['date'] as String,
        category: params['category'] as String,
      );
      await _repo.addExpense(item);
      return 'Expense of \$${item.amount} at ${item.vendor} logged successfully.';
    } else if (action == 'get_expenses') {
      final items = await _repo.getAllExpenses();
      if (items.isEmpty) return 'No expenses found.';
      return items.map((e) => '- \${e.amount} at ${e.vendor} on ${e.date} (${e.category})').join('\n');
    }
    return 'Unknown action: $action';
  }
}
