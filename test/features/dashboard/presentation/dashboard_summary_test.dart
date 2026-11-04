import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaasutracker/core/localization/generated/app_localizations.dart';
import 'package:kaasutracker/core/network/api_service.dart';
import 'package:kaasutracker/features/dashboard/presentation/dashboard_page.dart';
import 'package:kaasutracker/features/emis/data/emis_provider.dart';
import 'package:kaasutracker/features/expenses/data/expenses_provider.dart';
import 'package:kaasutracker/features/finance/data/finance_models.dart';
import 'package:kaasutracker/features/finance/data/finance_repository.dart';

void main() {
  const period = FinancePeriod(year: 2026, month: 10);
  final summary = MonthlyFinancialSummary.fromJson({
    'month': 10,
    'year': 2026,
    'baseMonthlySalary': 50000,
    'openingCarryForwardBalance': 3000,
    'additionalFundsReceived': 0,
    'borrowedFundsReceived': 5000,
    'totalEligibleActualExpenses': 55000,
    'salaryFundedExpenses': 50000,
    'additionalFundsUsed': 0,
    'carryForwardUsed': 3000,
    'borrowedFundsUsed': 2000,
    'totalAllocatedExpenses': 55000,
    'remainingSalaryAvailable': 0,
    'remainingCarryForwardAvailable': 0,
    'remainingAdditionalFundsAvailable': 0,
    'remainingBorrowedFundsAvailable': 3000,
    'totalAvailableFunding': 58000,
    'unfundedOverspending': 0,
    'monthlyEmiScheduledAmount': 4000,
    'nextEmiDueDate': '2026-10-30',
    'nextEmiPaymentStatus': 'PAYMENT_NOT_TRACKED',
  });

  testWidgets('dashboard displays backend allocation and source balances', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          selectedFinancePeriodProvider.overrideWith(
            _FixedFinancePeriodNotifier.new,
          ),
          monthlyFinancialSummaryProvider(period)
              .overrideWith((ref) async => summary),
          emisProvider.overrideWith((ref) async => const []),
          expensesProvider.overrideWith((ref) async => const []),
        ],
        child: const MaterialApp(
          home: DashboardPage(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Additional funds used'), findsNothing);
    expect(find.text('Salary spent'), findsNothing);
    expect(find.text('Carry-forward used'), findsOneWidget);
    expect(find.text('Borrowed funds used'), findsOneWidget);
    expect(find.text('Actual expenses'), findsWidgets);
    expect(find.text('Total remaining funds'), findsOneWidget);
    expect(find.text('Unfunded overspending'), findsNothing);
    expect(find.textContaining('₹50,000.00'), findsNWidgets(2));
    expect(find.textContaining('₹3,000.00'), findsNWidgets(3));
    expect(find.textContaining('₹2,000.00'), findsOneWidget);
    expect(find.textContaining('₹55,000.00'), findsOneWidget);
    expect(find.textContaining('₹0.00'), findsNWidgets(3));
    expect(find.text('Additional funds available: ₹0.00'), findsOneWidget);
  });

  testWidgets('dashboard shows only backend-reported uncovered overspending', (
    tester,
  ) async {
    final overspentSummary = MonthlyFinancialSummary.fromJson({
      'month': 10,
      'year': 2026,
      'baseMonthlySalary': 50000,
      'openingCarryForwardBalance': 3000,
      'additionalFundsReceived': 0,
      'borrowedFundsReceived': 5000,
      'totalEligibleActualExpenses': 62000,
      'salaryFundedExpenses': 50000,
      'additionalFundsUsed': 0,
      'carryForwardUsed': 3000,
      'borrowedFundsUsed': 5000,
      'totalAllocatedExpenses': 58000,
      'remainingSalaryAvailable': 0,
      'remainingCarryForwardAvailable': 0,
      'remainingAdditionalFundsAvailable': 0,
      'remainingBorrowedFundsAvailable': 0,
      'totalAvailableFunding': 58000,
      'unfundedOverspending': 4000,
      'monthlyEmiScheduledAmount': 3000,
      'nextEmiDueDate': '2026-10-30',
      'nextEmiPaymentStatus': 'PAYMENT_NOT_TRACKED',
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          selectedFinancePeriodProvider.overrideWith(
            _FixedFinancePeriodNotifier.new,
          ),
          monthlyFinancialSummaryProvider(period)
              .overrideWith((ref) async => overspentSummary),
          emisProvider.overrideWith((ref) async => const []),
          expensesProvider.overrideWith((ref) async => const []),
        ],
        child: const MaterialApp(
          home: DashboardPage(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Unfunded overspending'), findsOneWidget);
    expect(find.textContaining('₹4,000.00'), findsOneWidget);
    expect(find.textContaining('₹0.00'), findsWidgets);
  });

  testWidgets('summary API errors do not render zero-valued finance data', (
    tester,
  ) async {
    var requests = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          selectedFinancePeriodProvider.overrideWith(
            _FixedFinancePeriodNotifier.new,
          ),
          monthlyFinancialSummaryProvider(period).overrideWith((ref) async {
            requests++;
            throw const FormatException('Malformed finance summary');
          }),
          emisProvider.overrideWith((ref) async => const []),
          expensesProvider.overrideWith((ref) async => const []),
        ],
        child: const MaterialApp(
          home: DashboardPage(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Monthly summary could not be loaded.'), findsOneWidget);
    expect(find.text('EMI schedule'), findsOneWidget);
    expect(find.text('Recent Expenses'), findsOneWidget);
    expect(
      find.text('The request could not be completed. Please try again.'),
      findsOneWidget,
    );
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(requests, 1);
    expect(find.text('₹0.00'), findsNothing);
    expect(find.text('Actual expenses'), findsNothing);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(requests, 2);
    expect(find.text('Monthly summary could not be loaded.'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('retry recovers the summary after a temporary API failure', (
    tester,
  ) async {
    var requests = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          selectedFinancePeriodProvider.overrideWith(
            _FixedFinancePeriodNotifier.new,
          ),
          monthlyFinancialSummaryProvider(period).overrideWith((ref) async {
            requests++;
            if (requests == 1) {
              throw const ApiException(
                statusCode: 503,
                message: 'Temporary unavailable',
              );
            }
            return summary;
          }),
          emisProvider.overrideWith((ref) async => const []),
          expensesProvider.overrideWith((ref) async => const []),
        ],
        child: const MaterialApp(
          home: DashboardPage(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('The service is temporarily unavailable. Please try again.'),
      findsOneWidget,
    );
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(requests, 1);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(requests, 2);
    expect(find.text('₹50,000.00'), findsNWidgets(2));
    expect(find.text('Monthly summary could not be loaded.'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('unconfigured salary has a setup message, not fabricated data', (
    tester,
  ) async {
    final noSalary = _summaryFor(period, salary: 0);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          selectedFinancePeriodProvider.overrideWith(
            _FixedFinancePeriodNotifier.new,
          ),
          monthlyFinancialSummaryProvider(period)
              .overrideWith((ref) async => noSalary),
          emisProvider.overrideWith((ref) async => const []),
          expensesProvider.overrideWith((ref) async => const []),
        ],
        child: const MaterialApp(
          home: DashboardPage(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Monthly salary is not configured. Set it from the funds menu.',
      ),
      findsOneWidget,
    );
    expect(find.text('No financial activity for this month.'), findsOneWidget);
    expect(find.text('₹0.00'), findsWidgets);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('selecting another month requests that month summary', (
    tester,
  ) async {
    final requests = <FinancePeriod>[];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          selectedFinancePeriodProvider.overrideWith(_OctoberNotifier.new),
          monthlyFinancialSummaryProvider.overrideWith((ref, period) async {
            requests.add(period);
            return _summaryFor(period);
          }),
          emisProvider.overrideWith((ref) async => const []),
          expensesProvider.overrideWith((ref) async => const []),
        ],
        child: const MaterialApp(
          home: DashboardPage(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(requests, [const FinancePeriod(year: 2026, month: 10)]);

    await tester.tap(find.byTooltip('Next month'));
    await tester.pumpAndSettle();

    expect(requests, [
      const FinancePeriod(year: 2026, month: 10),
      const FinancePeriod(year: 2026, month: 11),
    ]);
    expect(find.text('November 2026'), findsWidgets);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('overflow menu does not include Additional funds', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          selectedFinancePeriodProvider.overrideWith(
            _FixedFinancePeriodNotifier.new,
          ),
          monthlyFinancialSummaryProvider(period)
              .overrideWith((ref) async => summary),
          emisProvider.overrideWith((ref) async => const []),
          expensesProvider.overrideWith((ref) async => const []),
        ],
        child: const MaterialApp(
          home: DashboardPage(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Fund sources'));
    await tester.pumpAndSettle();

    expect(find.text('Additional funds'), findsNothing);
    expect(find.text('Borrowed funds'), findsOneWidget);
    expect(find.text('Establish carry-forward'), findsOneWidget);
    expect(find.text('Set monthly salary'), findsOneWidget);
  });
}

class _FixedFinancePeriodNotifier extends SelectedFinancePeriodNotifier {
  @override
  FinancePeriod build() => const FinancePeriod(year: 2026, month: 10);
}

class _OctoberNotifier extends SelectedFinancePeriodNotifier {
  @override
  FinancePeriod build() => const FinancePeriod(year: 2026, month: 10);
}

MonthlyFinancialSummary _summaryFor(
  FinancePeriod period, {
  int salary = 50000,
}) {
  return MonthlyFinancialSummary.fromJson({
    'month': period.month,
    'year': period.year,
    'baseMonthlySalary': salary,
    'openingCarryForwardBalance': 0,
    'additionalFundsReceived': 0,
    'borrowedFundsReceived': 0,
    'totalEligibleActualExpenses': 0,
    'salaryFundedExpenses': 0,
    'additionalFundsUsed': 0,
    'carryForwardUsed': 0,
    'borrowedFundsUsed': 0,
    'totalAllocatedExpenses': 0,
    'remainingSalaryAvailable': salary,
    'remainingCarryForwardAvailable': 0,
    'remainingAdditionalFundsAvailable': 0,
    'remainingBorrowedFundsAvailable': 0,
    'totalAvailableFunding': salary,
    'unfundedOverspending': 0,
    'monthlyEmiScheduledAmount': 0,
    'nextEmiDueDate': null,
    'nextEmiPaymentStatus': null,
  });
}
