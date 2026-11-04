import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:kaasutracker/core/localization/generated/app_localizations.dart';
import 'package:kaasutracker/core/network/api_service.dart';
import 'package:kaasutracker/features/analytics/presentation/analytics_screen.dart';
import 'package:kaasutracker/features/auth/auth_provider.dart';
import 'package:kaasutracker/features/dashboard/presentation/dashboard_page.dart';
import 'package:kaasutracker/features/expenses/data/expenses_provider.dart';
import 'package:kaasutracker/features/expenses/presentation/add_expense_screen.dart';
import 'package:kaasutracker/features/finance/data/finance_models.dart';
import 'package:kaasutracker/features/finance/data/finance_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  testWidgets('a saved expense refreshes the expense provider and Analytics', (
    tester,
  ) async {
    final client = _ExpenseApiClient();
    final supabase = SupabaseClient(
      'http://localhost:54321',
      'test-anon-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const _HomeScreen(),
        ),
        GoRoute(
          path: '/add-expense',
          builder: (context, state) => const AddExpenseScreen(),
        ),
        GoRoute(
          path: '/analytics',
          builder: (context, state) => const AnalyticsScreen(),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateStreamProvider.overrideWith((ref) => const Stream.empty()),
          apiServiceProvider.overrideWithValue(
            ApiService(
              client: client,
              supabase: supabase,
              accessTokenProvider: () => 'test-token',
            ),
          ),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(client.getCount, 1);

    await tester.tap(find.text('Add expense'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), '50.00');
    await tester.enterText(find.byType(TextFormField).at(1), 'Groceries');
    await tester.tap(find.text('Save Expense'));
    await tester.pumpAndSettle();

    expect(client.postCount, 1);
    expect(client.getCount, greaterThanOrEqualTo(2));

    await tester.tap(find.text('Analytics'));
    await tester.pumpAndSettle();

    expect(find.textContaining('50.00'), findsNWidgets(2));
    expect(find.text('No expenses this month'), findsNothing);
  });

  testWidgets('saving an expense reloads the backend dashboard summary', (
    tester,
  ) async {
    final client = _ExpenseApiClient();
    final supabase = SupabaseClient(
      'http://localhost:54321',
      'test-anon-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    final period = FinancePeriod.fromDate(DateTime.now());
    var summaryRequests = 0;
    final router = GoRouter(
      initialLocation: '/dashboard',
      routes: [
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const DashboardPage(),
        ),
        GoRoute(
          path: '/expenses/add',
          builder: (context, state) => const AddExpenseScreen(),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateStreamProvider.overrideWith((ref) => const Stream.empty()),
          apiServiceProvider.overrideWithValue(
            ApiService(
              client: client,
              supabase: supabase,
              accessTokenProvider: () => 'test-token',
            ),
          ),
          selectedFinancePeriodProvider.overrideWith(
            _FixedFinancePeriodNotifier.new,
          ),
          monthlyFinancialSummaryProvider(period).overrideWith((ref) async {
            summaryRequests++;
            final spent = summaryRequests == 1 ? 0 : 5000;
            return _summary(period, spent);
          }),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(summaryRequests, 1);
    expect(find.textContaining('₹0.00'), findsWidgets);

    await tester.tap(find.text('Add expense'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), '50.00');
    await tester.enterText(find.byType(TextFormField).at(1), 'Groceries');
    await tester.tap(find.text('Save Expense'));
    await tester.pumpAndSettle();

    expect(summaryRequests, greaterThan(1));
    expect(find.textContaining('₹50.00'), findsNWidgets(2));
  });
}

MonthlyFinancialSummary _summary(FinancePeriod period, int spent) =>
    MonthlyFinancialSummary.fromJson({
      'month': period.month,
      'year': period.year,
      'baseMonthlySalary': 1000,
      'openingCarryForwardBalance': 0,
      'additionalFundsReceived': 0,
      'borrowedFundsReceived': 0,
      'totalEligibleActualExpenses': spent / 100,
      'salaryFundedExpenses': spent / 100,
      'additionalFundsUsed': 0,
      'carryForwardUsed': 0,
      'borrowedFundsUsed': 0,
      'totalAllocatedExpenses': spent / 100,
      'remainingSalaryAvailable': 1000 - spent / 100,
      'remainingCarryForwardAvailable': 0,
      'remainingAdditionalFundsAvailable': 0,
      'remainingBorrowedFundsAvailable': 0,
      'totalAvailableFunding': 1000,
      'unfundedOverspending': 0,
      'monthlyEmiScheduledAmount': 0,
      'nextEmiDueDate': null,
      'nextEmiPaymentStatus': null,
    });

class _FixedFinancePeriodNotifier extends SelectedFinancePeriodNotifier {
  @override
  FinancePeriod build() => FinancePeriod.fromDate(DateTime.now());
}

class _HomeScreen extends ConsumerWidget {
  const _HomeScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(expensesProvider);
    return Scaffold(
      body: Column(
        children: [
          TextButton(
            onPressed: () => context.push('/add-expense'),
            child: const Text('Add expense'),
          ),
          TextButton(
            onPressed: () => context.push('/analytics'),
            child: const Text('Analytics'),
          ),
        ],
      ),
    );
  }
}

class _ExpenseApiClient extends http.BaseClient {
  final List<Map<String, Object?>> _expenses = [];
  int getCount = 0;
  int postCount = 0;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    late final int statusCode;
    late final Object body;
    if (request.method == 'GET' && request.url.path.endsWith('/expenses')) {
      getCount++;
      statusCode = 200;
      body = _expenses;
    } else if (request.method == 'POST' &&
        request.url.path.endsWith('/expenses')) {
      postCount++;
      final payload =
          jsonDecode((request as http.Request).body) as Map<String, dynamic>;
      final expense = <String, Object?>{
        'id': postCount,
        'amount': payload['amount'],
        'category': payload['category'],
        'description': payload['description'],
        'expenseDate': payload['expenseDate'],
        'isConfirmed': payload['isConfirmed'],
      };
      _expenses.add(expense);
      statusCode = 201;
      body = expense;
    } else {
      statusCode = 404;
      body = {'message': 'Unexpected test request'};
    }

    return http.StreamedResponse(
      Stream.value(utf8.encode(jsonEncode(body))),
      statusCode,
      headers: {'content-type': 'application/json'},
    );
  }
}
