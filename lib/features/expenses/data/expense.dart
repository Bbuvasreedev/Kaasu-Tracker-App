import 'package:kaasutracker/features/finance/data/finance_models.dart';

class Expense {
  const Expense({
    required this.id,
    required this.amount,
    required this.category,
    required this.description,
    required this.expenseDate,
    this.isConfirmed = true,
    this.refundedAmount = 0,
  });

  final String id;
  final double amount;
  final String category;
  final String description;
  final DateTime expenseDate;
  final bool isConfirmed;
  final double refundedAmount;

  int get amountMinorUnits =>
      parseMinorUnits(amount.toString(), field: 'amount');

  int get refundedAmountMinorUnits =>
      parseMinorUnits(refundedAmount.toString(), field: 'refundedAmount');

  int get eligibleAmountMinorUnits =>
      (amountMinorUnits - refundedAmountMinorUnits).clamp(0, amountMinorUnits);

  factory Expense.fromJson(Map<String, dynamic> json) {
    final amountValue = json['amount'];
    final refundedValue = json['refundedAmount'] ?? 0;
    final dateValue = json['expenseDate'];

    if (amountValue is! num && amountValue is! String) {
      throw const FormatException('Expense amount must be a number.');
    }
    if (refundedValue is! num && refundedValue is! String) {
      throw const FormatException('Refunded amount must be a number.');
    }
    if (dateValue is! String) {
      throw const FormatException('Expense date must be an ISO-8601 string.');
    }
    if (json['isConfirmed'] != null && json['isConfirmed'] is! bool) {
      throw const FormatException('Expense confirmation flag must be boolean.');
    }

    return Expense(
      id: json['id'].toString(),
      amount: parseMinorUnits(amountValue, field: 'amount') / 100,
      category:
          json['category'] is String &&
              (json['category'] as String).trim().isNotEmpty
          ? (json['category'] as String).trim()
          : 'Uncategorized',
      description: json['description'] is String
          ? json['description'] as String
          : '',
      expenseDate: DateTime.parse(dateValue),
      isConfirmed: json['isConfirmed'] as bool? ?? true,
      refundedAmount:
          parseMinorUnits(refundedValue, field: 'refundedAmount') / 100,
    );
  }
}
