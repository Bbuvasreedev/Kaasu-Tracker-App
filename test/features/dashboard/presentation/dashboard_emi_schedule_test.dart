import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kaasutracker/core/localization/generated/app_localizations.dart';
import 'package:kaasutracker/features/dashboard/presentation/dashboard_page.dart';
import 'package:kaasutracker/features/dashboard/presentation/main_layout.dart';
import 'package:kaasutracker/features/emis/data/emi_model.dart';
import 'package:kaasutracker/features/emis/data/emis_provider.dart';
import 'package:kaasutracker/features/expenses/data/expenses_provider.dart';
import 'package:kaasutracker/features/finance/data/finance_models.dart';
import 'package:kaasutracker/features/finance/data/finance_repository.dart';

const _period = FinancePeriod(year: 2026, month: 11);

void main() {
  test('schedule distinguishes due today from future recurring payments', () {
    final emis = [
      _emi('today', 'Rent loan', 120, DateTime(2026, 11, 12).day),
      _emi('future', 'Vehicle loan', 200, 15),
      _emi('today', 'Duplicate', 999, 12),
    ];

    final schedule = buildEmiSchedule(emis, now: DateTime(2026, 11, 12));

    expect(schedule, hasLength(2));
    expect(schedule[0].emi.title, 'Rent loan');
    expect(
      schedule[0].statusFor(DateTime(2026, 11, 12)),
      EmiScheduleStatus.dueToday,
    );
    expect(
      schedule[1].statusFor(DateTime(2026, 11, 12)),
      EmiScheduleStatus.scheduled,
    );
    expect(schedule[1].dueDate, DateTime(2026, 11, 15));
  });

  test(
    'schedule advances past due-day to the next month without marking paid',
    () {
      final schedule = buildEmiSchedule([
        _emi('monthly', 'Loan', 100, 10),
      ], now: DateTime(2026, 11, 11));

      expect(schedule.single.dueDate, DateTime(2026, 12, 10));
      expect(
        schedule.single.statusFor(DateTime(2026, 11, 11)),
        EmiScheduleStatus.scheduled,
      );
    },
  );

  testWidgets(
    'dashboard shows EMI schedule, due-today amount, and no duplicates',
    (tester) async {
      final today = DateTime.now();
      final futureDay = today.day < 28 ? today.day + 1 : 1;
      await _pumpDashboard(tester, [
        _emi('today', 'Current loan', 120, today.day),
        _emi('future', 'Future loan', 200, futureDay),
        _emi('today', 'Duplicate loan', 999, today.day),
      ]);

      expect(find.text('EMI schedule'), findsOneWidget);
      expect(find.text('Monthly EMI scheduled'), findsNothing);
      expect(find.text('Current loan'), findsNothing);

      await tester.ensureVisible(find.text('EMI schedule'));
      await tester.tap(find.text('EMI schedule'));
      await tester.pumpAndSettle();

      expect(find.text('Monthly EMI scheduled'), findsOneWidget);
      expect(find.text('₹320.00'), findsOneWidget);
      expect(find.text('EMI due today'), findsWidgets);
      expect(find.text('₹120.00'), findsNWidgets(2));
      expect(find.text('Current loan'), findsOneWidget);
      expect(find.text('Future loan'), findsOneWidget);
      expect(find.text('Duplicate loan'), findsNothing);
      expect(find.text('Paid'), findsNothing);
      expect(find.text('Overdue'), findsNothing);
      expect(find.text('Borrowed funds used'), findsOneWidget);
    },
  );

  testWidgets('dashboard displays an empty schedule state', (tester) async {
    await _pumpDashboard(tester, const []);

    expect(find.text('No active EMI schedules'), findsNothing);
    await tester.ensureVisible(find.text('EMI schedule'));
    await tester.tap(find.text('EMI schedule'));
    await tester.pumpAndSettle();
    expect(find.text('No active EMI schedules'), findsOneWidget);
  });

  testWidgets('dashboard shows EMI loading and API error states', (
    tester,
  ) async {
    final pending = Completer<List<EmiModel>>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          selectedFinancePeriodProvider.overrideWith(_FixedPeriodNotifier.new),
          monthlyFinancialSummaryProvider(_period)
              .overrideWith((ref) async => _summary()),
          emisProvider.overrideWith((ref) => pending.future),
          expensesProvider.overrideWith((ref) async => const []),
        ],
        child: const _DashboardApp(),
      ),
    );
    await tester.pump();
    expect(find.text('EMI schedule'), findsOneWidget);
    expect(find.text('Could not load EMIs'), findsNothing);
    await tester.ensureVisible(find.text('EMI schedule'));
    await tester.tap(find.text('EMI schedule'));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.byType(CircularProgressIndicator), findsWidgets);
    expect(find.byType(CircularProgressIndicator), findsWidgets);

    pending.completeError(const FormatException('Unavailable'));
    await tester.pumpAndSettle();
    expect(find.text('Could not load EMIs'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('EMI expansion is independent of Recent Expenses', (
    tester,
  ) async {
    await _pumpDashboard(tester, [
      _emi('loan', 'Loan', 100, DateTime.now().day),
    ]);

    expect(find.text('Loan'), findsNothing);
    await tester.ensureVisible(find.text('EMI schedule'));
    await tester.tap(find.text('EMI schedule'));
    await tester.pumpAndSettle();
    expect(find.text('Loan'), findsOneWidget);
    expect(find.text('Recent Expenses'), findsOneWidget);
    expect(find.text('No expenses recorded yet'), findsNothing);

    await tester.ensureVisible(find.text('Recent Expenses'));
    await tester.tap(find.text('Recent Expenses'));
    await tester.pumpAndSettle();
    expect(find.text('Loan'), findsOneWidget);
    expect(find.text('No expenses recorded yet'), findsOneWidget);

    await tester.ensureVisible(find.text('EMI schedule'));
    await tester.tap(find.text('EMI schedule'));
    await tester.pumpAndSettle();
    expect(find.text('Loan'), findsNothing);
    expect(find.text('No expenses recorded yet'), findsOneWidget);
  });

  testWidgets('dashboard pull-to-refresh reloads the EMI schedule', (
    tester,
  ) async {
    var requests = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          selectedFinancePeriodProvider.overrideWith(_FixedPeriodNotifier.new),
          monthlyFinancialSummaryProvider(_period)
              .overrideWith((ref) async => _summary()),
          emisProvider.overrideWith((ref) async {
            requests++;
            return [_emi('id', 'Loan', 100, DateTime.now().day)];
          }),
          expensesProvider.overrideWith((ref) async => const []),
        ],
        child: const _DashboardApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(requests, 1);

    final refreshIndicator = tester.widget<RefreshIndicator>(
      find.byType(RefreshIndicator),
    );
    await refreshIndicator.onRefresh();
    await tester.pumpAndSettle();

    expect(requests, greaterThan(1));
  });

  testWidgets('Dashboard tab selection does not invalidate loaded providers', (
    tester,
  ) async {
    var expenseRequests = 0;
    var emiRequests = 0;
    var summaryRequests = 0;
    final router = GoRouter(
      initialLocation: '/dashboard',
      routes: [
        ShellRoute(
          builder: (context, state, child) => MainLayout(child: child),
          routes: [
            GoRoute(
              path: '/dashboard',
              builder: (context, state) => const DashboardPage(),
            ),
            GoRoute(
              path: '/profile',
              builder: (context, state) => Builder(
                builder: (context) => Scaffold(
                  body: TextButton(
                    onPressed: () => context.push('/emis'),
                    child: const Text('Open EMI tracker'),
                  ),
                ),
              ),
            ),
          ],
        ),
        GoRoute(
          path: '/emis',
          builder: (context, state) => Scaffold(
            body: TextButton(
              onPressed: () => context.pop(),
              child: const Text('Back to profile'),
            ),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          selectedFinancePeriodProvider.overrideWith(_FixedPeriodNotifier.new),
          monthlyFinancialSummaryProvider(_period).overrideWith((ref) async {
            summaryRequests++;
            return _summary();
          }),
          emisProvider.overrideWith((ref) async {
            emiRequests++;
            return [_emi('loan', 'Loan', 100, DateTime.now().day)];
          }),
          expensesProvider.overrideWith((ref) async {
            expenseRequests++;
            return const [];
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
    expect(emiRequests, 1);
    expect(expenseRequests, 1);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open EMI tracker'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Back to profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dashboard'));
    await tester.pumpAndSettle();

    expect(summaryRequests, 1);
    expect(emiRequests, 1);
    expect(expenseRequests, 2);

    final requestsAfterReturn = (summaryRequests, emiRequests, expenseRequests);
    await tester.tap(find.text('Dashboard'));
    await tester.pumpAndSettle();
    expect((
      summaryRequests,
      emiRequests,
      expenseRequests,
    ), requestsAfterReturn);
  });
}

EmiModel _emi(String id, String title, double amount, int dueDay) =>
    EmiModel(id: id, title: title, amount: amount, dueDateDay: dueDay);

Future<void> _pumpDashboard(WidgetTester tester, List<EmiModel> emis) =>
    _pumpDashboardFuture(tester, Future.value(emis));

Future<void> _pumpDashboardFuture(
  WidgetTester tester,
  Future<List<EmiModel>> emis,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        selectedFinancePeriodProvider.overrideWith(_FixedPeriodNotifier.new),
        monthlyFinancialSummaryProvider(_period)
            .overrideWith((ref) async => _summary()),
        emisProvider.overrideWith((ref) => emis),
        expensesProvider.overrideWith((ref) async => const []),
      ],
      child: const _DashboardApp(),
    ),
  );
  await tester.pumpAndSettle();
}

class _DashboardApp extends StatelessWidget {
  const _DashboardApp();

  @override
  Widget build(BuildContext context) => const MaterialApp(
    home: DashboardPage(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
  );
}

class _FixedPeriodNotifier extends SelectedFinancePeriodNotifier {
  @override
  FinancePeriod build() => _period;
}

MonthlyFinancialSummary _summary() => MonthlyFinancialSummary.fromJson({
  'month': 11,
  'year': 2026,
  'baseMonthlySalary': 100000,
  'openingCarryForwardBalance': 0,
  'additionalFundsReceived': 0,
  'borrowedFundsReceived': 0,
  'totalEligibleActualExpenses': 0,
  'salaryFundedExpenses': 0,
  'additionalFundsUsed': 0,
  'carryForwardUsed': 0,
  'borrowedFundsUsed': 0,
  'totalAllocatedExpenses': 0,
  'remainingSalaryAvailable': 100000,
  'remainingCarryForwardAvailable': 0,
  'remainingAdditionalFundsAvailable': 0,
  'remainingBorrowedFundsAvailable': 0,
  'totalAvailableFunding': 100000,
  'unfundedOverspending': 0,
  'monthlyEmiScheduledAmount': 0,
  'nextEmiDueDate': null,
  'nextEmiPaymentStatus': null,
});
