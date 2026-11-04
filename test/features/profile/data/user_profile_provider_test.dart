import 'package:flutter_test/flutter_test.dart';
import 'package:kaasutracker/features/profile/data/user_model.dart';

void main() {
  test('UserModel.fromJson parses successfully', () {
    final json = {
      'baseSalary': 50000.0,
      'thresholdPercentage': 80.0,
      'languagePref': 'en',
      'email': 'test@example.com',
    };
    final model = UserModel.fromJson(json);
    expect(model.baseSalary, 50000.0);
    expect(model.thresholdPercentage, 80.0);
    expect(model.languagePref, 'en');
    expect(model.email, 'test@example.com');
  });
}
