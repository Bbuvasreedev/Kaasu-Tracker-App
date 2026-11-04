class FinancePeriod {
  const FinancePeriod({required this.year, required this.month});

  factory FinancePeriod.fromDate(DateTime date) =>
      FinancePeriod(year: date.year, month: date.month);

  final int year;
  final int month;

  DateTime get firstDay => DateTime(year, month);

  Map<String, int> get queryParameters => {'year': year, 'month': month};

  @override
  bool operator ==(Object other) =>
      other is FinancePeriod && other.year == year && other.month == month;

  @override
  int get hashCode => Object.hash(year, month);
}

int parseMinorUnits(Object? value, {required String field}) {
  if (value is! num && value is! String) {
    throw FormatException('$field must be a monetary value.');
  }
  final text = value.toString().trim();
  final match = RegExp(r'^([+-]?)(\d+)(?:\.(\d{1,2}))?$').firstMatch(text);
  if (match == null) {
    throw FormatException('$field must have at most two decimal places.');
  }
  final sign = match.group(1) == '-' ? -1 : 1;
  final whole = BigInt.parse(match.group(2)!);
  final fractional = (match.group(3) ?? '').padRight(2, '0');
  final minor = whole * BigInt.from(100) + BigInt.parse(fractional);
  final signedMinor = sign == -1 ? -minor : minor;
  if (signedMinor < BigInt.from(-9007199254740991) ||
      signedMinor > BigInt.from(9007199254740991)) {
    throw FormatException('$field exceeds the supported monetary range.');
  }
  return signedMinor.toInt();
}

double minorUnitsToApiAmount(int amountMinorUnits) => amountMinorUnits / 100;

class MonthlyFinancialSummary {
  const MonthlyFinancialSummary({
    required this.month,
    required this.year,
    required this.baseMonthlySalary,
    required this.openingCarryForwardBalance,
    required this.additionalFundsReceived,
    required this.borrowedFundsReceived,
    required this.totalEligibleActualExpenses,
    required this.salaryFundedExpenses,
    required this.additionalFundsUsed,
    required this.carryForwardUsed,
    required this.borrowedFundsUsed,
    required this.totalAllocatedExpenses,
    required this.remainingSalaryAvailable,
    required this.remainingCarryForwardAvailable,
    required this.remainingAdditionalFundsAvailable,
    required this.remainingBorrowedFundsAvailable,
    required this.totalAvailableFunding,
    required this.unfundedOverspending,
    required this.monthlyEmiScheduledAmount,
    required this.nextEmiDueDate,
    required this.nextEmiPaymentStatus,
  });

  final int month;
  final int year;
  final int baseMonthlySalary;
  final int openingCarryForwardBalance;
  final int additionalFundsReceived;
  final int borrowedFundsReceived;
  final int totalEligibleActualExpenses;
  final int salaryFundedExpenses;
  final int additionalFundsUsed;
  final int carryForwardUsed;
  final int borrowedFundsUsed;
  final int totalAllocatedExpenses;
  final int remainingSalaryAvailable;
  final int remainingCarryForwardAvailable;
  final int remainingAdditionalFundsAvailable;
  final int remainingBorrowedFundsAvailable;
  final int totalAvailableFunding;
  final int unfundedOverspending;
  final int monthlyEmiScheduledAmount;
  final DateTime? nextEmiDueDate;
  final String? nextEmiPaymentStatus;

  int get totalRemainingFunding =>
      remainingSalaryAvailable +
      remainingCarryForwardAvailable +
      remainingAdditionalFundsAvailable +
      remainingBorrowedFundsAvailable;

  factory MonthlyFinancialSummary.fromJson(Map<String, dynamic> json) {
    int amount(String key) => parseMinorUnits(json[key], field: key);
    final month = json['month'];
    final year = json['year'];
    if (month is! num || year is! num) {
      throw const FormatException('Monthly summary requires month and year.');
    }

    final nextDateValue = json['nextEmiDueDate'];
    if (nextDateValue != null && nextDateValue is! String) {
      throw const FormatException('nextEmiDueDate must be an ISO-8601 date.');
    }
    final status = json['nextEmiPaymentStatus'];
    if (status != null && status is! String) {
      throw const FormatException('nextEmiPaymentStatus must be a string.');
    }

    return MonthlyFinancialSummary(
      month: month.toInt(),
      year: year.toInt(),
      baseMonthlySalary: amount('baseMonthlySalary'),
      openingCarryForwardBalance: amount('openingCarryForwardBalance'),
      additionalFundsReceived: amount('additionalFundsReceived'),
      borrowedFundsReceived: amount('borrowedFundsReceived'),
      totalEligibleActualExpenses: amount('totalEligibleActualExpenses'),
      salaryFundedExpenses: amount('salaryFundedExpenses'),
      additionalFundsUsed: amount('additionalFundsUsed'),
      carryForwardUsed: amount('carryForwardUsed'),
      borrowedFundsUsed: amount('borrowedFundsUsed'),
      totalAllocatedExpenses: amount('totalAllocatedExpenses'),
      remainingSalaryAvailable: amount('remainingSalaryAvailable'),
      remainingCarryForwardAvailable: amount('remainingCarryForwardAvailable'),
      remainingAdditionalFundsAvailable: amount(
        'remainingAdditionalFundsAvailable',
      ),
      remainingBorrowedFundsAvailable: amount(
        'remainingBorrowedFundsAvailable',
      ),
      totalAvailableFunding: amount('totalAvailableFunding'),
      unfundedOverspending: amount('unfundedOverspending'),
      monthlyEmiScheduledAmount: amount('monthlyEmiScheduledAmount'),
      nextEmiDueDate: nextDateValue == null
          ? null
          : DateTime.parse(nextDateValue).toLocal(),
      nextEmiPaymentStatus: status as String?,
    );
  }
}

