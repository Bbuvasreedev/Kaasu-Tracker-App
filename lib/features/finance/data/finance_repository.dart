import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:kaasutracker/core/network/api_service.dart';
import 'package:kaasutracker/features/auth/auth_provider.dart';
import 'package:kaasutracker/features/finance/data/finance_models.dart';

enum FundType {
  additional('additional-funds'),
  borrowed('borrowed-funds');

  const FundType(this.path);
  final String path;
}

class FundQuery {
  const FundQuery({required this.type, required this.period});

  final FundType type;
  final FinancePeriod period;

  @override
  bool operator ==(Object other) =>
      other is FundQuery && other.type == type && other.period == period;

  @override
  int get hashCode => Object.hash(type, period);
}

class FinanceRepository {
  FinanceRepository(this._api);

  final ApiService _api;

  Future<void> saveMonthlySalary({
    required FinancePeriod period,
    required int amount,
  }) async {
    await _api.put(
      'finance/monthly-salary',
      body: {
        'year': period.year,
        'month': period.month,
        'amount': minorUnitsToApiAmount(amount),
      },
    );
  }

  Future<MonthlyFinancialSummary> getMonthlySummary(
    FinancePeriod period,
  ) async {
    try {
      final response = await _api.get(
        'finance/monthly-summary',
        queryParameters: period.queryParameters,
      );
      final summary = MonthlyFinancialSummary.fromJson(_object(response));
      if (summary.month != period.month || summary.year != period.year) {
        throw const FormatException(
          'The monthly summary does not match the requested period.',
        );
      }
      return summary;
    } catch (error, stackTrace) {
      if (kDebugMode) {
        final status = error is ApiException
            ? ', status ${error.statusCode}'
            : '';
        debugPrint(
          'Monthly summary request failed for '
          '${period.year}-${period.month.toString().padLeft(2, '0')} '
          '(${error.runtimeType}$status).',
        );
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<FundCollection> getFunds(FundQuery query) async {
    final response = await _api.get(
      query.type.path,
      queryParameters: query.period.queryParameters,
    );
    return FundCollection.fromJson(_object(response));
  }

  Future<FundRecord> saveFund({
    required FundType type,
    int? id,
    required int amount,
    required DateTime fundDate,
    required String sourceDescription,
    String? purpose,
    int? outstandingRepaymentBalance,
  }) async {
    final payload = <String, Object?>{
      'amount': minorUnitsToApiAmount(amount),
      'fundDate': DateFormat('yyyy-MM-dd').format(fundDate),
      'sourceDescription': sourceDescription.trim(),
    };
    if (type == FundType.borrowed) {
      payload['purpose'] = purpose?.trim();
      if (outstandingRepaymentBalance != null) {
        payload['outstandingRepaymentBalance'] = minorUnitsToApiAmount(
          outstandingRepaymentBalance,
        );
      }
    }

    final response = id == null
        ? await _api.post(type.path, body: payload)
        : await _api.put('${type.path}/$id', body: payload);
    return FundRecord.fromJson(_object(response));
  }

  Future<void> deactivateFund(FundType type, int id) async {
    await _api.delete('${type.path}/$id');
  }

  Future<CarryForwardBalance> getCarryForward(FinancePeriod period) async {
    final response = await _api.get(
      'finance/carry-forward',
      queryParameters: period.queryParameters,
    );
    return CarryForwardBalance.fromJson(_object(response));
  }

  Future<CarryForwardBalance> establishCarryForward(
    FinancePeriod period,
  ) async {
    final response = await _api.postWithoutBody(
      'finance/carry-forward',
      queryParameters: period.queryParameters,
    );
    return CarryForwardBalance.fromJson(_object(response));
  }

  Future<List<ExpenseFundingAllocation>> getExpenseFunding(
    int expenseId,
  ) async {
    final response = await _api.get('expenses/$expenseId/funding');
    return _allocationList(response);
  }

  Future<List<ExpenseFundingAllocation>> replaceExpenseFunding({
    required int expenseId,
    required List<ExpenseFundingAllocationInput> allocations,
  }) async {
    final response = await _api.put(
      'expenses/$expenseId/funding',
      body: {
        'allocations': allocations
            .map(
              (allocation) => <String, Object?>{
                'fundingSource': allocation.fundingSource.apiValue,
                'sourceId': allocation.sourceId,
                'amount': minorUnitsToApiAmount(allocation.amount),
              },
            )
            .toList(growable: false),
      },
    );
    return _allocationList(response);
  }

  static Map<String, dynamic> _object(Object? response) {
    if (response is Map<String, dynamic>) return response;
    throw const FormatException('Expected an API response object.');
  }

  static List<ExpenseFundingAllocation> _allocationList(Object? response) {
    if (response is! List) {
      throw const FormatException(
        'Expected the funding endpoint to return a list.',
      );
    }
    return response
        .map((item) {
          if (item is! Map<String, dynamic>) {
            throw const FormatException(
              'Expected each funding allocation to be an object.',
            );
          }
          return ExpenseFundingAllocation.fromJson(item);
        })
        .toList(growable: false);
  }
}

class ExpenseFundingAllocationInput {
  const ExpenseFundingAllocationInput({
    required this.fundingSource,
    required this.sourceId,
    required this.amount,
  });

  final FundingSource fundingSource;
  final int? sourceId;
  final int amount;
}

final financeRepositoryProvider = Provider<FinanceRepository>((ref) {
  ref.watch(authStateStreamProvider);
  return FinanceRepository(ref.watch(apiServiceProvider));
});

class SelectedFinancePeriodNotifier extends Notifier<FinancePeriod> {
  @override
  FinancePeriod build() => FinancePeriod.fromDate(DateTime.now());

  void select(FinancePeriod period) => state = period;
}

final selectedFinancePeriodProvider =
    NotifierProvider<SelectedFinancePeriodNotifier, FinancePeriod>(
      SelectedFinancePeriodNotifier.new,
    );

final monthlyFinancialSummaryProvider =
    FutureProvider.family<MonthlyFinancialSummary, FinancePeriod>(
      (ref, period) =>
          ref.watch(financeRepositoryProvider).getMonthlySummary(period),
      retry: (retryCount, error) => null,
    );

final fundCollectionProvider = FutureProvider.family<FundCollection, FundQuery>(
  (ref, query) => ref.watch(financeRepositoryProvider).getFunds(query),
);

final carryForwardProvider =
    FutureProvider.family<CarryForwardBalance, FinancePeriod>(
      (ref, period) =>
          ref.watch(financeRepositoryProvider).getCarryForward(period),
    );

final expenseFundingProvider =
    FutureProvider.family<List<ExpenseFundingAllocation>, int>(
      (ref, expenseId) =>
          ref.watch(financeRepositoryProvider).getExpenseFunding(expenseId),
      retry: (retryCount, error) => null,
    );
