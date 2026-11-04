import 'package:kaasutracker/core/network/api_service.dart';
import 'package:kaasutracker/features/expenses/data/expense.dart';
import 'package:kaasutracker/features/auth/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'expenses_provider.g.dart';

Duration? _disableAutomaticRetry(int retryCount, Object error) => null;

class ExpenseRepository {
  const ExpenseRepository(this._api);

  final ApiService _api;

  Future<void> deleteExpense(int expenseId) async {
    if (expenseId <= 0) {
      throw ArgumentError.value(expenseId, 'expenseId', 'Must be positive.');
    }
    await _api.delete('expenses/$expenseId');
  }
}

final expenseRepositoryProvider = Provider<ExpenseRepository>(
  (ref) => ExpenseRepository(ref.watch(apiServiceProvider)),
);

@Riverpod(retry: _disableAutomaticRetry)
Future<List<Expense>> expenses(Ref ref) async {
  ref.watch(authStateStreamProvider);
  final api = ref.watch(apiServiceProvider);
  final response = await api.get('expenses');
  if (response is! List) {
    throw const FormatException(
      'Expected the expenses endpoint to return a list.',
    );
  }

  return response
      .map((item) {
        if (item is! Map<String, dynamic>) {
          throw const FormatException(
            'Expected each expense to be a JSON object.',
          );
        }
        return Expense.fromJson(item);
      })
      .toList(growable: false);
}

final expenseDetailsProvider = FutureProvider.family<Expense?, int>((
  ref,
  expenseId,
) async {
  if (expenseId <= 0) return null;
  final expenses = await ref.watch(expensesProvider.future);
  for (final expense in expenses) {
    if (expense.id == '$expenseId') return expense;
  }
  return null;
}, retry: _disableAutomaticRetry);
