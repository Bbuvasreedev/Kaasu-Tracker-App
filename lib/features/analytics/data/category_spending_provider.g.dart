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
        retry: null,
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

String _$categorySpendingHash() => r'5ea46c392d9e068e12f7fa3ac611d0c9d7e6745a';
