import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kaasutracker/core/network/api_service.dart';
import 'package:kaasutracker/features/expenses/data/expense.dart';
import 'package:kaasutracker/features/expenses/data/expenses_provider.dart';
import 'package:kaasutracker/features/finance/data/expense_funding_context.dart';
import 'package:kaasutracker/features/finance/data/finance_models.dart';
import 'package:kaasutracker/features/finance/data/finance_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('loads current allocations and computes source balances', () async {
    final expense = Expense(
      id: '31',
      amount: 50,
      category: 'Food',
      description: 'Groceries',
      expenseDate: DateTime(2026, 10, 4),
    );
    final allocations = [
      {'id': 14, 'fundingSource': 'SALARY', 'sourceId': null, 'amount': 40.0},
      {'id': 15, 'fundingSource': 'ADDITIONAL', 'sourceId': 9, 'amount': 10.0},
    ];
    final client = MockClient((request) async {
      final path = request.url.path;
      if (path.endsWith('/expenses/31/funding')) {
        return http.Response(jsonEncode(allocations), 200);
      }
      if (path.endsWith('/finance/monthly-summary')) {
        return http.Response(jsonEncode(_summary), 200);
      }
      if (path.endsWith('/finance/carry-forward')) {
        return http.Response(
          jsonEncode({
            'id': 12,
            'year': 2026,
            'month': 10,
            'openingBalance': 20,
            'calculatedEligibleClosingBalance': 0,
            'monthlySummary': null,
          }),
          200,
        );
      }
      if (path.endsWith('/additional-funds')) {
        return http.Response(
          jsonEncode({
            'funds': [
              {
                'id': 9,
                'amount': 40,
                'fundDate': '2026-10-03',
                'sourceDescription': 'Gift',
                'status': 'INACTIVE',
              },
            ],
            'totalReceived': 40,
            'totalUsed': 10,
            'remainingAvailable': 30,
          }),
          200,
        );
      }
      if (path.endsWith('/borrowed-funds')) {
        return http.Response(
          jsonEncode({
            'funds': [],
            'totalReceived': 0,
            'totalUsed': 0,
            'remainingAvailable': 0,
          }),
          200,
        );
      }
      throw StateError('Unexpected request: ${request.method} $path');
    });
    final repository = FinanceRepository(
      ApiService(
        client: client,
        supabase: SupabaseClient(
          'http://localhost:54321',
          'test-anon-key',
          authOptions: const AuthClientOptions(autoRefreshToken: false),
        ),
        baseUrl: Uri.parse('http://localhost:8080/api/v1/'),
        accessTokenProvider: () => 'test-token',
      ),
    );
    final container = ProviderContainer(
      overrides: [
        expensesProvider.overrideWith((ref) async => [expense]),
        financeRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(() {
      container.dispose();
      client.close();
    });

    final result = await container.read(
      expenseFundingContextProvider(31).future,
    );

    expect(result.allocations, hasLength(2));
    final salary = result.options.singleWhere(
      (option) => option.source == FundingSource.salary,
    );
    expect(salary.assigned, 4000);
    expect(salary.available, 10000);
    final additional = result.options.singleWhere(
      (option) => option.source == FundingSource.additional,
    );
    expect(additional.assigned, 1000);
    expect(additional.available, 0);
    expect(additional.label, 'Gift · #9');
  });
}

final _summary = <String, Object?>{
  'month': 10,
  'year': 2026,
  'baseMonthlySalary': 100,
  'openingCarryForwardBalance': 0,
  'additionalFundsReceived': 40,
  'borrowedFundsReceived': 0,
  'totalEligibleActualExpenses': 50,
  'salaryFundedExpenses': 40,
  'additionalFundsUsed': 10,
  'carryForwardUsed': 0,
  'borrowedFundsUsed': 0,
  'totalAllocatedExpenses': 50,
  'remainingSalaryAvailable': 60,
  'remainingCarryForwardAvailable': 0,
  'remainingAdditionalFundsAvailable': 30,
  'remainingBorrowedFundsAvailable': 0,
  'totalAvailableFunding': 90,
  'unfundedOverspending': 0,
  'monthlyEmiScheduledAmount': 0,
  'nextEmiDueDate': null,
  'nextEmiPaymentStatus': null,
};
