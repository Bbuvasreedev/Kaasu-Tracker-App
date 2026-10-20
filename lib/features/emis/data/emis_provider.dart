import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaasutracker/core/network/api_service.dart';
import 'package:kaasutracker/features/emis/data/emi_model.dart';

/// Provider for fetching the user's EMIs from `GET /api/v1/emis`
final emisProvider = FutureProvider<List<EmiModel>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  try {
    final response = await api.get('emis');
    if (response is List) {
      return response
          .map((item) {
            if (item is Map<String, dynamic>) {
              return EmiModel.fromJson(item);
            }
            return null;
          })
          .whereType<EmiModel>()
          .toList();
    }
  } catch (_) {
    // Return empty list if endpoint returns error or uninitialized
  }
  return [];
});

class EmiRepository {
  final ApiService _api;

  EmiRepository(this._api);

  /// Creates a new EMI via `POST /api/v1/emis`
  Future<void> addEmi({
    required String title,
    required double amount,
    required int dueDateDay,
  }) async {
    final payload = {
      'title': title,
      'amount': amount,
      'dueDateDay': dueDateDay,
      'isActive': true,
    };
    await _api.post('emis', body: payload);
  }
}

final emiRepositoryProvider = Provider<EmiRepository>((ref) {
  return EmiRepository(ref.watch(apiServiceProvider));
});
