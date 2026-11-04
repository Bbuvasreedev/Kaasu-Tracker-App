import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaasutracker/core/network/api_service.dart';
import 'package:kaasutracker/features/auth/auth_provider.dart';
import 'package:kaasutracker/features/profile/data/user_model.dart';

/// Provider for fetching user profile details from backend `/users/me`
final userProfileProvider = FutureProvider<UserModel>((ref) async {
  ref.watch(authStateStreamProvider);
  final api = ref.watch(apiServiceProvider);
  final auth = ref.read(authProvider);
  final email = auth.currentUser?.email;

  try {
    final response = await api.get('users/me');
    if (response is Map<String, dynamic>) {
      final model = UserModel.fromJson(response);
      return model.copyWith(email: email ?? model.email);
    }
    return UserModel(
      email: email,
      baseSalary: 0.0,
      thresholdPercentage: 80.0,
      languagePref: 'en',
    );
  } on ApiException catch (e) {
    if (e.statusCode == 404) {
      return UserModel(
        email: email,
        baseSalary: 0.0,
        thresholdPercentage: 80.0,
        languagePref: 'en',
      );
    }
    rethrow;
  } on ApiAuthenticationException {
    return UserModel(
      email: email,
      baseSalary: 0.0,
      thresholdPercentage: 80.0,
      languagePref: 'en',
    );
  }
});
