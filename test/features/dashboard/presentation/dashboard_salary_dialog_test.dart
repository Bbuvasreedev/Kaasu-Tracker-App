import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kaasutracker/core/localization/generated/app_localizations.dart';
import 'package:kaasutracker/core/network/api_service.dart';
import 'package:kaasutracker/features/dashboard/presentation/dashboard_page.dart';
import 'package:kaasutracker/features/emis/data/emis_provider.dart';
import 'package:kaasutracker/features/expenses/data/expenses_provider.dart';
import 'package:kaasutracker/features/finance/data/finance_models.dart';
import 'package:kaasutracker/features/finance/data/finance_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _period = FinancePeriod(year: 2026, month: 10);

void main() {
  testWidgets('Cancel closes salary dialog without saving', (tester) async {
    final requests = <http.Request>[];
    final harness = await _pumpDashboard(tester, (request) async {
      requests.add(request);
      return http.Response('', 204);
    });

    await _openSalaryDialog(tester);
    expect(
      tester.widget<TextFormField>(find.byType(TextFormField)).controller!.text,
      '50000.00',
    );
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(requests, isEmpty);
    expect(tester.takeException(), isNull);
    harness.dispose();
  });

  testWidgets(
    'saving updates salary and reopening uses the latest saved value',
    (tester) async {
      var salary = 500;
      final requests = <http.Request>[];
      final harness = await _pumpDashboard(tester, (request) async {
        requests.add(request);
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        salary = (body['amount'] as num).toInt();
        return http.Response('', 204);
      }, currentSalary: () => salary);

      await _openSalaryDialog(tester);
      await tester.enterText(find.byType(TextFormField), '600.00');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(requests, hasLength(1));
      expect(requests.single.method, 'PUT');
      expect(requests.single.url.path, '/api/v1/finance/monthly-salary');
      expect(jsonDecode(requests.single.body), {
        'year': 2026,
        'month': 10,
        'amount': 600.0,
      });
      expect(find.text('Monthly salary saved.'), findsOneWidget);

      await _openSalaryDialog(tester);
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField))
            .controller!
            .text,
        '600.00',
      );
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      harness.dispose();
    },
  );

  testWidgets(
    'repeatedly opening and cancelling creates no disposed controller',
    (tester) async {
      final harness = await _pumpDashboard(
        tester,
        (_) async => http.Response('', 204),
      );

      for (var index = 0; index < 5; index++) {
        await _openSalaryDialog(tester);
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }

      expect(find.byType(AlertDialog), findsNothing);
      harness.dispose();
    },
  );

  testWidgets('disables Save and ignores repeated taps while saving', (
    tester,
  ) async {
    final pendingResponse = Completer<http.Response>();
    var requests = 0;
    final harness = await _pumpDashboard(tester, (_) {
      requests++;
      return pendingResponse.future;
    });

    await _openSalaryDialog(tester);
    await tester.enterText(find.byType(TextFormField), '725.00');
    await tester.tap(find.text('Save'));
    await tester.pump();

    final saveButton = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(saveButton.onPressed, isNull);
    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    expect(requests, 1);

    pendingResponse.complete(http.Response('', 204));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(requests, 1);
    expect(tester.takeException(), isNull);
    harness.dispose();
  });

  testWidgets(
    'rejects empty, negative, malformed and non-finite salary input',
    (tester) async {
      var requests = 0;
      final harness = await _pumpDashboard(tester, (_) async {
        requests++;
        return http.Response('', 204);
      });

      await _openSalaryDialog(tester);
      for (final input in ['', '-1', 'abc', 'NaN', 'Infinity']) {
        await tester.enterText(find.byType(TextFormField), input);
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();
        expect(
          find.text('Please enter a valid salary amount.'),
          findsOneWidget,
        );
        expect(requests, 0);
        expect(find.byType(AlertDialog), findsOneWidget);
      }
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      harness.dispose();
    },
  );

  testWidgets('save failure keeps salary dialog and entered value for retry', (
    tester,
  ) async {
    var shouldFail = true;
    final requests = <http.Request>[];
    final harness = await _pumpDashboard(tester, (request) async {
      requests.add(request);
      if (shouldFail) {
        return http.Response('{"message":"Salary update failed"}', 500);
      }
      return http.Response('', 204);
    });

    await _openSalaryDialog(tester);
    await tester.enterText(find.byType(TextFormField), '725.00');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(
      find.text('The service is temporarily unavailable. Please try again.'),
      findsOneWidget,
    );
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(
      tester.widget<TextFormField>(find.byType(TextFormField)).controller!.text,
      '725.00',
    );
    expect(find.text('Monthly salary saved.'), findsNothing);

    shouldFail = false;
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(requests, hasLength(2));
    expect(find.byType(AlertDialog), findsNothing);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.text('Monthly salary saved.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    harness.dispose();
  });
}

Future<void> _openSalaryDialog(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Fund sources'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Set monthly salary'));
  await tester.pumpAndSettle();
}

Future<_Harness> _pumpDashboard(
  WidgetTester tester,
  Future<http.Response> Function(http.Request) handler, {
  int Function()? currentSalary,
}) async {
  final client = MockClient(handler);
  final api = ApiService(
    client: client,
    supabase: SupabaseClient(
      'http://localhost:54321',
      'test-anon-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    ),
    baseUrl: Uri.parse('http://localhost:8080/api/v1/'),
    accessTokenProvider: () => 'test-token',
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        selectedFinancePeriodProvider.overrideWith(_FixedPeriodNotifier.new),
        monthlyFinancialSummaryProvider(
          _period,
        ).overrideWith((ref) async => _summary(currentSalary?.call() ?? 50000)),
        financeRepositoryProvider.overrideWithValue(FinanceRepository(api)),
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
  return _Harness(client);
}

class _Harness {
  const _Harness(this.client);

  final MockClient client;

  void dispose() => client.close();
}

class _FixedPeriodNotifier extends SelectedFinancePeriodNotifier {
  @override
  FinancePeriod build() => _period;
}

MonthlyFinancialSummary _summary(int salary) =>
    MonthlyFinancialSummary.fromJson({
      'month': 10,
      'year': 2026,
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
