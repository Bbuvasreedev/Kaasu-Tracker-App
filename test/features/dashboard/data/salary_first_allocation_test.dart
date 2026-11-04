import 'package:flutter_test/flutter_test.dart';
import 'package:kaasutracker/features/dashboard/data/salary_first_allocation.dart';

void main() {
  group('salary-first allocation', () {
    test('expenses below salary are allocated only to salary', () {
      final result = SalaryFirstAllocation.calculate(
        totalExpenses: 30000,
        salaryAvailable: 50000,
        carryForwardAvailable: 10000,
        borrowedFundsAvailable: 5000,
      );

      expect(result.salaryUsed, 30000);
      expect(result.salaryUtilization, 0.6);
      expect(result.additionalFundsUsed, 0);
      expect(result.salaryRemaining, 20000);
    });

    test('expenses equal to salary consume exactly the salary budget', () {
      final result = SalaryFirstAllocation.calculate(
        totalExpenses: 50000,
        salaryAvailable: 50000,
        carryForwardAvailable: 10000,
        borrowedFundsAvailable: 5000,
      );

      expect(result.salaryUsed, 50000);
      expect(result.salaryUtilization, 1);
      expect(result.additionalFundsUsed, 0);
      expect(result.salaryRemaining, 0);
    });

    test('expenses above salary use carry-forward before borrowed funds', () {
      final result = SalaryFirstAllocation.calculate(
        totalExpenses: 60000,
        salaryAvailable: 50000,
        carryForwardAvailable: 6000,
        borrowedFundsAvailable: 5000,
      );

      expect(result.salaryUsed, 50000);
      expect(result.salaryUtilization, 1);
      expect(result.carryForwardUsed, 6000);
      expect(result.borrowedFundsUsed, 4000);
      expect(result.additionalFundsUsed, 10000);
      expect(result.unfundedOverspending, 0);
      expect(result.borrowedFundsAvailable - result.borrowedFundsUsed, 1000);
    });

    test('reports overspending beyond all available funds', () {
      final result = SalaryFirstAllocation.calculate(
        totalExpenses: 60000,
        salaryAvailable: 50000,
        carryForwardAvailable: 3000,
        borrowedFundsAvailable: 2000,
      );

      expect(result.salaryUsed, 50000);
      expect(result.additionalFundsUsed, 5000);
      expect(result.unfundedOverspending, 5000);
    });

    test('zero or missing salary never causes division by zero', () {
      final result = SalaryFirstAllocation.calculate(
        totalExpenses: 250,
        salaryAvailable: 0,
      );

      expect(result.salaryUtilization, 0);
      expect(result.salaryRemaining, 0);
      expect(result.additionalFundsUsed, 0);
      expect(result.unfundedOverspending, 250);
    });

    test('negative and non-finite funds are not treated as available', () {
      final result = SalaryFirstAllocation.calculate(
        totalExpenses: 100,
        salaryAvailable: double.nan,
        carryForwardAvailable: -50,
        borrowedFundsAvailable: double.infinity,
      );

      expect(result.salaryAvailable, 0);
      expect(result.additionalFundsAvailable, 0);
      expect(result.unfundedOverspending, 100);
    });
  });
}
