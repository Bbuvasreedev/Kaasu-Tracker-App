import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaasutracker/core/network/api_service.dart';
import 'package:kaasutracker/features/expenses/data/expense.dart';
import 'package:kaasutracker/features/expenses/data/expenses_provider.dart';
import 'package:kaasutracker/features/finance/data/finance_models.dart';
import 'package:kaasutracker/features/finance/data/finance_repository.dart';

class FundingOption {
  const FundingOption({
    required this.source,
    required this.sourceId,
    required this.label,
    required this.available,
    required this.assigned,
  });

  final FundingSource source;
  final int? sourceId;
  final String? label;
  final int available;
  final int assigned;
}

class ExpenseFundingContext {
  const ExpenseFundingContext({
    required this.expenseId,
    required this.expense,
    required this.period,
    required this.summary,
    required this.allocations,
    required this.options,
  });

  final int expenseId;
  final Expense expense;
  final FinancePeriod period;
  final MonthlyFinancialSummary summary;
  final List<ExpenseFundingAllocation> allocations;
  final List<FundingOption> options;
}

final expenseFundingContextProvider =
    FutureProvider.family<ExpenseFundingContext, int>((ref, expenseId) async {
      final expensesFuture = ref.watch(expensesProvider.future);
      final allocationsFuture = ref.watch(
        expenseFundingProvider(expenseId).future,
      );
      final repository = ref.watch(financeRepositoryProvider);
      final expenses = await expensesFuture;
      final matches = expenses.where((item) => item.id == '$expenseId');
      final expense = matches.isEmpty ? null : matches.first;
      if (expense == null) {
        throw StateError('Expense $expenseId is not available.');
      }

      final period = FinancePeriod.fromDate(expense.expenseDate);
      final summaryFuture = ref.watch(
        monthlyFinancialSummaryProvider(period).future,
      );
      final carryForwardFuture = ref.watch(carryForwardProvider(period).future);
      final additionalFuture = ref.watch(
        fundCollectionProvider(
          FundQuery(type: FundType.additional, period: period),
        ).future,
      );
      final borrowedFuture = ref.watch(
        fundCollectionProvider(
          FundQuery(type: FundType.borrowed, period: period),
        ).future,
      );

      final expensesThisMonth = expenses.where(
        (item) =>
            item.isConfirmed &&
            item.expenseDate.year == period.year &&
            item.expenseDate.month == period.month,
      );
      final allocationsByExpenseFuture = Future.wait(
        expensesThisMonth.map((item) async {
          final id = int.tryParse(item.id);
          if (id == null) {
            throw FormatException('Expense ID "${item.id}" is not numeric.');
          }
          if (id == expenseId) {
            return allocationsFuture;
          }
          try {
            return await repository.getExpenseFunding(id);
          } on ApiException catch (error) {
            if (error.statusCode == 404) {
              return <ExpenseFundingAllocation>[];
            }
            rethrow;
          }
        }),
      );
      final results = await Future.wait<Object>([
        summaryFuture,
        carryForwardFuture,
        additionalFuture,
        borrowedFuture,
        allocationsFuture,
        allocationsByExpenseFuture,
      ]);
      final summary = results[0] as MonthlyFinancialSummary;
      final carryForward = results[1] as CarryForwardBalance;
      final additionalFunds = results[2] as FundCollection;
      final borrowedFunds = results[3] as FundCollection;
      final currentAllocations = results[4] as List<ExpenseFundingAllocation>;
      final allAllocations =
          (results[5] as List<List<ExpenseFundingAllocation>>).expand(
            (items) => items,
          );
      final amountsUsedBySource = <String, int>{};
      for (final allocation in allAllocations) {
        final key =
            '${allocation.fundingSource.apiValue}:${allocation.sourceId ?? ''}';
        amountsUsedBySource.update(
          key,
          (amount) => amount + allocation.amount,
          ifAbsent: () => allocation.amount,
        );
      }
      final currentAmounts = <String, int>{};
      for (final allocation in currentAllocations) {
        final key =
            '${allocation.fundingSource.apiValue}:${allocation.sourceId ?? ''}';
        currentAmounts.update(
          key,
          (amount) => amount + allocation.amount,
          ifAbsent: () => allocation.amount,
        );
      }

      int sourceBalance(FundingSource source, int? id, int total) {
        final key = '${source.apiValue}:${id ?? ''}';
        return (total -
                (amountsUsedBySource[key] ?? 0) +
                (currentAmounts[key] ?? 0))
            .clamp(0, total)
            .toInt();
      }

      final options = <FundingOption>[
        FundingOption(
          source: FundingSource.salary,
          sourceId: null,
          label: null,
          available: sourceBalance(
            FundingSource.salary,
            null,
            summary.baseMonthlySalary,
          ),
          assigned: currentAmounts['SALARY:'] ?? 0,
        ),
        if (carryForward.id != null)
          FundingOption(
            source: FundingSource.carryForward,
            sourceId: carryForward.id,
            label: null,
            available: sourceBalance(
              FundingSource.carryForward,
              carryForward.id,
              carryForward.openingBalance,
            ),
            assigned: currentAmounts['CARRY_FORWARD:${carryForward.id}'] ?? 0,
          ),
        ...additionalFunds.funds
            .where(
              (fund) =>
                  fund.status == 'AVAILABLE' ||
                  (currentAmounts['ADDITIONAL:${fund.id}'] ?? 0) > 0,
            )
            .map((fund) {
              final assigned = currentAmounts['ADDITIONAL:${fund.id}'] ?? 0;
              final isAvailable = fund.status == 'AVAILABLE';
              return FundingOption(
                source: FundingSource.additional,
                sourceId: fund.id,
                label: '${fund.sourceDescription} · #${fund.id}',
                available: isAvailable
                    ? sourceBalance(
                        FundingSource.additional,
                        fund.id,
                        fund.amount,
                      )
                    : 0,
                assigned: assigned,
              );
            }),
        ...borrowedFunds.funds
            .where(
              (fund) =>
                  fund.status == 'AVAILABLE' ||
                  (currentAmounts['BORROWED:${fund.id}'] ?? 0) > 0,
            )
            .map((fund) {
              final assigned = currentAmounts['BORROWED:${fund.id}'] ?? 0;
              final isAvailable = fund.status == 'AVAILABLE';
              return FundingOption(
                source: FundingSource.borrowed,
                sourceId: fund.id,
                label: '${fund.sourceDescription} · #${fund.id}',
                available: isAvailable
                    ? sourceBalance(
                        FundingSource.borrowed,
                        fund.id,
                        fund.amount,
                      )
                    : 0,
                assigned: assigned,
              );
            }),
      ];

      return ExpenseFundingContext(
        expenseId: expenseId,
        expense: expense,
        period: period,
        summary: summary,
        allocations: currentAllocations,
        options: options,
      );
    }, retry: (retryCount, error) => null);
