import 'package:flutter_test/flutter_test.dart';
import 'package:kaasutracker/features/dashboard/data/dashboard_calculations.dart';
import 'package:kaasutracker/features/emis/data/emi_model.dart';
import 'package:kaasutracker/features/expenses/data/expense.dart';

Expense expense({
  required String id,
  required double amount,
  required DateTime date,
}) {
  return Expense(
    id: id,
    amount: amount,
    category: 'Test',
    description: 'Test transaction',
    expenseDate: date,
  );
}

void main() {
  group('dashboard calculations', () {
    test('filters by month and year across year boundaries', () {
      final total = totalExpensesForMonth([
        expense(id: 'dec', amount: 100, date: DateTime(2025, 12, 31)),
        expense(id: 'jan', amount: 250, date: DateTime(2026, 1, 1)),
        expense(id: 'next-year', amount: 400, date: DateTime(2027, 1, 1)),
      ], DateTime(2026, 1));

      expect(total, 250);
    });

    test('deduplicates repeated expense IDs', () {
      final total = totalExpensesForMonth([
        expense(id: 'same', amount: 300, date: DateTime(2026, 6, 1)),
        expense(id: 'same', amount: 300, date: DateTime(2026, 6, 1)),
      ], DateTime(2026, 6));

      expect(total, 300);
    });

    test('refunds reduce expenses without creating negative spending', () {
      final total = totalExpensesForMonth([
        expense(id: 'purchase', amount: 500, date: DateTime(2026, 3, 1)),
        expense(id: 'refund', amount: -125, date: DateTime(2026, 3, 2)),
      ], DateTime(2026, 3));

      expect(total, 375);
      expect(
        totalExpensesForMonth([
          expense(id: 'refund-only', amount: -125, date: DateTime(2026, 3, 2)),
        ], DateTime(2026, 3)),
        0,
      );
    });

    test('selects next scheduled EMI and clamps to month end', () {
      final nextDate = nextScheduledEmiDate([
        const EmiModel(
          id: 'end-of-month',
          title: 'Month end',
          amount: 100,
          dueDateDay: 31,
        ),
        const EmiModel(
          id: 'inactive',
          title: 'Inactive',
          amount: 200,
          dueDateDay: 1,
          isActive: false,
        ),
      ], from: DateTime(2026, 2, 28, 14));

      expect(nextDate, DateTime(2026, 2, 28));
    });

    test('next EMI rolls into next year when due date has passed', () {
      final nextDate = nextScheduledEmiDate([
        const EmiModel(id: 'emi', title: 'EMI', amount: 100, dueDateDay: 10),
      ], from: DateTime(2026, 12, 11));

      expect(nextDate, DateTime(2027, 1, 10));
    });

    test('does not produce EMI dates when no active schedule exists', () {
      expect(
        nextScheduledEmiDate(const [], from: DateTime(2026, 10, 1)),
        isNull,
      );
    });
  });
}
