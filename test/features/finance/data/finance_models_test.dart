import 'package:flutter_test/flutter_test.dart';
import 'package:kaasutracker/features/finance/data/finance_models.dart';

void main() {
  test(
    'parses exact backend monthly summary amounts and nullable EMI data',
    () {
      final summary = MonthlyFinancialSummary.fromJson({
        'month': 10,
        'year': 2026,
        'baseMonthlySalary': 50000.25,
        'openingCarryForwardBalance': 1000.50,
        'additionalFundsReceived': 250.75,
        'borrowedFundsReceived': 100.00,
        'totalEligibleActualExpenses': 2000.20,
        'salaryFundedExpenses': 1500.10,
        'additionalFundsUsed': 100.05,
        'carryForwardUsed': 200.00,
        'borrowedFundsUsed': 50.05,
        'totalAllocatedExpenses': 1850.20,
        'remainingSalaryAvailable': 48500.15,
        'remainingCarryForwardAvailable': 800.50,
        'remainingAdditionalFundsAvailable': 150.70,
        'remainingBorrowedFundsAvailable': 49.95,
        'totalAvailableFunding': 51351.50,
        'unfundedOverspending': 150.00,
        'monthlyEmiScheduledAmount': 5000.00,
        'nextEmiDueDate': '2026-10-30',
        'nextEmiPaymentStatus': 'PAYMENT_NOT_TRACKED',
      });

      expect(summary.month, 10);
      expect(summary.year, 2026);
      expect(summary.baseMonthlySalary, 5000025);
      expect(summary.totalEligibleActualExpenses, 200020);
      expect(summary.remainingSalaryAvailable, 4850015);
      expect(summary.borrowedFundsUsed, 5005);
      expect(summary.unfundedOverspending, 15000);
      expect(summary.totalRemainingFunding, 4950130);
      expect(summary.nextEmiDueDate, DateTime(2026, 10, 30));
      expect(summary.nextEmiPaymentStatus, 'PAYMENT_NOT_TRACKED');
    },
  );

  test('parses an empty-month response without inventing values', () {
    final summary = MonthlyFinancialSummary.fromJson({
      'month': 2,
      'year': 2027,
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
    });

    expect(summary.totalEligibleActualExpenses, 0);
    expect(summary.nextEmiDueDate, isNull);
    expect(summary.nextEmiPaymentStatus, isNull);
  });

  test('parses fund collections and funding source allocation DTOs', () {
    final funds = FundCollection.fromJson({
      'funds': [
        {
          'id': 42,
          'amount': 125.25,
          'fundDate': '2026-10-03',
          'sourceDescription': 'Gift',
          'purpose': null,
          'outstandingRepaymentBalance': null,
          'status': 'AVAILABLE',
        },
      ],
      'totalReceived': 125.25,
      'totalUsed': 25.25,
      'remainingAvailable': 100.00,
    });
    final allocation = ExpenseFundingAllocation.fromJson({
      'id': 8,
      'fundingSource': 'ADDITIONAL',
      'sourceId': 42,
      'amount': 25.25,
    });

    expect(funds.funds.single.id, 42);
    expect(funds.totalReceived, 12525);
    expect(funds.totalUsed, 2525);
    expect(funds.remainingAvailable, 10000);
    expect(allocation.fundingSource, FundingSource.additional);
    expect(allocation.sourceId, 42);
    expect(allocation.amount, 2525);
  });

  test('parses money in minor units and rejects unsupported precision', () {
    expect(parseMinorUnits('123.40', field: 'test'), 12340);
    expect(parseMinorUnits(100, field: 'test'), 10000);
    expect(
      () => parseMinorUnits('1.001', field: 'test'),
      throwsFormatException,
    );
  });

  test('finance periods compare by selected year and month', () {
    expect(
      FinancePeriod(year: 2026, month: 10),
      FinancePeriod.fromDate(DateTime(2026, 10, 29)),
    );
    expect(FinancePeriod(year: 2025, month: 12).firstDay, DateTime(2025, 12));
  });
}
