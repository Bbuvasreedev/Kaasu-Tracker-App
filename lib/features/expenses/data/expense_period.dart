import 'package:kaasutracker/features/expenses/data/expense.dart';
import 'package:kaasutracker/features/finance/data/finance_models.dart';

bool expenseIsInPeriod(Expense expense, FinancePeriod period) {
  final date = expense.expenseDate.toLocal();
  final start = period.firstDay;
  final nextMonth = DateTime(period.year, period.month + 1);
  return !date.isBefore(start) && date.isBefore(nextMonth);
}
