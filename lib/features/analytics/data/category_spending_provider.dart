import 'package:kaasutracker/features/expenses/data/expenses_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'category_spending_provider.g.dart';

class CategorySpending {
  const CategorySpending({required this.category, required this.total});

  final String category;
  final double total;
}

@riverpod
Future<List<CategorySpending>> categorySpending(Ref ref) async {
  final expenses = await ref.watch(expensesProvider.future);
  final totals = <String, double>{};

  for (final expense in expenses) {
    totals.update(
      expense.category,
      (total) => total + expense.amount,
      ifAbsent: () => expense.amount,
    );
  }

  final spending = totals.entries
      .map((entry) => CategorySpending(category: entry.key, total: entry.value))
      .toList();
  spending.sort((a, b) => b.total.compareTo(a.total));
  return spending;
}
