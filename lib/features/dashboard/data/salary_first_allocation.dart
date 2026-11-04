class SalaryFirstAllocation {
  const SalaryFirstAllocation({
    required this.totalExpenses,
    required this.salaryAvailable,
    required this.carryForwardAvailable,
    required this.borrowedFundsAvailable,
    required this.salaryUsed,
    required this.carryForwardUsed,
    required this.borrowedFundsUsed,
    required this.unfundedOverspending,
  });

  final double totalExpenses;
  final double salaryAvailable;
  final double carryForwardAvailable;
  final double borrowedFundsAvailable;
  final double salaryUsed;
  final double carryForwardUsed;
  final double borrowedFundsUsed;
  final double unfundedOverspending;

  double get additionalFundsAvailable =>
      carryForwardAvailable + borrowedFundsAvailable;

  double get additionalFundsUsed => carryForwardUsed + borrowedFundsUsed;

  double get salaryRemaining => salaryAvailable - salaryUsed;

  double get salaryUtilization =>
      salaryAvailable == 0 ? 0 : salaryUsed / salaryAvailable;

  double get additionalFundsUtilization => additionalFundsAvailable == 0
      ? 0
      : additionalFundsUsed / additionalFundsAvailable;

  factory SalaryFirstAllocation.calculate({
    required double totalExpenses,
    required double salaryAvailable,
    double carryForwardAvailable = 0,
    double borrowedFundsAvailable = 0,
  }) {
    final expenses = _nonNegativeFinite(totalExpenses);
    final salary = _nonNegativeFinite(salaryAvailable);
    final carryForward = _nonNegativeFinite(carryForwardAvailable);
    final borrowed = _nonNegativeFinite(borrowedFundsAvailable);

    final salaryUsed = expenses < salary ? expenses : salary;
    final excessAfterSalary = expenses - salaryUsed;
    final carryForwardUsed = excessAfterSalary < carryForward
        ? excessAfterSalary
        : carryForward;
    final excessAfterCarryForward = excessAfterSalary - carryForwardUsed;
    final borrowedUsed = excessAfterCarryForward < borrowed
        ? excessAfterCarryForward
        : borrowed;

    return SalaryFirstAllocation(
      totalExpenses: expenses,
      salaryAvailable: salary,
      carryForwardAvailable: carryForward,
      borrowedFundsAvailable: borrowed,
      salaryUsed: salaryUsed,
      carryForwardUsed: carryForwardUsed,
      borrowedFundsUsed: borrowedUsed,
      unfundedOverspending: excessAfterCarryForward - borrowedUsed,
    );
  }
}

double _nonNegativeFinite(double value) =>
    value.isFinite && value > 0 ? value : 0;
