import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaasutracker/core/localization/generated/app_localizations.dart';
import 'package:kaasutracker/core/network/api_service.dart';
import 'package:kaasutracker/features/expenses/data/expense.dart';
import 'package:kaasutracker/features/expenses/data/expenses_provider.dart';
import 'package:kaasutracker/features/finance/data/expense_funding_context.dart';
import 'package:kaasutracker/features/finance/data/finance_models.dart';
import 'package:kaasutracker/features/finance/data/finance_repository.dart';
import 'package:kaasutracker/features/finance/presentation/expense_funding_screen.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  testWidgets('allocation form rejects amounts above the source balance', (
    tester,
  ) async {
    final fundingContext = _fundingContext(
      options: const [
        FundingOption(
          source: FundingSource.salary,
          sourceId: null,
          label: null,
          available: 5000,
          assigned: 0,
        ),
      ],
    );

    await tester.pumpWidget(
      _fundingApp(
        context: fundingContext,
        client: MockClient((_) async => http.Response('', 204)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), '60.00');
    await tester.pumpAndSettle();

    expect(
      find.text('An allocation exceeds the available balance.'),
      findsOneWidget,
    );
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
  });

  testWidgets(
    'requires an exact allocation total, saves once, and verifies persisted values',
    (tester) async {
      final fundingContext = _fundingContext(
        options: const [
          FundingOption(
            source: FundingSource.salary,
            sourceId: null,
            label: null,
            available: 10000,
            assigned: 0,
          ),
          FundingOption(
            source: FundingSource.additional,
            sourceId: 9,
            label: 'Gift · #9',
            available: 10000,
            assigned: 0,
          ),
        ],
      );
      final pendingPut = Completer<http.Response>();
      final requests = <http.Request>[];
      final client = MockClient((request) async {
        requests.add(request);
        if (request.method == 'PUT') return pendingPut.future;
        return http.Response(jsonEncode(_allocationsJson), 200);
      });

      await tester.pumpWidget(
        _fundingApp(context: fundingContext, client: client),
      );
      await tester.pumpAndSettle();

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), '30.00');
      await tester.pumpAndSettle();
      expect(find.text('₹70.00'), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );

      await tester.enterText(fields.at(1), '80.00');
      await tester.pumpAndSettle();
      expect(
        find.text('Allocations must equal the expense amount.'),
        findsOneWidget,
      );
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );

      await tester.enterText(fields.at(1), '70.00');
      await tester.pumpAndSettle();
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNotNull,
      );
      await tester.tap(find.text('Save changes'));
      await tester.pump();
      expect(requests, hasLength(1));
      expect(requests.single.method, 'PUT');
      expect(requests.single.url.path, '/api/v1/expenses/31/funding');
      expect(jsonDecode(requests.single.body), {
        'allocations': [
          {'fundingSource': 'SALARY', 'sourceId': null, 'amount': 30.0},
          {'fundingSource': 'ADDITIONAL', 'sourceId': 9, 'amount': 70.0},
        ],
      });

      await tester.tap(find.byType(FilledButton));
      await tester.pump();
      expect(requests, hasLength(1));

      pendingPut.complete(http.Response(jsonEncode(_allocationsJson), 200));
      await tester.pumpAndSettle();
      expect(requests, hasLength(2));
      expect(requests.last.method, 'GET');
    },
  );

  testWidgets('refreshes expense and dashboard providers after saving', (
    tester,
  ) async {
    final fundingContext = _fundingContext(
      options: const [
        FundingOption(
          source: FundingSource.salary,
          sourceId: null,
          label: null,
          available: 10000,
          assigned: 0,
        ),
      ],
    );
    final counts = _RefreshCounts();
    final client = MockClient(
      (request) async => http.Response(
        jsonEncode([
          {
            'id': 1,
            'fundingSource': 'SALARY',
            'sourceId': null,
            'amount': 100.0,
          },
        ]),
        200,
      ),
    );

    await tester.pumpWidget(
      _fundingApp(
        context: fundingContext,
        client: client,
        refreshCounts: counts,
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '100.00');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    expect(counts.expenses, greaterThan(1));
    expect(counts.expenseDetails, greaterThan(1));
    expect(counts.funding, greaterThan(1));
    expect(counts.dashboardSummary, greaterThan(1));
  });

  testWidgets('backend validation errors preserve the entered allocation', (
    tester,
  ) async {
    final fundingContext = _fundingContext(
      options: const [
        FundingOption(
          source: FundingSource.salary,
          sourceId: null,
          label: null,
          available: 10000,
          assigned: 0,
        ),
      ],
    );
    final client = MockClient(
      (_) async => http.Response(
        '{"message":"Allocation rejected","validationErrors":'
        '[{"field":"allocations","message":"Source is no longer available"}]}',
        422,
      ),
    );

    await tester.pumpWidget(
      _fundingApp(context: fundingContext, client: client),
    );
    await tester.pumpAndSettle();
    final field = find.byType(TextFormField);
    await tester.enterText(field, '100.00');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Allocation rejected'), findsOneWidget);
    expect(tester.widget<TextFormField>(field).controller!.text, '100.00');
    expect(find.text('Expense funding updated.'), findsNothing);
  });

  testWidgets('network failures keep the form available for retry', (
    tester,
  ) async {
    final fundingContext = _fundingContext(
      options: const [
        FundingOption(
          source: FundingSource.salary,
          sourceId: null,
          label: null,
          available: 10000,
          assigned: 0,
        ),
      ],
    );
    final client = MockClient((_) async => throw StateError('offline'));

    await tester.pumpWidget(
      _fundingApp(context: fundingContext, client: client),
    );
    await tester.pumpAndSettle();
    final field = find.byType(TextFormField);
    await tester.enterText(field, '100.00');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    expect(
      find.text('The request could not be completed. Please try again.'),
      findsOneWidget,
    );
    expect(tester.widget<TextFormField>(field).controller!.text, '100.00');
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
  });

  testWidgets('does not report success when the follow-up fetch differs', (
    tester,
  ) async {
    final fundingContext = _fundingContext(
      options: const [
        FundingOption(
          source: FundingSource.salary,
          sourceId: null,
          label: null,
          available: 10000,
          assigned: 0,
        ),
      ],
    );
    var getCount = 0;
    final client = MockClient((request) async {
      if (request.method == 'PUT') {
        return http.Response(
          jsonEncode([
            {
              'id': 3,
              'fundingSource': 'SALARY',
              'sourceId': null,
              'amount': 100.0,
            },
          ]),
          200,
        );
      }
      getCount++;
      return http.Response('[]', 200);
    });

    await tester.pumpWidget(
      _fundingApp(context: fundingContext, client: client),
    );
    await tester.pumpAndSettle();
    final field = find.byType(TextFormField);
    await tester.enterText(field, '100.00');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    expect(getCount, 1);
    expect(
      find.text(
        'The server did not confirm the requested allocation. Your changes are still on this screen.',
      ),
      findsOneWidget,
    );
    expect(find.text('Expense funding updated.'), findsNothing);
    expect(tester.widget<TextFormField>(field).controller!.text, '100.00');
  });
}

