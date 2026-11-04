import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:kaasutracker/core/localization/generated/app_localizations.dart';
import 'package:kaasutracker/features/analytics/data/category_spending_provider.dart';
import 'package:kaasutracker/features/expenses/data/expenses_provider.dart';
import 'package:kaasutracker/features/finance/data/expense_funding_context.dart';
import 'package:kaasutracker/features/finance/data/finance_error.dart';
import 'package:kaasutracker/features/finance/data/finance_models.dart';
import 'package:kaasutracker/features/finance/data/finance_repository.dart';

class ExpenseFundingScreen extends ConsumerWidget {
  const ExpenseFundingScreen({required this.expenseId, super.key});

  final int expenseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final funding = ref.watch(expenseFundingContextProvider(expenseId));
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.allocationTitle)),
      body: funding.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _FundingError(
          message: financeErrorMessage(context, error),
          onRetry: () =>
              ref.invalidate(expenseFundingContextProvider(expenseId)),
        ),
        data: (data) => _ExpenseFundingForm(data: data),
      ),
    );
  }
}

class _ExpenseFundingForm extends ConsumerStatefulWidget {
  const _ExpenseFundingForm({required this.data});

  final ExpenseFundingContext data;

  @override
  ConsumerState<_ExpenseFundingForm> createState() =>
      _ExpenseFundingFormState();
}

