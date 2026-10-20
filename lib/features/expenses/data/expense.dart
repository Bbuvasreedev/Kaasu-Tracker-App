class Expense {
  const Expense({
    required this.id,
    required this.amount,
    required this.category,
    required this.description,
    required this.expenseDate,
  });

  final String id;
  final double amount;
  final String category;
  final String description;
  final DateTime expenseDate;

  factory Expense.fromJson(Map<String, dynamic> json) {
    final amountValue = json['amount'];
    final dateValue = json['expenseDate'];

    if (amountValue is! num && amountValue is! String) {
      throw const FormatException('Expense amount must be a number.');
    }
    if (dateValue is! String) {
      throw const FormatException('Expense date must be an ISO-8601 string.');
    }

    return Expense(
      id: json['id'].toString(),
      amount: amountValue is num
          ? amountValue.toDouble()
          : double.parse(amountValue),
      category:
          json['category'] is String &&
              (json['category'] as String).trim().isNotEmpty
          ? (json['category'] as String).trim()
          : 'Uncategorized',
      description: json['description'] as String,
      expenseDate: DateTime.parse(dateValue),
    );
  }
}
