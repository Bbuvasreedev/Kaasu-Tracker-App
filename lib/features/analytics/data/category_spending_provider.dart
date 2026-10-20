import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaasutracker/features/expenses/data/expenses_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'category_spending_provider.g.dart';

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

@riverpod
Future<List<CategorySpending>> categorySpending(Ref ref) async {
  final analytics = await ref.watch(expensesByCategoryProvider.future);
  return analytics.categorySpendingList;
}

final expensesByCategoryProvider =
    FutureProvider<MonthlyCategoryAnalytics>((ref) async {
  final expenses = await ref.watch(expensesProvider.future);
  final now = DateTime.now();

  // Filter expenses for current month
  final currentMonthExpenses = expenses.where((expense) {
    return expense.expenseDate.year == now.year &&
        expense.expenseDate.month == now.month;
  }).toList();

  final totals = <String, double>{};
  double totalSpending = 0.0;

  for (final expense in currentMonthExpenses) {
    totals.update(
      expense.category,
      (current) => current + expense.amount,
      ifAbsent: () => expense.amount,
    );
    totalSpending += expense.amount;
  }

  final sortedEntries = totals.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  final categoryList = <CategorySpending>[];
  for (var i = 0; i < sortedEntries.length; i++) {
    final entry = sortedEntries[i];
    final percentage =
        totalSpending > 0 ? (entry.value / totalSpending) * 100.0 : 0.0;
    final color = _categoryColors[i % _categoryColors.length];

    categoryList.add(
      CategorySpending(
        category: entry.key,
        totalAmount: entry.value,
        percentage: percentage,
        color: color,
      ),
    );
  }

  return MonthlyCategoryAnalytics(
    totalMonthlySpending: totalSpending,
    categorySpendingList: categoryList,
  );
});
