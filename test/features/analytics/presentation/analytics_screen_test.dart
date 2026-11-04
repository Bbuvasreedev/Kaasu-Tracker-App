import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaasutracker/core/localization/generated/app_localizations.dart';
import 'package:kaasutracker/core/network/api_service.dart';
import 'package:kaasutracker/features/analytics/presentation/analytics_screen.dart';
import 'package:kaasutracker/features/expenses/data/expense.dart';
import 'package:kaasutracker/features/expenses/data/expenses_provider.dart';
import 'package:kaasutracker/features/finance/data/finance_models.dart';
import 'package:kaasutracker/features/finance/data/finance_repository.dart';

const _november = FinancePeriod(year: 2026, month: 11);

void main() {
  testWidgets('Analytics displays provider expenses for the selected month', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          selectedFinancePeriodProvider.overrideWith(_NovemberNotifier.new),
          expensesProvider.overrideWith(
            (ref) async => [
              _expense('oct', '2026-10-25', 300),
              _expense('nov', '2026-11-25', 125),
            ],
          ),
        ],
        child: const _LocalizedAnalyticsApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('November 2026'), findsOneWidget);
    expect(find.textContaining('125.00'), findsNWidgets(2));
    expect(find.textContaining('300.00'), findsNothing);
    expect(find.text('Food'), findsOneWidget);
  });

  testWidgets('an empty provider result shows the localized empty state', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          selectedFinancePeriodProvider.overrideWith(_NovemberNotifier.new),
          expensesProvider.overrideWith((ref) async => const <Expense>[]),
        ],
        child: const _LocalizedAnalyticsApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No expenses this month'), findsOneWidget);
    expect(find.text('Retry'), findsNothing);
  });

  testWidgets('an API failure is shown as an error with retry, not empty', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          selectedFinancePeriodProvider.overrideWith(_NovemberNotifier.new),
          expensesProvider.overrideWith((ref) async {
            throw const ApiException(
              statusCode: 500,
              message: 'private detail',
            );
          }),
        ],
        child: const _LocalizedAnalyticsApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Could not load analytics'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('No expenses this month'), findsNothing);
    expect(find.text('private detail'), findsNothing);
  });

  testWidgets('authentication failures use the localized session message', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          selectedFinancePeriodProvider.overrideWith(_NovemberNotifier.new),
          expensesProvider.overrideWith((ref) async {
            throw const ApiAuthenticationException();
          }),
        ],
        child: const _LocalizedAnalyticsApp(),
      ),
    );
    await tester.pumpAndSettle();

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l10n.serverSessionExpired), findsOneWidget);
    expect(find.text('No expenses this month'), findsNothing);
  });

  testWidgets('switching locale keeps the selected month expenses visible', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          selectedFinancePeriodProvider.overrideWith(_NovemberNotifier.new),
          expensesProvider.overrideWith(
            (ref) async => [_expense('nov', '2026-11-25', 125)],
          ),
        ],
        child: const _LocaleSwitchingApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('125.00'), findsNWidgets(2));
    final english = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(english.analyticsTitle), findsOneWidget);

    await tester.tap(find.text('Switch language'));
    await tester.pumpAndSettle();

    expect(find.textContaining('125.00'), findsNWidgets(2));
    final telugu = await AppLocalizations.delegate.load(const Locale('te'));
    expect(find.text(telugu.analyticsTitle), findsOneWidget);
    expect(find.text('ఈ నెల ఖర్చులు లేవు'), findsNothing);
  });
}

Expense _expense(String id, String date, double amount) => Expense(
  id: id,
  amount: amount,
  category: 'Food',
  description: 'Groceries',
  expenseDate: DateTime.parse(date),
);

class _NovemberNotifier extends SelectedFinancePeriodNotifier {
  @override
  FinancePeriod build() => _november;
}

class _LocalizedAnalyticsApp extends StatelessWidget {
  const _LocalizedAnalyticsApp();

  @override
  Widget build(BuildContext context) => const MaterialApp(
    home: AnalyticsScreen(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
  );
}

class _LocaleSwitchingApp extends StatefulWidget {
  const _LocaleSwitchingApp();

  @override
  State<_LocaleSwitchingApp> createState() => _LocaleSwitchingAppState();
}

class _LocaleSwitchingAppState extends State<_LocaleSwitchingApp> {
  Locale _locale = const Locale('en');

  @override
  Widget build(BuildContext context) => MaterialApp(
    locale: _locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: Column(
        children: [
          TextButton(
            onPressed: () => setState(() => _locale = const Locale('te')),
            child: const Text('Switch language'),
          ),
          const Expanded(child: AnalyticsScreen()),
        ],
      ),
    ),
  );
}
