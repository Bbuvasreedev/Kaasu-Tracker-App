import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:kaasutracker/core/localization/generated/app_localizations.dart';
import 'package:kaasutracker/core/network/api_service.dart';
import 'package:kaasutracker/features/finance/data/finance_models.dart';
import 'package:kaasutracker/features/finance/data/finance_repository.dart';
import 'package:kaasutracker/features/finance/presentation/fund_management_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  testWidgets('saving additional funds submits and refreshes the fund list', (
    tester,
  ) async {
    const period = FinancePeriod(year: 2026, month: 10);
    final query = FundQuery(type: FundType.additional, period: period);
    var listRequests = 0;
    final repository = _RecordingFinanceRepository(_unusedApiService());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          selectedFinancePeriodProvider.overrideWith(
            _FixedFinancePeriodNotifier.new,
          ),
          fundCollectionProvider(query).overrideWith((ref) async {
            listRequests++;
            return const FundCollection(
              funds: [],
              totalReceived: 0,
              totalUsed: 0,
              remainingAvailable: 0,
            );
          }),
          financeRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(
          home: FundManagementScreen(type: FundType.additional),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add funds'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), '12.30');
    await tester.enterText(find.byType(TextFormField).at(1), 'Gift');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(repository.savedType, FundType.additional);
    expect(repository.savedAmount, 1230);
    expect(repository.savedDescription, 'Gift');
    expect(listRequests, greaterThanOrEqualTo(2));
  });
}

class _FixedFinancePeriodNotifier extends SelectedFinancePeriodNotifier {
  @override
  FinancePeriod build() => const FinancePeriod(year: 2026, month: 10);
}

class _RecordingFinanceRepository extends FinanceRepository {
  _RecordingFinanceRepository(super.api);

  FundType? savedType;
  int? savedAmount;
  String? savedDescription;

  @override
  Future<FundRecord> saveFund({
    required FundType type,
    int? id,
    required int amount,
    required DateTime fundDate,
    required String sourceDescription,
    String? purpose,
    int? outstandingRepaymentBalance,
  }) async {
    savedType = type;
    savedAmount = amount;
    savedDescription = sourceDescription;
    return FundRecord(
      id: 1,
      amount: amount,
      fundDate: fundDate,
      sourceDescription: sourceDescription,
      status: 'AVAILABLE',
    );
  }
}

ApiService _unusedApiService() => ApiService(
  client: _FailingClient(),
  supabase: SupabaseClient(
    'http://localhost:54321',
    'test-anon-key',
    authOptions: const AuthClientOptions(autoRefreshToken: false),
  ),
  accessTokenProvider: () => 'test-token',
);

class _FailingClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async =>
      throw StateError('The test should not make API requests.');
}
