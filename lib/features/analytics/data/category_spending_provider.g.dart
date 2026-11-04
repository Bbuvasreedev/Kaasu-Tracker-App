// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_spending_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(categorySpending)
final categorySpendingProvider = CategorySpendingProvider._();

final class CategorySpendingProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<CategorySpending>>,
          List<CategorySpending>,
          FutureOr<List<CategorySpending>>
        >
    with
        $FutureModifier<List<CategorySpending>>,
        $FutureProvider<List<CategorySpending>> {
  CategorySpendingProvider._()
    : super(
        from: null,
        argument: null,
        retry: _disableAutomaticRetry,
        name: r'categorySpendingProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$categorySpendingHash();

  @$internal
  @override
  $FutureProviderElement<List<CategorySpending>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<CategorySpending>> create(Ref ref) {
    return categorySpending(ref);
  }
}

String _$categorySpendingHash() => r'13b286dfdda2ce55ffe048c91d58483306b8d9cf';
