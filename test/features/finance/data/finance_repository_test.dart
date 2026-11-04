import 'dart:convert';
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kaasutracker/core/network/api_service.dart';
import 'package:kaasutracker/features/finance/data/finance_models.dart';
import 'package:kaasutracker/features/finance/data/finance_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  late List<http.Request> requests;
  late FinanceRepository repository;
  late MockClient client;

  setUp(() {
    requests = [];
    client = MockClient((request) async {
      requests.add(request);
      if (request.method == 'GET' &&
          request.url.path.endsWith('/finance/monthly-summary')) {
        return http.Response(
          jsonEncode(_summaryJson(request.url.queryParameters)),
          200,
        );
      }
      if (request.method == 'GET' &&
          request.url.path.endsWith('/additional-funds')) {
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
      if (request.method == 'GET' &&
          request.url.path.endsWith('/finance/carry-forward')) {
        return http.Response(
          jsonEncode({
            'id': 12,
            'year': 2026,
            'month': 10,
            'openingBalance': 200.00,
            'calculatedEligibleClosingBalance': 500.00,
            'monthlySummary': _summaryJson({'year': '2026', 'month': '10'}),
          }),
          200,
        );
      }
      if (request.method == 'POST' &&
          request.url.path.endsWith('/finance/carry-forward')) {
        return http.Response(
          jsonEncode({
            'id': 12,
            'year': 2026,
            'month': 10,
            'openingBalance': 200.00,
            'calculatedEligibleClosingBalance': 500.00,
            'monthlySummary': _summaryJson({'year': '2026', 'month': '10'}),
          }),
          200,
        );
      }
      if (request.method == 'POST' &&
          (request.url.path.endsWith('/additional-funds') ||
              request.url.path.endsWith('/borrowed-funds'))) {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode({'id': 9, ...body, 'status': 'AVAILABLE'}),
          201,
        );
      }
      if (request.method == 'PUT' &&
          request.url.path.endsWith('/expenses/31/funding')) {
        return http.Response(
          jsonEncode([
            {
              'id': 1,
              'fundingSource': 'SALARY',
              'sourceId': null,
              'amount': 40.25,
            },
          ]),
          200,
        );
      }
      if (request.method == 'GET' &&
          request.url.path.endsWith('/expenses/31/funding')) {
        return http.Response('[]', 200);
      }
      return http.Response('', 204);
    });
    final api = ApiService(
      client: client,
      supabase: SupabaseClient('http://localhost:54321', 'test-anon-key'),
      baseUrl: Uri.parse('http://localhost:8080/api/v1/'),
      accessTokenProvider: () => 'test-token',
    );
    repository = FinanceRepository(api);
  });

  tearDown(() => client.close());

  test('requests the selected monthly summary and parses its DTO', () async {
    final summary = await repository.getMonthlySummary(
      const FinancePeriod(year: 2026, month: 10),
    );

    expect(requests.single.method, 'GET');
    expect(requests.single.url.path, '/api/v1/finance/monthly-summary');
    expect(requests.single.url.queryParameters, {
      'year': '2026',
      'month': '10',
    });
    expect(summary.month, 10);
    expect(summary.year, 2026);
    expect(summary.totalEligibleActualExpenses, 5500000);
    expect(summary.salaryFundedExpenses, 5000000);
    expect(summary.carryForwardUsed, 300000);
    expect(summary.borrowedFundsUsed, 200000);
    expect(summary.unfundedOverspending, 0);
    expect(summary.remainingBorrowedFundsAvailable, 300000);
    expect(summary.totalRemainingFunding, 300000);
  });

  test(
    'returns an empty monthly summary without synthesizing balances',
    () async {
      final emptyClient = MockClient((request) async {
        requests.add(request);
        return http.Response(
          jsonEncode({
            'month': 11,
            'year': 2026,
            'baseMonthlySalary': 0,
            'openingCarryForwardBalance': 0,
            'additionalFundsReceived': 0,
            'borrowedFundsReceived': 0,
            'totalEligibleActualExpenses': 0,
            'salaryFundedExpenses': 0,
            'additionalFundsUsed': 0,
            'carryForwardUsed': 0,
            'borrowedFundsUsed': 0,
            'totalAllocatedExpenses': 0,
            'remainingSalaryAvailable': 0,
            'remainingCarryForwardAvailable': 0,
            'remainingAdditionalFundsAvailable': 0,
            'remainingBorrowedFundsAvailable': 0,
            'totalAvailableFunding': 0,
            'unfundedOverspending': 0,
            'monthlyEmiScheduledAmount': 0,
            'nextEmiDueDate': null,
            'nextEmiPaymentStatus': null,
          }),
          200,
        );
      });
      final emptyRepository = FinanceRepository(
        ApiService(
          client: emptyClient,
          supabase: SupabaseClient('http://localhost:54321', 'test-anon-key'),
          baseUrl: Uri.parse('http://localhost:8080/api/v1/'),
          accessTokenProvider: () => 'test-token',
        ),
      );
      addTearDown(emptyClient.close);

      final result = await emptyRepository.getMonthlySummary(
        const FinancePeriod(year: 2026, month: 11),
      );

      expect(result.baseMonthlySalary, 0);
      expect(result.totalEligibleActualExpenses, 0);
      expect(result.totalRemainingFunding, 0);
      expect(result.nextEmiDueDate, isNull);
      expect(requests, hasLength(1));
    },
  );

  test('rejects a summary returned for a different month', () async {
    final mismatchedClient = MockClient(
      (request) async => http.Response(
        jsonEncode(_summaryJson({'year': '2026', 'month': '10'})),
        200,
      ),
    );
    final mismatchedRepository = FinanceRepository(
      ApiService(
        client: mismatchedClient,
        supabase: SupabaseClient('http://localhost:54321', 'test-anon-key'),
        baseUrl: Uri.parse('http://localhost:8080/api/v1/'),
        accessTokenProvider: () => 'test-token',
      ),
    );
    addTearDown(mismatchedClient.close);

    await expectLater(
      mismatchedRepository.getMonthlySummary(
        const FinancePeriod(year: 2026, month: 11),
      ),
      throwsA(isA<FormatException>()),
    );
  });

  test('preserves a monthly summary HTTP error for UI handling', () async {
    final unavailableClient = MockClient(
      (request) async => http.Response('temporarily unavailable', 503),
    );
    final unavailableRepository = FinanceRepository(
      ApiService(
        client: unavailableClient,
        supabase: SupabaseClient('http://localhost:54321', 'test-anon-key'),
        baseUrl: Uri.parse('http://localhost:8080/api/v1/'),
        accessTokenProvider: () => 'test-token',
      ),
    );
    addTearDown(unavailableClient.close);

    await expectLater(
      unavailableRepository.getMonthlySummary(
        const FinancePeriod(year: 2026, month: 11),
      ),
      throwsA(
        isA<ApiException>().having(
          (error) => error.statusCode,
          'statusCode',
          503,
        ),
      ),
    );
  });

  for (final statusCode in [401, 403, 404, 500]) {
    test('preserves monthly summary HTTP $statusCode errors', () async {
      var requestsMade = 0;
      final failingClient = MockClient((request) async {
        requestsMade++;
        return http.Response('{"message":"request failed"}', statusCode);
      });
      final failingRepository = FinanceRepository(
        ApiService(
          client: failingClient,
          supabase: SupabaseClient('http://localhost:54321', 'test-anon-key'),
          baseUrl: Uri.parse('http://localhost:8080/api/v1/'),
          accessTokenProvider: () => 'test-token',
        ),
      );
      addTearDown(failingClient.close);

      await expectLater(
        failingRepository.getMonthlySummary(
          const FinancePeriod(year: 2026, month: 11),
        ),
        throwsA(
          isA<ApiException>().having(
            (error) => error.statusCode,
            'statusCode',
            statusCode,
          ),
        ),
      );
      expect(requestsMade, 1);
    });
  }

  test('malformed monthly summary response fails parsing', () async {
    final malformedClient = MockClient(
      (request) async => http.Response('{"month":11,"year":2026}', 200),
    );
    final malformedRepository = FinanceRepository(
      ApiService(
        client: malformedClient,
        supabase: SupabaseClient('http://localhost:54321', 'test-anon-key'),
        baseUrl: Uri.parse('http://localhost:8080/api/v1/'),
        accessTokenProvider: () => 'test-token',
      ),
    );
    addTearDown(malformedClient.close);

    await expectLater(
      malformedRepository.getMonthlySummary(
        const FinancePeriod(year: 2026, month: 11),
      ),
      throwsA(isA<FormatException>()),
    );
  });

  test(
    'malformed JSON from monthly summary is not treated as empty data',
    () async {
      final malformedClient = MockClient(
        (request) async => http.Response('<html>bad gateway</html>', 200),
      );
      final malformedRepository = FinanceRepository(
        ApiService(
          client: malformedClient,
          supabase: SupabaseClient('http://localhost:54321', 'test-anon-key'),
          baseUrl: Uri.parse('http://localhost:8080/api/v1/'),
          accessTokenProvider: () => 'test-token',
        ),
      );
      addTearDown(malformedClient.close);

      await expectLater(
        malformedRepository.getMonthlySummary(
          const FinancePeriod(year: 2026, month: 11),
        ),
        throwsA(isA<FormatException>()),
      );
    },
  );

  test('lists funds for the selected period', () async {
    await repository.getFunds(
      const FundQuery(
        type: FundType.additional,
        period: FinancePeriod(year: 2026, month: 10),
      ),
    );

    expect(requests.single.method, 'GET');
    expect(requests.single.url.path, '/api/v1/additional-funds');
    expect(requests.single.url.queryParameters, {
      'year': '2026',
      'month': '10',
    });
  });

  test('creates a fund using the backend FundRequest fields', () async {
    final fund = await repository.saveFund(
      type: FundType.additional,
      amount: 12050,
      fundDate: DateTime(2026, 10, 3),
      sourceDescription: '  Gift ',
    );
    final requestBody =
        jsonDecode(requests.single.body) as Map<String, dynamic>;

    expect(requests.single.method, 'POST');
    expect(requests.single.url.path, '/api/v1/additional-funds');
    expect(requestBody, {
      'amount': 120.5,
      'fundDate': '2026-10-03',
      'sourceDescription': 'Gift',
    });
    expect(fund.id, 9);
    expect(fund.amount, 12050);
  });

  test('records borrowed-fund purpose and repayment balance fields', () async {
    await repository.saveFund(
      type: FundType.borrowed,
      amount: 25000,
      fundDate: DateTime(2026, 10, 4),
      sourceDescription: 'Friend',
      purpose: 'Emergency',
      outstandingRepaymentBalance: 20000,
    );
    final requestBody =
        jsonDecode(requests.single.body) as Map<String, dynamic>;

    expect(requests.single.url.path, '/api/v1/borrowed-funds');
    expect(requestBody, {
      'amount': 250.0,
      'fundDate': '2026-10-04',
      'sourceDescription': 'Friend',
      'purpose': 'Emergency',
      'outstandingRepaymentBalance': 200.0,
    });
  });

  test('saves monthly salary using the backend year/month DTO', () async {
    await repository.saveMonthlySalary(
      period: const FinancePeriod(year: 2026, month: 10),
      amount: 5000000,
    );
    final body = jsonDecode(requests.single.body) as Map<String, dynamic>;

    expect(requests.single.method, 'PUT');
    expect(requests.single.url.path, '/api/v1/finance/monthly-salary');
    expect(body, {'year': 2026, 'month': 10, 'amount': 50000.0});
  });

  test(
    'establishes carry-forward with query parameters and no fabricated DTO',
    () async {
      final result = await repository.establishCarryForward(
        const FinancePeriod(year: 2026, month: 10),
      );

      expect(requests.single.method, 'POST');
      expect(requests.single.url.path, '/api/v1/finance/carry-forward');
      expect(requests.single.url.queryParameters, {
        'year': '2026',
        'month': '10',
      });
      expect(requests.single.body, isEmpty);
      expect(result.id, 12);
      expect(result.monthlySummary!.year, 2026);
    },
  );

  test(
    'replaces expense allocations using API enum and sourceId fields',
    () async {
      final allocations = await repository.replaceExpenseFunding(
        expenseId: 31,
        allocations: const [
          ExpenseFundingAllocationInput(
            fundingSource: FundingSource.salary,
            sourceId: null,
            amount: 4025,
          ),
        ],
      );
      final body = jsonDecode(requests.single.body) as Map<String, dynamic>;

      expect(requests.single.method, 'PUT');
      expect(requests.single.url.path, '/api/v1/expenses/31/funding');
      expect(body, {
        'allocations': [
          {'fundingSource': 'SALARY', 'sourceId': null, 'amount': 40.25},
        ],
      });
      expect(allocations.single.amount, 4025);
    },
  );

  test(
    'loads current expense allocations using the funding response DTO',
    () async {
      final fundingClient = MockClient((request) async {
        requests.add(request);
        return http.Response(
          jsonEncode([
            {
              'id': 14,
              'fundingSource': 'SALARY',
              'sourceId': null,
              'amount': 30.25,
            },
            {
              'id': 15,
              'fundingSource': 'ADDITIONAL',
              'sourceId': 9,
              'amount': 69.75,
            },
          ]),
          200,
        );
      });
      final fundingRepository = FinanceRepository(
        ApiService(
          client: fundingClient,
          supabase: SupabaseClient('http://localhost:54321', 'test-anon-key'),
          baseUrl: Uri.parse('http://localhost:8080/api/v1/'),
          accessTokenProvider: () => 'test-token',
        ),
      );
      addTearDown(fundingClient.close);

      final allocations = await fundingRepository.getExpenseFunding(31);

      expect(requests.single.method, 'GET');
      expect(requests.single.url.path, '/api/v1/expenses/31/funding');
      expect(allocations, hasLength(2));
      expect(allocations[0].fundingSource, FundingSource.salary);
      expect(allocations[0].sourceId, isNull);
      expect(allocations[0].amount, 3025);
      expect(allocations[1].fundingSource, FundingSource.additional);
      expect(allocations[1].sourceId, 9);
      expect(allocations[1].amount, 6975);
    },
  );

  test(
    'period-specific summary requests remain isolated when responses race',
    () async {
      final pending = <String, Completer<http.Response>>{};
      final racingClient = MockClient((request) {
        final month = request.url.queryParameters['month']!;
        final completer = Completer<http.Response>();
        pending[month] = completer;
        return completer.future;
      });
      final racingRepository = FinanceRepository(
        ApiService(
          client: racingClient,
          supabase: SupabaseClient('http://localhost:54321', 'test-anon-key'),
          baseUrl: Uri.parse('http://localhost:8080/api/v1/'),
          accessTokenProvider: () => 'test-token',
        ),
      );
      final container = ProviderContainer(
        overrides: [
          financeRepositoryProvider.overrideWithValue(racingRepository),
        ],
      );
      addTearDown(() {
        container.dispose();
        racingClient.close();
      });
      final october = container.read(
        monthlyFinancialSummaryProvider(
          const FinancePeriod(year: 2026, month: 10),
        ).future,
      );
      final november = container.read(
        monthlyFinancialSummaryProvider(
          const FinancePeriod(year: 2026, month: 11),
        ).future,
      );
      await Future<void>.delayed(Duration.zero);

      pending['11']!.complete(
        http.Response(
          jsonEncode(_summaryJson({'year': '2026', 'month': '11'})),
          200,
        ),
      );
      pending['10']!.complete(
        http.Response(
          jsonEncode(_summaryJson({'year': '2026', 'month': '10'})),
          200,
        ),
      );

      expect((await november).month, 11);
      expect((await october).month, 10);
    },
  );

  test(
    'getExpenseFunding propagates 404 as API integration error',
    () async {
      final failingClient = MockClient((request) async {
        return http.Response('{"message":"not found"}', 404);
      });
      final failingRepository = FinanceRepository(
        ApiService(
          client: failingClient,
          supabase: SupabaseClient('http://localhost:54321', 'test-anon-key'),
          baseUrl: Uri.parse('http://localhost:8080/api/v1/'),
          accessTokenProvider: () => 'test-token',
        ),
      );
      addTearDown(failingClient.close);

      await expectLater(
        failingRepository.getExpenseFunding(31),
        throwsA(
          isA<ApiException>().having(
            (error) => error.statusCode,
            'statusCode',
            404,
          ),
        ),
      );
    },
  );

  test(
    'getFunds returns empty collection when backend returns no additional funds',
    () async {
      final emptyClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'funds': [],
            'totalReceived': 0,
            'totalUsed': 0,
            'remainingAvailable': 0,
          }),
          200,
        );
      });
      final emptyRepository = FinanceRepository(
        ApiService(
          client: emptyClient,
          supabase: SupabaseClient('http://localhost:54321', 'test-anon-key'),
          baseUrl: Uri.parse('http://localhost:8080/api/v1/'),
          accessTokenProvider: () => 'test-token',
        ),
      );
      addTearDown(emptyClient.close);

      final result = await emptyRepository.getFunds(
        const FundQuery(
          type: FundType.additional,
          period: FinancePeriod(year: 2026, month: 10),
        ),
      );

      expect(result.funds, isEmpty);
      expect(result.totalReceived, 0);
      expect(result.totalUsed, 0);
      expect(result.remainingAvailable, 0);
    },
  );

  test(
    'getFunds propagates 404 on additional-funds as API integration error',
    () async {
      final failingClient = MockClient((request) async {
        return http.Response('{"message":"not found"}', 404);
      });
      final failingRepository = FinanceRepository(
        ApiService(
          client: failingClient,
          supabase: SupabaseClient('http://localhost:54321', 'test-anon-key'),
          baseUrl: Uri.parse('http://localhost:8080/api/v1/'),
          accessTokenProvider: () => 'test-token',
        ),
      );
      addTearDown(failingClient.close);

      await expectLater(
        failingRepository.getFunds(
          const FundQuery(
            type: FundType.additional,
            period: FinancePeriod(year: 2026, month: 10),
          ),
        ),
        throwsA(
          isA<ApiException>().having(
            (error) => error.statusCode,
            'statusCode',
            404,
          ),
        ),
      );
    },
  );
}

Map<String, Object?> _summaryJson(Map<String, String> query) => {
  'month': int.parse(query['month']!),
  'year': int.parse(query['year']!),
  'baseMonthlySalary': 50000.00,
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
  'totalAvailableFunding': 58000.00,
  'unfundedOverspending': 0,
  'monthlyEmiScheduledAmount': 0,
  'nextEmiDueDate': null,
  'nextEmiPaymentStatus': null,
};