class FundRecord {
  const FundRecord({
    required this.id,
    required this.amount,
    required this.fundDate,
    required this.sourceDescription,
    required this.status,
    this.purpose,
    this.outstandingRepaymentBalance,
  });

  final int id;
  final int amount;
  final DateTime fundDate;
  final String sourceDescription;
  final String? purpose;
  final int? outstandingRepaymentBalance;
  final String status;

  factory FundRecord.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final date = json['fundDate'];
    final source = json['sourceDescription'];
    final purpose = json['purpose'];
    final status = json['status'];
    if (id is! num ||
        date is! String ||
        source is! String ||
        status is! String) {
      throw const FormatException('Fund record is missing required fields.');
    }
    if (purpose != null && purpose is! String) {
      throw const FormatException('Fund purpose must be a string.');
    }
    final outstanding = json['outstandingRepaymentBalance'];
    return FundRecord(
      id: id.toInt(),
      amount: parseMinorUnits(json['amount'], field: 'amount'),
      fundDate: DateTime.parse(date),
      sourceDescription: source,
      purpose: purpose as String?,
      outstandingRepaymentBalance: outstanding == null
          ? null
          : parseMinorUnits(outstanding, field: 'outstandingRepaymentBalance'),
      status: status,
    );
  }
}

class FundCollection {
  const FundCollection({
    required this.funds,
    required this.totalReceived,
    required this.totalUsed,
    required this.remainingAvailable,
  });

  final List<FundRecord> funds;
  final int totalReceived;
  final int totalUsed;
  final int remainingAvailable;

  factory FundCollection.fromJson(Map<String, dynamic> json) {
    final rawFunds = json['funds'];
    if (rawFunds is! List) {
      throw const FormatException('Fund collection requires a funds list.');
    }
    return FundCollection(
      funds: rawFunds
          .map((item) {
            if (item is! Map<String, dynamic>) {
              throw const FormatException('Fund entry must be a JSON object.');
            }
            return FundRecord.fromJson(item);
          })
          .toList(growable: false),
      totalReceived: parseMinorUnits(
        json['totalReceived'],
        field: 'totalReceived',
      ),
      totalUsed: parseMinorUnits(json['totalUsed'], field: 'totalUsed'),
      remainingAvailable: parseMinorUnits(
        json['remainingAvailable'],
        field: 'remainingAvailable',
      ),
    );
  }
}

class CarryForwardBalance {
  const CarryForwardBalance({
    required this.id,
    required this.year,
    required this.month,
    required this.openingBalance,
    required this.calculatedEligibleClosingBalance,
    this.monthlySummary,
  });

  final int? id;
  final int year;
  final int month;
  final int openingBalance;
  final int calculatedEligibleClosingBalance;
  final MonthlyFinancialSummary? monthlySummary;

  factory CarryForwardBalance.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final year = json['year'];
    final month = json['month'];
    final summaryValue = json['monthlySummary'];
    if ((id != null && id is! num) || year is! num || month is! num) {
      throw const FormatException('Carry-forward response is malformed.');
    }
    if (summaryValue != null && summaryValue is! Map<String, dynamic>) {
      throw const FormatException('monthlySummary must be an object.');
    }
    return CarryForwardBalance(
      id: (id as num?)?.toInt(),
      year: year.toInt(),
      month: month.toInt(),
      openingBalance: parseMinorUnits(
        json['openingBalance'],
        field: 'openingBalance',
      ),
      calculatedEligibleClosingBalance: parseMinorUnits(
        json['calculatedEligibleClosingBalance'],
        field: 'calculatedEligibleClosingBalance',
      ),
      monthlySummary: summaryValue == null
          ? null
          : MonthlyFinancialSummary.fromJson(summaryValue),
    );
  }
}

enum FundingSource {
  salary('SALARY'),
  carryForward('CARRY_FORWARD'),
  additional('ADDITIONAL'),
  borrowed('BORROWED');

  const FundingSource(this.apiValue);
  final String apiValue;

  static FundingSource parse(Object? value) => FundingSource.values.firstWhere(
    (source) => source.apiValue == value,
    orElse: () => throw FormatException('Unknown funding source: $value'),
  );
}

class ExpenseFundingAllocation {
  const ExpenseFundingAllocation({
    required this.id,
    required this.fundingSource,
    required this.sourceId,
    required this.amount,
  });

  final int id;
  final FundingSource fundingSource;
  final int? sourceId;
  final int amount;

  factory ExpenseFundingAllocation.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final sourceId = json['sourceId'];
    if (id is! num || (sourceId != null && sourceId is! num)) {
      throw const FormatException(
        'Funding allocation identifiers are invalid.',
      );
    }
    return ExpenseFundingAllocation(
      id: id.toInt(),
      fundingSource: FundingSource.parse(json['fundingSource']),
      sourceId: (sourceId as num?)?.toInt(),
      amount: parseMinorUnits(json['amount'], field: 'amount'),
    );
  }
}
