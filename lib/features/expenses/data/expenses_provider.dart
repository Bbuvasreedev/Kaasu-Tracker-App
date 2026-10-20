import 'package:kaasutracker/core/network/api_service.dart';
import 'package:kaasutracker/features/expenses/data/expense.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'expenses_provider.g.dart';

@riverpod
Future<List<Expense>> expenses(Ref ref) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.get('expenses');
  if (response is! List) {
    throw const FormatException(
      'Expected the expenses endpoint to return a list.',
    );
  }

  return response
      .map((item) {
        if (item is! Map<String, dynamic>) {
          throw const FormatException(
            'Expected each expense to be a JSON object.',
          );
        }
        return Expense.fromJson(item);
      })
      .toList(growable: false);
}
