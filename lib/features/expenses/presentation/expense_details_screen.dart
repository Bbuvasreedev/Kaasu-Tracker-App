import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kaasutracker/core/localization/expense_category_localization.dart';
import 'package:kaasutracker/core/localization/generated/app_localizations.dart';
import 'package:kaasutracker/features/analytics/data/category_spending_provider.dart';
import 'package:kaasutracker/features/expenses/data/expense.dart';
import 'package:kaasutracker/features/expenses/data/expenses_provider.dart';
import 'package:kaasutracker/features/finance/data/finance_error.dart';
import 'package:kaasutracker/features/finance/data/expense_funding_context.dart';
import 'package:kaasutracker/features/finance/data/finance_models.dart';
import 'package:kaasutracker/features/finance/data/finance_repository.dart';

class ExpenseDetailsScreen extends ConsumerStatefulWidget {
  const ExpenseDetailsScreen({required this.expenseId, super.key});

  final int expenseId;

  @override
  ConsumerState<ExpenseDetailsScreen> createState() =>
      _ExpenseDetailsScreenState();
}

class _ExpenseDetailsScreenState extends ConsumerState<ExpenseDetailsScreen> {
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final expenseAsync = ref.watch(expenseDetailsProvider(widget.expenseId));
    return Scaffold(
      appBar: AppBar(title: Text(l10n.expenseDetailsTitle)),
      body: expenseAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _LoadError(
          message: financeErrorMessage(context, error),
          onRetry: () =>
              ref.invalidate(expenseDetailsProvider(widget.expenseId)),
        ),
        data: (expense) {
          if (expense == null) {
            return Center(child: Text(l10n.expenseDetailsNotFound));
          }
          return _details(context, expense);
        },
      ),
    );
  }

  Widget _details(BuildContext context, Expense expense) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final currency = NumberFormat.currency(
      locale: locale,
      symbol: '₹',
      decimalDigits: 2,
    );
    final dateFormat = DateFormat.yMMMd(locale);
    final localExpenseDate = expense.expenseDate.toLocal();
    final includesTime =
        expense.expenseDate.isUtc ||
        localExpenseDate.hour != 0 ||
        localExpenseDate.minute != 0 ||
        localExpenseDate.second != 0;
    final transactionDate = includesTime
        ? '${dateFormat.format(localExpenseDate)} '
              '${DateFormat.jm(locale).format(localExpenseDate)}'
        : dateFormat.format(localExpenseDate);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.description.trim().isEmpty
                      ? localizedExpenseCategory(expense.category, l10n)
                      : expense.description,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  currency.format(expense.amount),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Divider(height: 24),
                _DetailRow(
                  label: l10n.categoryLabel,
                  value: localizedExpenseCategory(expense.category, l10n),
                ),
                _DetailRow(label: l10n.dateLabel, value: transactionDate),
                _DetailRow(
                  label: l10n.expenseAmount,
                  value: currency.format(
                    expense.eligibleAmountMinorUnits / 100,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _FundingBreakdown(expense: expense),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () =>
              context.push('/expenses/${widget.expenseId}/funding'),
          icon: const Icon(Icons.account_balance_wallet_outlined),
          label: Text(l10n.manageExpenseFunding),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: _isDeleting ? null : () => _confirmDelete(expense),
          icon: _isDeleting
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.delete_outline),
          label: Text(l10n.deleteExpense),
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(Expense expense) async {
    final l10n = AppLocalizations.of(context)!;
    final currency = NumberFormat.currency(
      locale: Localizations.localeOf(context).toString(),
      symbol: '₹',
      decimalDigits: 2,
    );
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteExpense),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              expense.description.trim().isEmpty
                  ? localizedExpenseCategory(expense.category, l10n)
                  : expense.description,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(currency.format(expense.amount)),
            const SizedBox(height: 12),
            Text(l10n.confirmExpenseDeleteMessage),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l10n.deleteExpense),
          ),
        ],
      ),
    );
    if (confirmed == true) await _delete(expense);
  }

  Future<void> _delete(Expense expense) async {
    setState(() => _isDeleting = true);
    try {
      await ref.read(expenseRepositoryProvider).deleteExpense(widget.expenseId);
      if (!mounted) return;

      final expensePeriod = FinancePeriod.fromDate(expense.expenseDate);
      final periods = {expensePeriod, ref.read(selectedFinancePeriodProvider)};
      ref.invalidate(expensesProvider);
      ref.invalidate(expenseDetailsProvider(widget.expenseId));
      ref.invalidate(expenseFundingProvider(widget.expenseId));
      ref.invalidate(expenseFundingContextProvider(widget.expenseId));
      ref.invalidate(expensesByCategoryProvider);
      for (final period in periods) {
        ref.invalidate(monthlyFinancialSummaryProvider(period));
        ref.invalidate(carryForwardProvider(period));
        ref.invalidate(
          fundCollectionProvider(
            FundQuery(type: FundType.additional, period: period),
          ),
        );
        ref.invalidate(
          fundCollectionProvider(
            FundQuery(type: FundType.borrowed, period: period),
          ),
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.expenseDeleted)),
      );
      context.pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(financeErrorMessage(context, error)),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }
}

class _FundingBreakdown extends ConsumerWidget {
  const _FundingBreakdown({required this.expense});

  final Expense expense;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toString();
    final currency = NumberFormat.currency(
      locale: locale,
      symbol: '₹',
      decimalDigits: 2,
    );
    final allocations = ref.watch(
      expenseFundingProvider(int.parse(expense.id)),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.expenseFundingBreakdown,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            allocations.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, stack) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    financeErrorMessage(context, error),
                    style: TextStyle(color: colors.error),
                  ),
                  TextButton(
                    onPressed: () => ref.invalidate(
                      expenseFundingProvider(int.parse(expense.id)),
                    ),
                    child: Text(l10n.retry),
                  ),
                ],
              ),
              data: (items) {
                final allocated = items.fold<int>(
                  0,
                  (total, item) => total + item.amount,
                );
                final remaining = (expense.eligibleAmountMinorUnits - allocated)
                    .clamp(0, expense.eligibleAmountMinorUnits);
                return Column(
                  children: [
                    if (items.isNotEmpty)
                      for (final item in items)
                        _DetailRow(
                          label: switch (item.fundingSource) {
                            FundingSource.salary => l10n.salaryAvailable,
                            FundingSource.carryForward =>
                              l10n.carryForwardAvailable,
                            FundingSource.additional =>
                              l10n.additionalFundsTitle,
                            FundingSource.borrowed => l10n.borrowedFundsTitle,
                          },
                          value: currency.format(item.amount / 100),
                        ),
                    if (remaining > 0)
                      _DetailRow(
                        label: l10n.unfundedAmount,
                        value: currency.format(remaining / 100),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(label)),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

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
          FilledButton(
            onPressed: onRetry,
            child: Text(AppLocalizations.of(context)!.retry),
          ),
        ],
      ),
    ),
  );
}
