import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:kaasutracker/core/localization/generated/app_localizations.dart';
import 'package:kaasutracker/core/network/api_service.dart';
import 'package:kaasutracker/features/expenses/data/expense.dart';
import 'package:kaasutracker/features/expenses/data/expenses_provider.dart';
import 'package:kaasutracker/features/expenses/presentation/expense_details_screen.dart';
import 'package:kaasutracker/features/finance/data/finance_models.dart';
import 'package:kaasutracker/features/finance/data/finance_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _period = FinancePeriod(year: 2026, month: 11);

void main() {
  testWidgets('details show expense fields and backend funding allocations', (
    tester,
  ) async {
    await _pumpDetails(
      tester,
      expenseList: [_expense],
      allocations: const [
        ExpenseFundingAllocation(
          id: 1,
          fundingSource: FundingSource.salary,
          sourceId: null,
          amount: 2500,
        ),
        ExpenseFundingAllocation(
          id: 2,
          fundingSource: FundingSource.borrowed,
          sourceId: 7,
          amount: 2500,
        ),
      ],
    );

    expect(find.text('Groceries'), findsWidgets);
    expect(find.text('Food'), findsOneWidget);
    expect(find.text('₹50.00'), findsNWidgets(2));
    expect(find.text('₹25.00'), findsNWidgets(2));
    expect(find.text('Current-month salary balance'), findsOneWidget);
    expect(find.text('Borrowed funds'), findsOneWidget);
    expect(find.text('Delete expense'), findsOneWidget);
  });

  testWidgets('missing and invalid expense IDs show not-found state', (
    tester,
  ) async {
    await _pumpDetails(tester, expenseList: const [], expenseId: 31);
    expect(find.text('Expense not found.'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('invalid expense ID immediately shows not-found state', (
    tester,
  ) async {
    await _pumpDetails(tester, expenseList: const [], expenseId: 0);
    expect(find.text('Expense not found.'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('expense page shows loading only while list request is pending', (
    tester,
  ) async {
    final pending = Completer<List<Expense>>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          expensesProvider.overrideWith((ref) => pending.future),
          expenseFundingProvider(31).overrideWith((ref) async => const []),
        ],
        child: const _App(expenseId: 31),
      ),
    );
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    pending.complete([_expense]);
    await tester.pumpAndSettle();
    expect(find.text('Groceries'), findsWidgets);
  });

  testWidgets('expense loading failures show error and Retry', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          expenseDetailsProvider(31).overrideWith(
            (ref) async => throw const ApiException(
              statusCode: 503,
              message: 'not available',
            ),
          ),
        ],
        child: const _App(expenseId: 31),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('The service is temporarily unavailable. Please try again.'),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('cancel leaves the expense unchanged and does not delete', (
    tester,
  ) async {
    final api = _RecordingApi();
    await _pumpDetails(
      tester,
      expenseList: [_expense],
      api: api,
      allocations: const [],
    );
    await tester.tap(find.text('Delete expense'));
    await tester.pumpAndSettle();

    expect(find.text('Groceries'), findsWidgets);
    expect(find.text('₹50.00'), findsWidgets);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(api.deleteRequests, isEmpty);
    expect(find.text('Expense details'), findsOneWidget);
    expect(find.text('Groceries'), findsWidgets);
  });

  testWidgets('failed delete keeps expense visible and shows an error', (
    tester,
  ) async {
    final api = _RecordingApi(statusCode: 500);
    await _pumpDetails(
      tester,
      expenseList: [_expense],
      api: api,
      allocations: const [],
    );

    await tester.tap(find.text('Delete expense'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete expense').last);
    await tester.pumpAndSettle();

    expect(api.deleteRequests, ['DELETE /api/v1/expenses/31']);
    expect(find.text('Expense details'), findsOneWidget);
    expect(find.text('Groceries'), findsWidgets);
    expect(
      find.text('The service is temporarily unavailable. Please try again.'),
      findsOneWidget,
    );
  });

  testWidgets('successful delete refreshes expense and balance providers', (
    tester,
  ) async {
    final api = _RecordingApi();
    var deleted = false;
    var expenseRequests = 0;
    var summaryRequests = 0;
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => _BalanceHome(period: _period),
        ),
        GoRoute(
          path: '/expenses/:expenseId/details',
          builder: (context, state) => ExpenseDetailsScreen(
            expenseId: int.parse(state.pathParameters['expenseId']!),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiServiceProvider.overrideWithValue(api.service),
          expenseDetailsProvider(31).overrideWith((ref) async {
            expenseRequests++;
            return deleted ? null : _expense;
          }),
          expensesProvider.overrideWith((ref) async {
            expenseRequests++;
            return deleted ? const [] : [_expense];
          }),
          monthlyFinancialSummaryProvider(_period).overrideWith((ref) async {
            summaryRequests++;
            return _summary(deleted ? 9000 : 5000);
          }),
          expenseFundingProvider(31).overrideWith((ref) async => const []),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('balance:50.00'), findsOneWidget);
    await tester.tap(find.text('Open expense'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete expense'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete expense').last);
    deleted = true;
    await tester.pumpAndSettle();

    expect(api.deleteRequests, ['DELETE /api/v1/expenses/31']);
    expect(find.text('balance:90.00'), findsOneWidget);
    expect(find.text('expenses:0'), findsOneWidget);
    expect(find.text('Open expense'), findsOneWidget);
    expect(expenseRequests, greaterThan(1));
    expect(summaryRequests, greaterThan(1));
  });
}

final _expense = Expense(
  id: '31',
  amount: 50,
  category: 'Food',
  description: 'Groceries',
  expenseDate: DateTime(2026, 11, 1, 13, 30),
);

Future<void> _pumpDetails(
  WidgetTester tester, {
  required List<Expense> expenseList,
  int expenseId = 31,
  List<ExpenseFundingAllocation> allocations = const [],
  _RecordingApi? api,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        apiServiceProvider.overrideWithValue((api ?? _RecordingApi()).service),
        expensesProvider.overrideWith((ref) async => expenseList),
        expenseFundingProvider(expenseId)
            .overrideWith((ref) async => allocations),
      ],
      child: _App(expenseId: expenseId),
    ),
  );
  await tester.pumpAndSettle();
}

class _App extends StatelessWidget {
  const _App({required this.expenseId});

  final int expenseId;

  @override
  Widget build(BuildContext context) => MaterialApp(
    home: ExpenseDetailsScreen(expenseId: expenseId),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
  );
}

class _RecordingApi {
  _RecordingApi({this.statusCode = 204}) {
    service = ApiService(
      client: _DeleteClient(this, statusCode),
      supabase: SupabaseClient(
        'http://localhost:54321',
        'test-anon-key',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      ),
      baseUrl: Uri.parse('http://localhost/api/v1/'),
      accessTokenProvider: () => 'test-token',
    );
  }

  final int statusCode;
  final deleteRequests = <String>[];
  late final ApiService service;
}

class _DeleteClient extends http.BaseClient {
  _DeleteClient(this.recorder, this.statusCode);

  final _RecordingApi recorder;
  final int statusCode;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    recorder.deleteRequests.add('${request.method} ${request.url.path}');
    return http.StreamedResponse(
      Stream.value(
        statusCode == 204
            ? <int>[]
            : http.Response(
                '{"message":"server failed"}',
                statusCode,
              ).bodyBytes,
      ),
      statusCode,
    );
  }
}

class _BalanceHome extends ConsumerWidget {
  const _BalanceHome({required this.period});

  final FinancePeriod period;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenses = ref.watch(expensesProvider);
    final summary = ref.watch(monthlyFinancialSummaryProvider(period));
    return Scaffold(
      body: Column(
        children: [
          Text(
            summary.when(
              data: (value) =>
                  'balance:${(value.remainingSalaryAvailable / 100).toStringAsFixed(2)}',
              loading: () => 'loading',
              error: (_, _) => 'error',
            ),
          ),
          expenses.when(
            data: (items) => Text('expenses:${items.length}'),
            loading: () => const Text('loading expenses'),
            error: (_, _) => const Text('expense error'),
          ),
          TextButton(
            onPressed: () => context.push('/expenses/31/details'),
            child: const Text('Open expense'),
          ),
        ],
      ),
    );
  }
}

MonthlyFinancialSummary _summary(int balance) =>
    MonthlyFinancialSummary.fromJson({
      'month': 11,
      'year': 2026,
      'baseMonthlySalary': 100000,
      'openingCarryForwardBalance': 0,
      'additionalFundsReceived': 0,
      'borrowedFundsReceived': 0,
      'totalEligibleActualExpenses': 5000,
      'salaryFundedExpenses': 5000,
      'additionalFundsUsed': 0,
      'carryForwardUsed': 0,
      'borrowedFundsUsed': 0,
      'totalAllocatedExpenses': 5000,
      'remainingSalaryAvailable': balance / 100,
      'remainingCarryForwardAvailable': 0,
      'remainingAdditionalFundsAvailable': 0,
      'remainingBorrowedFundsAvailable': 0,
      'totalAvailableFunding': balance / 100,
      'unfundedOverspending': 0,
      'monthlyEmiScheduledAmount': 0,
      'nextEmiDueDate': null,
      'nextEmiPaymentStatus': null,
    });
