import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaasutracker/core/network/api_service.dart';
import 'package:kaasutracker/features/auth/auth_provider.dart';
import 'package:kaasutracker/features/profile/data/user_model.dart';

/// Provider for fetching user profile details from backend `/users/me`
final userProfileProvider = FutureProvider<UserModel>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final auth = ref.watch(authProvider);
  final email = auth.currentUser?.email;

  try {
    final response = await api.get('users/me');
    if (response is Map<String, dynamic>) {
      final model = UserModel.fromJson(response);
      return model.copyWith(email: email ?? model.email);
    }
  } catch (_) {
    // Return default preference state if user profile endpoint returns error or 404
  }

  return UserModel(
    email: email ?? 'user@example.com',
    baseSalary: 50000.0,
    thresholdPercentage: 80.0,
    languagePref: 'en',
  );
});
