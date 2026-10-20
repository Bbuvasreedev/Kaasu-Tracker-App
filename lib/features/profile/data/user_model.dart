class UserModel {
  const UserModel({
    this.email,
    required this.baseSalary,
    required this.thresholdPercentage,
    required this.languagePref,
  });

  final String? email;
  final double baseSalary;
  final double thresholdPercentage;
  final String languagePref;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final salary = json['baseSalary'];
    final threshold = json['thresholdPercentage'];

    return UserModel(
      email: json['email'] as String?,
      baseSalary: salary is num
          ? salary.toDouble()
          : salary is String
              ? double.tryParse(salary) ?? 0.0
              : 0.0,
      thresholdPercentage: threshold is num
          ? threshold.toDouble()
          : threshold is String
              ? double.tryParse(threshold) ?? 80.0
              : 80.0,
      languagePref: (json['languagePref'] as String?) ?? 'en',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'baseSalary': baseSalary,
      'thresholdPercentage': thresholdPercentage,
      'languagePref': languagePref,
    };
  }

  UserModel copyWith({
    String? email,
    double? baseSalary,
    double? thresholdPercentage,
    String? languagePref,
  }) {
    return UserModel(
      email: email ?? this.email,
      baseSalary: baseSalary ?? this.baseSalary,
      thresholdPercentage: thresholdPercentage ?? this.thresholdPercentage,
      languagePref: languagePref ?? this.languagePref,
    );
  }
}
