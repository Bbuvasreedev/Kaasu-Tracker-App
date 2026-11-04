import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:kaasutracker/core/network/api_service.dart';
import 'package:kaasutracker/features/analytics/data/category_spending_provider.dart';
import 'package:kaasutracker/features/auth/auth_provider.dart';
import 'package:kaasutracker/features/expenses/data/expense.dart';
import 'package:kaasutracker/features/expenses/data/expenses_provider.dart';
import 'package:kaasutracker/features/finance/data/finance_models.dart';
import 'package:kaasutracker/features/finance/data/finance_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  const october = FinancePeriod(year: 2026, month: 10);
  const november = FinancePeriod(year: 2026, month: 11);

  test('monthly totals use a half-open month range and eligible amounts', () {
    final analytics = calculateMonthlyCategoryAnalytics([
      _expense('october', '2026-10-31T23:59:59', amount: 40),
      _expense('november', '2026-11-01T00:00:00', amount: 100, refund: 20),
      _expense('refund', '2026-11-15T12:00:00', amount: -25),
      _expense('december', '2026-12-01T00:00:00', amount: 300),
    ], november);

    expect(analytics.totalMonthlySpending, 55);
    expect(analytics.categorySpendingList.single.category, 'Food');
    expect(analytics.categorySpendingList.single.totalAmount, 55);
  });

  test(
    'duplicate expense records are counted once, not once per allocation',
    () {
      final expense = _expense('expense-1', '2026-11-12', amount: 125);
      final analytics = calculateMonthlyCategoryAnalytics([
        expense,
        expense,
      ], november);

      expect(analytics.totalMonthlySpending, 125);
    },
  );

  test('changing the selected finance period recalculates analytics', () async {
    var expenseRequests = 0;
    final container = ProviderContainer(
      overrides: [
        expensesProvider.overrideWith((ref) async {
          expenseRequests++;
          return [
            _expense('october', '2026-10-12', amount: 45),
            _expense('november', '2026-11-12', amount: 70),
          ];
        }),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      expensesByCategoryProvider,
      (previous, next) {},
    );
    addTearDown(subscription.close);
    container.read(selectedFinancePeriodProvider.notifier).select(october);

    expect(
      (await container.read(expensesByCategoryProvider.future))
          .totalMonthlySpending,
      45,
    );

    container.read(selectedFinancePeriodProvider.notifier).select(november);

    expect(
      (await container.read(expensesByCategoryProvider.future))
          .totalMonthlySpending,
      70,
    );
    expect(expenseRequests, 1);
  });

  test(
    'malformed expenses endpoint responses throw instead of becoming empty',
    () async {
      final supabase = SupabaseClient(
        'http://localhost:54321',
        'test-anon-key',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      );
      final container = ProviderContainer(
        overrides: [
          authStateStreamProvider.overrideWith((ref) => const Stream.empty()),
          apiServiceProvider.overrideWithValue(
            ApiService(
              client: _JsonResponseClient({'expenses': []}),
              supabase: supabase,
              accessTokenProvider: () => 'test-token',
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(
        expensesProvider,
        (previous, next) {},
      );
      addTearDown(subscription.close);

      await expectLater(
        container.read(expensesProvider.future),
        throwsA(isA<FormatException>()),
      );
    },
  );
}

Expense _expense(
  String id,
  String date, {
  required double amount,
  double refund = 0,
}) => Expense(
  id: id,
  amount: amount,
  category: 'Food',
  description: '',
  expenseDate: DateTime.parse(date),
  refundedAmount: refund,
);

class _JsonResponseClient extends http.BaseClient {
  _JsonResponseClient(this.body);

  final Object body;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    return http.StreamedResponse(
      Stream.value(utf8.encode(jsonEncode(body))),
      200,
      headers: {'content-type': 'application/json'},
    );
  }
}
