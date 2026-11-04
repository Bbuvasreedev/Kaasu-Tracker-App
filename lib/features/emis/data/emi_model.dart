class EmiModel {
  const EmiModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.dueDateDay,
    this.isActive = true,
    this.startDate,
    this.durationMonths,
    this.endDate,
    this.status,
    this.totalInstallments,
    this.paidInstallments,
    this.remainingInstallments,
  });

  final String id;
  final String title;
  final double amount;
  final int dueDateDay;
  final bool isActive;
  final DateTime? startDate;
  final int? durationMonths;
  final DateTime? endDate;
  final String? status;
  final int? totalInstallments;
  final int? paidInstallments;
  final int? remainingInstallments;

  bool get isCompleted =>
      status?.toLowerCase() == 'completed' ||
      (totalInstallments != null &&
          totalInstallments! > 0 &&
          (remainingInstallments == 0 ||
              (paidInstallments != null &&
                  paidInstallments! >= totalInstallments!)));

  factory EmiModel.fromJson(Map<String, dynamic> json) {
    final amountValue = json['amount'];
    final dueDayValue = json['dueDateDay'] ?? json['dueDay'] ?? json['day'];
    final statusValue = json['status'];

    return EmiModel(
      id: json['id']?.toString() ?? '',
      title:
          json['title'] is String && (json['title'] as String).trim().isNotEmpty
          ? (json['title'] as String).trim()
          : 'EMI',
      amount: amountValue is num
          ? amountValue.toDouble()
          : amountValue is String
          ? double.tryParse(amountValue) ?? 0.0
          : 0.0,
      dueDateDay: dueDayValue is num
          ? dueDayValue.toInt()
          : dueDayValue is String
          ? int.tryParse(dueDayValue) ?? 1
          : 1,
      isActive: json['isActive'] is bool
          ? json['isActive'] as bool
          : json['active'] is bool
          ? json['active'] as bool
          : statusValue is String
          ? statusValue.toLowerCase() == 'active'
          : true,
      startDate: _dateFromJson(json['startDate']),
      durationMonths: _positiveIntFromJson(json['durationMonths']),
      endDate: _dateFromJson(json['endDate']),
      status: statusValue is String ? statusValue : null,
      totalInstallments: _positiveIntFromJson(json['totalInstallments']),
      paidInstallments: _nonNegativeIntFromJson(json['paidInstallments']),
      remainingInstallments: _nonNegativeIntFromJson(
        json['remainingInstallments'],
      ),
    );
  }

  static DateTime? _dateFromJson(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  static int? _intFromJson(Object? value) {
    if (value is int) return value;
    if (value is num && value.isFinite && value == value.roundToDouble()) {
      return value.toInt();
    }
    if (value is String) return int.tryParse(value);
    return null;
  }

  static int? _positiveIntFromJson(Object? value) {
    final parsed = _intFromJson(value);
    return parsed != null && parsed > 0 ? parsed : null;
  }

  static int? _nonNegativeIntFromJson(Object? value) {
    final parsed = _intFromJson(value);
    return parsed != null && parsed >= 0 ? parsed : null;
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'amount': amount,
      'dueDateDay': dueDateDay,
      'isActive': isActive,
      if (startDate != null) 'startDate': _dateOnly(startDate!),
      if (durationMonths != null) 'durationMonths': durationMonths,
    };
  }

  static String _dateOnly(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