Widget _fundingApp({
  required ExpenseFundingContext context,
  required http.Client client,
  _RefreshCounts? refreshCounts,
}) {
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
  final summary = context.summary;
  final period = context.period;
  final expenseId = context.expenseId;
  final app = MaterialApp(
    home: ExpenseFundingScreen(expenseId: expenseId),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
  );
  return ProviderScope(
    overrides: [
      expenseFundingContextProvider(expenseId)
          .overrideWith((ref) async => context),
      financeRepositoryProvider.overrideWithValue(repository),
      if (refreshCounts != null) ...[
        expensesProvider.overrideWith((ref) async {
          refreshCounts.expenses++;
          return [context.expense];
        }),
        expenseDetailsProvider(expenseId).overrideWith((ref) async {
          refreshCounts.expenseDetails++;
          return context.expense;
        }),
        expenseFundingProvider(expenseId).overrideWith((ref) async {
          refreshCounts.funding++;
          return const [];
        }),
        monthlyFinancialSummaryProvider(period).overrideWith((ref) async {
          refreshCounts.dashboardSummary++;
          return summary;
        }),
      ],
    ],
    child: refreshCounts == null
        ? app
        : Consumer(
            builder: (context, ref, child) {
              ref.watch(expensesProvider);
              ref.watch(expenseDetailsProvider(expenseId));
              ref.watch(expenseFundingProvider(expenseId));
              ref.watch(monthlyFinancialSummaryProvider(period));
              return child!;
            },
            child: app,
          ),
  );
}

ExpenseFundingContext _fundingContext({required List<FundingOption> options}) =>
    ExpenseFundingContext(
      expenseId: 31,
      expense: Expense(
        id: '31',
        amount: 100,
        category: 'Food',
        description: 'Groceries',
        expenseDate: DateTime(2026, 10, 4),
      ),
      period: const FinancePeriod(year: 2026, month: 10),
      summary: MonthlyFinancialSummary.fromJson(_summaryJson),
      allocations: const [],
      options: options,
    );

final _summaryJson = <String, Object?>{
  'month': 10,
  'year': 2026,
  'baseMonthlySalary': 100,
  'openingCarryForwardBalance': 0,
  'additionalFundsReceived': 0,
  'borrowedFundsReceived': 0,
  'totalEligibleActualExpenses': 100,
  'salaryFundedExpenses': 0,
  'additionalFundsUsed': 0,
  'carryForwardUsed': 0,
  'borrowedFundsUsed': 0,
  'totalAllocatedExpenses': 0,
  'remainingSalaryAvailable': 100,
  'remainingCarryForwardAvailable': 0,
  'remainingAdditionalFundsAvailable': 0,
  'remainingBorrowedFundsAvailable': 0,
  'totalAvailableFunding': 100,
  'unfundedOverspending': 100,
  'monthlyEmiScheduledAmount': 0,
  'nextEmiDueDate': null,
  'nextEmiPaymentStatus': null,
};

final _allocationsJson = [
  {'id': 1, 'fundingSource': 'SALARY', 'sourceId': null, 'amount': 30.0},
  {'id': 2, 'fundingSource': 'ADDITIONAL', 'sourceId': 9, 'amount': 70.0},
];

class _RefreshCounts {
  int expenses = 0;
  int expenseDetails = 0;
  int funding = 0;
  int dashboardSummary = 0;
}
