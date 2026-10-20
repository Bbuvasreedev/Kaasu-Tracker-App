class EmiModel {
  const EmiModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.dueDateDay,
    this.isActive = true,
  });

  final String id;
  final String title;
  final double amount;
  final int dueDateDay;
  final bool isActive;

  factory EmiModel.fromJson(Map<String, dynamic> json) {
    final amountValue = json['amount'];
    final dueDayValue = json['dueDateDay'] ?? json['dueDay'] ?? json['day'];

    return EmiModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] is String && (json['title'] as String).trim().isNotEmpty
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
              : true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'amount': amount,
      'dueDateDay': dueDateDay,
      'isActive': isActive,
    };
  }
}
