import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaasutracker/core/localization/generated/app_localizations.dart';
import 'package:kaasutracker/features/emis/data/emi_model.dart';
import 'package:kaasutracker/features/emis/data/emis_provider.dart';
import 'package:kaasutracker/features/emis/presentation/emi_screen.dart';

void main() {
  testWidgets('status toggle confirms deactivation and refreshes the EMI', (
    tester,
  ) async {
    var active = true;
    final repository = _RecordingEmiRepository(
      onStatus: (value) async {
        active = value;
      },
    );

    await _pumpScreen(
      tester,
      repository: repository,
      emis: () => [_emi(isActive: active)],
    );

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(find.text('Deactivate EMI?'), findsOneWidget);
    expect(find.textContaining('Test loan'), findsWidgets);

    await tester.tap(find.text('Deactivate').last);
    await tester.pumpAndSettle();

    expect(repository.statusUpdates, [false]);
    expect(find.text('Inactive'), findsOneWidget);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(repository.statusUpdates, [false, true]);
    expect(find.text('Active'), findsOneWidget);
  });

  testWidgets('failed status update preserves current state and shows error', (
    tester,
  ) async {
    final repository = _RecordingEmiRepository(
      onStatus: (_) async => throw StateError('offline'),
    );

    await _pumpScreen(tester, repository: repository, emis: () => [_emi()]);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Deactivate').last);
    await tester.pumpAndSettle();

    expect(find.text('Active'), findsOneWidget);
    expect(
      find.text('Could not update EMI status. Please try again.'),
      findsOneWidget,
    );
  });

  testWidgets('add form submits selected duration and date', (tester) async {
    final repository = _RecordingEmiRepository();
    await _pumpScreen(tester, repository: repository, emis: () => const []);

    await tester.tap(find.text('Add EMI'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'New loan');
    await tester.enterText(find.byType(TextFormField).at(1), '2400');
    expect(find.text('12 months'), findsOneWidget);
    expect(find.textContaining('Start date:'), findsOneWidget);
    await tester.tap(find.text('Save EMI'));
    await tester.pumpAndSettle();

    expect(repository.addedTitle, 'New loan');
    expect(repository.addedDuration, 12);
    expect(repository.addedStartDate, isNotNull);
  });

  testWidgets('add form rejects missing title, amount, and custom duration', (
    tester,
  ) async {
    final repository = _RecordingEmiRepository();
    await _pumpScreen(tester, repository: repository, emis: () => const []);

    await tester.tap(find.text('Add EMI'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save EMI'));
    await tester.pumpAndSettle();
    expect(find.text('Please enter a title for the EMI.'), findsOneWidget);
    expect(find.text('Please enter a valid positive amount.'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'Loan');
    await tester.enterText(find.byType(TextFormField).at(1), '1200');
    await tester.ensureVisible(find.text('12 months'));
    await tester.tap(find.text('12 months'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Custom duration').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save EMI'));
    await tester.tap(find.text('Save EMI'));
    await tester.pumpAndSettle();
    expect(
      find.text('Enter a positive whole number of months.'),
      findsOneWidget,
    );
    expect(repository.addedTitle, isNull);
  });

  testWidgets('shows persisted installment progress and completed status', (
    tester,
  ) async {
    await _pumpScreen(
      tester,
      repository: _RecordingEmiRepository(),
      emis: () => [
        EmiModel(
          id: 'completed',
          title: 'Paid loan',
          amount: 1500,
          dueDateDay: 15,
          isActive: false,
          startDate: DateTime(2024, 1, 1),
          durationMonths: 24,
          endDate: DateTime(2025, 12, 31),
          totalInstallments: 24,
          paidInstallments: 24,
          remainingInstallments: 0,
          status: 'COMPLETED',
        ),
      ],
    );

    expect(find.text('Completed'), findsOneWidget);
    expect(
      find.text('24 of 24 installments paid · 0 remaining'),
      findsOneWidget,
    );
    expect(find.text('24 months'), findsOneWidget);
    expect(find.textContaining('Start date:'), findsOneWidget);
    expect(find.textContaining('End date:'), findsOneWidget);
    expect(find.byType(Switch), findsNothing);
  });
}

Future<void> _pumpScreen(
  WidgetTester tester, {
  required _RecordingEmiRepository repository,
  required List<EmiModel> Function() emis,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        emisProvider.overrideWith((ref) async => emis()),
        emiRepositoryProvider.overrideWithValue(repository),
      ],
      child: const MaterialApp(
        home: EmiScreen(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

EmiModel _emi({bool isActive = true}) => EmiModel(
  id: 'loan-1',
  title: 'Test loan',
  amount: 1000,
  dueDateDay: 10,
  isActive: isActive,
);

class _RecordingEmiRepository implements EmiRepository {
  _RecordingEmiRepository({this.onStatus});

  final Future<void> Function(bool)? onStatus;
  final List<bool> statusUpdates = [];
  String? addedTitle;
  int? addedDuration;
  DateTime? addedStartDate;

  @override
  Future<void> updateEmiStatus({
    required String id,
    required bool isActive,
  }) async {
    statusUpdates.add(isActive);
    await onStatus?.call(isActive);
  }

  @override
  Future<void> addEmi({
    required String title,
    required double amount,
    required int dueDateDay,
    required DateTime startDate,
    required int durationMonths,
  }) async {
    addedTitle = title;
    addedStartDate = startDate;
    addedDuration = durationMonths;
  }
}
