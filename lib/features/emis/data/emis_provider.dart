import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaasutracker/core/network/api_service.dart';
import 'package:kaasutracker/features/auth/auth_provider.dart';
import 'package:kaasutracker/features/emis/data/emi_model.dart';

enum EmiScheduleStatus { scheduled, dueToday }

class EmiScheduleItem {
  const EmiScheduleItem({required this.emi, required this.dueDate});

  final EmiModel emi;
  final DateTime dueDate;

  EmiScheduleStatus statusFor(DateTime today) =>
      dueDate.year == today.year &&
          dueDate.month == today.month &&
          dueDate.day == today.day
      ? EmiScheduleStatus.dueToday
      : EmiScheduleStatus.scheduled;
}

List<EmiScheduleItem> buildEmiSchedule(
  List<EmiModel> emis, {
  required DateTime now,
}) {
  final today = DateTime(now.year, now.month, now.day);
  final seenIds = <String>{};
  final items = <EmiScheduleItem>[];

  for (final emi in emis) {
    if (!emi.isActive ||
        emi.isCompleted ||
        emi.dueDateDay < 1 ||
        emi.dueDateDay > 31 ||
        !emi.amount.isFinite ||
        emi.amount <= 0 ||
        (emi.id.isNotEmpty && !seenIds.add(emi.id))) {
      continue;
    }

    var year = today.year;
    var month = today.month;
    var dueDate = _dueDate(year, month, emi.dueDateDay);
    if (dueDate.isBefore(today)) {
      month++;
      if (month > 12) {
        year++;
        month = 1;
      }
      dueDate = _dueDate(year, month, emi.dueDateDay);
    }
    items.add(EmiScheduleItem(emi: emi, dueDate: dueDate));
  }

  items.sort((a, b) => a.dueDate.compareTo(b.dueDate));
  return items;
}

DateTime _dueDate(int year, int month, int requestedDay) {
  final lastDay = DateTime(year, month + 1, 0).day;
  return DateTime(year, month, requestedDay.clamp(1, lastDay));
}

/// Provider for fetching the user's EMIs from `GET /api/v1/emis`
final emisProvider = FutureProvider<List<EmiModel>>((ref) async {
  ref.watch(authStateStreamProvider);
  final api = ref.watch(apiServiceProvider);
  final response = await api.get('emis');
  if (response is! List) {
    throw const FormatException('Expected the EMIs endpoint to return a list.');
  }
  return response
      .map((item) {
        if (item is! Map<String, dynamic>) {
          throw const FormatException('Expected each EMI to be a JSON object.');
        }
        return EmiModel.fromJson(item);
      })
      .toList(growable: false);
});

class EmiRepository {
  final ApiService _api;

  EmiRepository(this._api);

  /// Creates a new EMI via `POST /api/v1/emis`
  Future<void> addEmi({
    required String title,
    required double amount,
    required int dueDateDay,
    required DateTime startDate,
    required int durationMonths,
  }) async {
    final payload = EmiModel(
      id: '',
      title: title,
      amount: amount,
      dueDateDay: dueDateDay,
      startDate: startDate,
      durationMonths: durationMonths,
    ).toJson();
    payload['isActive'] = true;
    await _api.post('emis', body: payload);
  }

  /// Updates only the active flag; backend payment history must be preserved.
  Future<void> updateEmiStatus({
    required String id,
    required bool isActive,
  }) async {
    final normalizedId = id.trim();
    final numericId = int.tryParse(normalizedId);
    if (numericId == null || numericId <= 0) {
      throw ArgumentError.value(id, 'id', 'EMI id must be a positive integer.');
    }
    final expectedStatus = isActive ? 'ACTIVE' : 'INACTIVE';
    final response = await _api.put(
      'emis/$numericId/status',
      body: {'status': expectedStatus},
    );
    if (response is! Map<String, dynamic> ||
        response['status'] is! String ||
        (response['status'] as String).toUpperCase() != expectedStatus) {
      throw const FormatException(
        'The EMI status update response did not confirm the requested status.',
      );
    }
  }
}

final emiRepositoryProvider = Provider<EmiRepository>((ref) {
  return EmiRepository(ref.watch(apiServiceProvider));
});
