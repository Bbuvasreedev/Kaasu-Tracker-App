import 'package:kaasutracker/features/emis/data/emi_model.dart';
import 'package:kaasutracker/features/expenses/data/expense.dart';

double totalExpensesForMonth(List<Expense> expenses, DateTime month) {
  final seenIds = <String>{};
  var total = 0.0;
  for (final expense in expenses) {
    final expenseDate = expense.expenseDate.toLocal();
    if (expenseDate.year != month.year ||
        expenseDate.month != month.month ||
        !expense.amount.isFinite) {
      continue;
    }
    if (expense.id.isNotEmpty &&
        expense.id != 'null' &&
        !seenIds.add(expense.id)) {
      continue;
    }
    total += expense.amount;
  }
  return total.isFinite ? total.clamp(0.0, double.infinity).toDouble() : 0;
}

DateTime? nextScheduledEmiDate(
  List<EmiModel> activeEmis, {
  required DateTime from,
}) {
  final today = DateTime(from.year, from.month, from.day);
  DateTime? nextDate;

  for (final emi in activeEmis) {
    if (!emi.isActive || emi.dueDateDay < 1 || emi.dueDateDay > 31) continue;
    var year = today.year;
    var month = today.month;
    var dueDate = _dueDate(year, month, emi.dueDateDay);
    if (dueDate.isBefore(today)) {
      month++;
      if (month > 12) {
        month = 1;
        year++;
      }
      dueDate = _dueDate(year, month, emi.dueDateDay);
    }
    if (nextDate == null || dueDate.isBefore(nextDate)) nextDate = dueDate;
  }
  return nextDate;
}

DateTime _dueDate(int year, int month, int day) {
  final daysInMonth = DateTime(year, month + 1, 0).day;
  return DateTime(year, month, day.clamp(1, daysInMonth));
}
