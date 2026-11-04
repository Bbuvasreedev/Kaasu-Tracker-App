import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaasutracker/features/expenses/data/expense.dart';
import 'package:kaasutracker/features/expenses/data/expense_period.dart';
import 'package:kaasutracker/features/expenses/data/expenses_provider.dart';
import 'package:kaasutracker/features/finance/data/finance_models.dart';
import 'package:kaasutracker/features/finance/data/finance_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'category_spending_provider.g.dart';

Duration? _disableAutomaticRetry(int retryCount, Object error) => null;

class CategorySpending {
  const CategorySpending({
    required this.category,
    required this.totalAmount,
    required this.percentage,
    required this.color,
  });

  /// Category name
  final String category;

  /// Total spending in this category for the month
  final double totalAmount;

  /// Percentage of total monthly spending
  final double percentage;

  /// Color representation in charts and legends
  final Color color;

  /// Compatibility getter for legacy callers
  double get total => totalAmount;
}

class MonthlyCategoryAnalytics {
  const MonthlyCategoryAnalytics({
    required this.totalMonthlySpending,
    required this.categorySpendingList,
  });

  final double totalMonthlySpending;
  final List<CategorySpending> categorySpendingList;
}

const _categoryColors = <Color>[
  Color(0xFF6750A4), // Primary Purple
  Color(0xFF006A60), // Teal
  Color(0xFFB5233C), // Crimson/Red
  Color(0xFFD97706), // Amber/Orange
  Color(0xFF2563EB), // Royal Blue
  Color(0xFF059669), // Emerald
  Color(0xFF9333EA), // Purple
  Color(0xFFDB2777), // Pink
];

MonthlyCategoryAnalytics calculateMonthlyCategoryAnalytics(
  List<Expense> expenses,
  FinancePeriod period,
) {
  final totalsMinorUnits = <String, int>{};
  final seenIds = <String>{};

  for (final expense in expenses) {
    if (!expenseIsInPeriod(expense, period) ||
        !expense.amount.isFinite ||
        (expense.id.isNotEmpty &&
            expense.id != 'null' &&
            !seenIds.add(expense.id))) {
      continue;
    }

    final amount = expense.amountMinorUnits < 0
        ? expense.amountMinorUnits
        : expense.eligibleAmountMinorUnits;
    totalsMinorUnits.update(
      expense.category,
      (current) => current + amount,
      ifAbsent: () => amount,
    );
  }

  final sortedEntries =
      totalsMinorUnits.entries.where((entry) => entry.value > 0).toList()
        ..sort((a, b) => b.value.compareTo(a.value));
  final totalMinorUnits = sortedEntries.fold<int>(
    0,
    (total, entry) => total + entry.value,
  );
  final categories = <CategorySpending>[
    for (var index = 0; index < sortedEntries.length; index++)
      CategorySpending(
        category: sortedEntries[index].key,
        totalAmount: sortedEntries[index].value / 100,
        percentage: totalMinorUnits == 0
            ? 0
            : sortedEntries[index].value / totalMinorUnits * 100,
        color: _categoryColors[index % _categoryColors.length],
      ),
  ];

  return MonthlyCategoryAnalytics(
    totalMonthlySpending: totalMinorUnits / 100,
    categorySpendingList: categories,
  );
}

@Riverpod(retry: _disableAutomaticRetry)
Future<List<CategorySpending>> categorySpending(Ref ref) async {
  final analytics = await ref.watch(expensesByCategoryProvider.future);
  return analytics.categorySpendingList;
}

final expensesByCategoryProvider = FutureProvider<MonthlyCategoryAnalytics>((
  ref,
) async {
  final period = ref.watch(selectedFinancePeriodProvider);
  try {
    final expenses = await ref.watch(expensesProvider.future);
    return calculateMonthlyCategoryAnalytics(expenses, period);
  } catch (error) {
    debugPrint('Expense analytics load failed (${error.runtimeType}).');
    rethrow;
  }
}, retry: _disableAutomaticRetry);