class _ExpenseFundingFormState extends ConsumerState<_ExpenseFundingForm> {
  final _formKey = GlobalKey<FormState>();
  late final List<FundingOption> _options;
  late final List<TextEditingController> _controllers;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _options = widget.data.options;
    _controllers = _options
        .map(
          (option) => TextEditingController(
            text: option.assigned == 0
                ? ''
                : (option.assigned / 100).toStringAsFixed(2),
          )..addListener(_onChanged),
        )
        .toList(growable: false);
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller
        ..removeListener(_onChanged)
        ..dispose();
    }
    super.dispose();
  }

  int _valueAt(int index) {
    final value = _controllers[index].text.trim();
    if (value.isEmpty) return 0;
    try {
      return parseMinorUnits(value, field: 'allocation');
    } on FormatException {
      return -1;
    }
  }

  int get _allocated => List<int>.generate(
    _controllers.length,
    _valueAt,
  ).fold(0, (total, value) => total + (value < 0 ? 0 : value));

  int _maximumAt(int index) =>
      _options[index].available > _options[index].assigned
      ? _options[index].available
      : _options[index].assigned;

  bool get _hasDuplicateSources {
    final keys = <String>{};
    for (var index = 0; index < _options.length; index++) {
      if (_valueAt(index) == 0) continue;
      final option = _options[index];
      final key =
          '${option.source.apiValue}:${option.sourceId?.toString() ?? ''}';
      if (!keys.add(key)) return true;
    }
    return false;
  }

  bool get _isAllocationValid {
    final eligibleAmount = widget.data.expense.eligibleAmountMinorUnits;
    for (var index = 0; index < _options.length; index++) {
      final amount = _valueAt(index);
      if (amount < 0 || amount > _maximumAt(index)) return false;
    }
    return !_hasDuplicateSources && _allocated == eligibleAmount;
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toString();
    final currency = NumberFormat.currency(
      locale: locale,
      symbol: '₹',
      decimalDigits: 2,
    );
    final expense = widget.data.expense;
    final eligibleAmount = expense.eligibleAmountMinorUnits;
    final canAllocate = expense.isConfirmed && eligibleAmount > 0;

    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: ListTile(
                      title: Text(expense.description),
                      subtitle: Text(
                        '${l10n.expenseAmount}: ${currency.format(eligibleAmount / 100)}',
                      ),
                      trailing: Text(
                        DateFormat.yMMMd(locale).format(expense.expenseDate),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (!canAllocate)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        l10n.expenseUnavailable,
                        style: TextStyle(color: colors.error),
                      ),
                    )
                  else if (_options.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(l10n.noFundingSources),
                    )
                  else
                    ...List.generate(_options.length, _buildOption),
                  if (_hasDuplicateSources) ...[
                    const SizedBox(height: 8),
                    Text(
                      l10n.duplicateFundingSource,
                      style: TextStyle(color: colors.error),
                    ),
                  ] else if (!_isAllocationValid &&
                      List<int>.generate(
                        _controllers.length,
                        _valueAt,
                      ).every((amount) => amount >= 0) &&
                      _options.asMap().entries.every(
                        (entry) => _valueAt(entry.key) <= _maximumAt(entry.key),
                      )) ...[
                    const SizedBox(height: 8),
                    Text(
                      l10n.allocationExceedsExpense,
                      style: TextStyle(color: colors.error),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${l10n.assignedAmount}: '
                                  '${currency.format(_allocated / 100)}',
                                ),
                                const SizedBox(height: 4),
                                Text(l10n.unallocatedAmount),
                              ],
                            ),
                          ),
                          Text(
                            currency.format(
                              (eligibleAmount - _allocated) / 100,
                            ),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: eligibleAmount == _allocated
                                  ? null
                                  : colors.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSaving
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: Text(l10n.cancel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed:
                        !canAllocate ||
                            _options.isEmpty ||
                            !_isAllocationValid ||
                            _isSaving
                        ? null
                        : _save,
                    child: _isSaving
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.saveAllocation),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOption(int index) {
    final l10n = AppLocalizations.of(context)!;
    final option = _options[index];
    final label =
        option.label ??
        switch (option.source) {
          FundingSource.salary => l10n.salaryAvailable,
          FundingSource.carryForward => l10n.carryForwardAvailable,
          FundingSource.additional => l10n.additionalFundsTitle,
          FundingSource.borrowed => l10n.borrowedFundsTitle,
        };
    final currency = NumberFormat.currency(
      locale: Localizations.localeOf(context).toString(),
      symbol: '₹',
      decimalDigits: 2,
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(
              '${l10n.sourceAvailable}: ${currency.format(option.available / 100)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            TextFormField(
              controller: _controllers[index],
              enabled: !_isSaving,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: l10n.assignedAmount,
                prefixText: '₹ ',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return null;
                final amount = _parseAmount(value);
                if (amount == null || amount < 0) {
                  return l10n.amountRequired;
                }
                if (amount > _maximumAt(index)) {
                  return l10n.allocationExceedsBalance;
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_isSaving || !_isAllocationValid) return;
    if (!_formKey.currentState!.validate()) return;
    final allocations = <ExpenseFundingAllocationInput>[];
    for (var index = 0; index < _options.length; index++) {
      final amount = _valueAt(index);
      if (amount == 0) continue;
      final option = _options[index];
      allocations.add(
        ExpenseFundingAllocationInput(
          fundingSource: option.source,
          sourceId: option.sourceId,
          amount: amount,
        ),
      );
    }

    setState(() => _isSaving = true);
    try {
      final repository = ref.read(financeRepositoryProvider);
      final responseAllocations = await repository.replaceExpenseFunding(
        expenseId: widget.data.expenseId,
        allocations: allocations,
      );
      if (!_sameAllocations(allocations, responseAllocations)) {
        throw const _AllocationVerificationException();
      }
      final persistedAllocations = await repository.getExpenseFunding(
        widget.data.expenseId,
      );
      if (!_sameAllocations(allocations, persistedAllocations)) {
        throw const _AllocationVerificationException();
      }
      if (!mounted) return;
      final period = widget.data.period;
      final selectedPeriod = ref.read(selectedFinancePeriodProvider);
      ref.invalidate(expenseFundingProvider(widget.data.expenseId));
      ref.invalidate(expenseFundingContextProvider(widget.data.expenseId));
      ref.invalidate(expenseDetailsProvider(widget.data.expenseId));
      ref.invalidate(expensesProvider);
      ref.invalidate(expensesByCategoryProvider);
      for (final refreshPeriod in {period, selectedPeriod}) {
        ref.invalidate(monthlyFinancialSummaryProvider(refreshPeriod));
        ref.invalidate(carryForwardProvider(refreshPeriod));
        ref.invalidate(
          fundCollectionProvider(
            FundQuery(type: FundType.additional, period: refreshPeriod),
          ),
        );
        ref.invalidate(
          fundCollectionProvider(
            FundQuery(type: FundType.borrowed, period: refreshPeriod),
          ),
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.allocationSaved)),
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is _AllocationVerificationException
                ? AppLocalizations.of(context)!.allocationVerificationFailed
                : financeErrorMessage(context, error),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class _AllocationVerificationException implements Exception {
  const _AllocationVerificationException();
}

bool _sameAllocations(
  List<ExpenseFundingAllocationInput> requested,
  List<ExpenseFundingAllocation> persisted,
) {
  String key(FundingSource source, int? sourceId) =>
      '${source.apiValue}:${sourceId?.toString() ?? ''}';

  final expected = <String, int>{};
  for (final allocation in requested) {
    if (allocation.amount <= 0 ||
        !_hasValidSourceId(allocation.fundingSource, allocation.sourceId)) {
      return false;
    }
    final allocationKey = key(allocation.fundingSource, allocation.sourceId);
    if (expected.containsKey(allocationKey)) return false;
    expected[allocationKey] = allocation.amount;
  }
  final actual = <String, int>{};
  for (final allocation in persisted) {
    if (allocation.amount <= 0 ||
        !_hasValidSourceId(allocation.fundingSource, allocation.sourceId)) {
      return false;
    }
    final allocationKey = key(allocation.fundingSource, allocation.sourceId);
    if (actual.containsKey(allocationKey)) return false;
    actual[allocationKey] = allocation.amount;
  }
  return expected.length == actual.length &&
      expected.entries.every((entry) => actual[entry.key] == entry.value);
}

bool _hasValidSourceId(FundingSource source, int? sourceId) => switch (source) {
  FundingSource.salary => sourceId == null,
  FundingSource.carryForward ||
  FundingSource.additional ||
  FundingSource.borrowed => sourceId != null && sourceId > 0,
};

int? _parseAmount(String input) {
  try {
    return parseMinorUnits(input.trim(), field: 'allocation');
  } on FormatException {
    return null;
  }
}

class _FundingError extends StatelessWidget {
  const _FundingError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onRetry,
            child: Text(AppLocalizations.of(context)!.retry),
          ),
        ],
      ),
    ),
  );
}
