import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:kaasutracker/core/localization/generated/app_localizations.dart';
import 'package:kaasutracker/features/finance/data/finance_models.dart';
import 'package:kaasutracker/features/finance/data/finance_error.dart';
import 'package:kaasutracker/features/finance/data/finance_repository.dart';

class FundManagementScreen extends ConsumerStatefulWidget {
  const FundManagementScreen({required this.type, super.key});

  final FundType type;

  @override
  ConsumerState<FundManagementScreen> createState() =>
      _FundManagementScreenState();
}

class _FundManagementScreenState extends ConsumerState<FundManagementScreen> {
  bool _isMutating = false;

  FundType get type => widget.type;

  @override
  Widget build(BuildContext context) {
    final type = widget.type;
    final l10n = AppLocalizations.of(context)!;
    final period = ref.watch(selectedFinancePeriodProvider);
    final query = FundQuery(type: type, period: period);
    final collection = ref.watch(fundCollectionProvider(query));
    final currency = NumberFormat.currency(
      locale: Localizations.localeOf(context).toString(),
      symbol: '₹',
      decimalDigits: 2,
    );
    final locale = Localizations.localeOf(context).toString();
    final isBorrowed = type == FundType.borrowed;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isBorrowed ? l10n.borrowedFundsTitle : l10n.additionalFundsTitle,
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isMutating ? null : () => _editFund(context, period, null),
        icon: _isMutating
            ? const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.add),
        label: Text(_isMutating ? l10n.saving : l10n.addFund),
      ),
      body: collection.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _ErrorState(
          message: financeErrorMessage(context, error),
          onRetry: () => ref.invalidate(fundCollectionProvider(query)),
        ),
        data: (data) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(fundCollectionProvider(query));
            await ref.read(fundCollectionProvider(query).future);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              _BalanceCard(
                received: currency.format(data.totalReceived / 100),
                used: currency.format(data.totalUsed / 100),
                remaining: currency.format(data.remainingAvailable / 100),
                receivedLabel: l10n.fundsReceived,
                usedLabel: l10n.fundsUsed,
                remainingLabel: l10n.fundsRemaining,
              ),
              const SizedBox(height: 16),
              if (data.funds.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 36),
                  child: Center(child: Text(l10n.emptyFunds)),
                )
              else
                ...data.funds.map(
                  (fund) => Card(
                    child: ListTile(
                      title: Text(fund.sourceDescription),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(DateFormat.yMMMd(locale).format(fund.fundDate)),
                          if (fund.purpose?.isNotEmpty ?? false)
                            Text(fund.purpose!),
                          if (isBorrowed &&
                              fund.outstandingRepaymentBalance != null)
                            Text(
                              '${l10n.repaymentBalanceLabel}: ${currency.format(fund.outstandingRepaymentBalance! / 100)}',
                            ),
                          if (fund.status != 'AVAILABLE')
                            Text(l10n.inactiveFundStatus),
                        ],
                      ),
                      isThreeLine: true,
                      trailing: SizedBox(
                        width: 150,
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                currency.format(fund.amount / 100),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.end,
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                            PopupMenuButton<String>(
                              tooltip: l10n.updateFund,
                              onSelected: (action) {
                                if (action == 'edit') {
                                  _editFund(context, period, fund);
                                } else {
                                  _deactivateFund(context, query, fund);
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Text(l10n.updateFund),
                                ),
                                if (fund.status == 'AVAILABLE')
                                  PopupMenuItem(
                                    value: 'deactivate',
                                    child: Text(l10n.deactivateFund),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editFund(
    BuildContext context,
    FinancePeriod period,
    FundRecord? existing,
  ) async {
    if (_isMutating) return;
    final draft = await showDialog<_FundDraft>(
      context: context,
      builder: (context) =>
          _FundFormDialog(type: type, initial: existing, period: period),
    );
    if (draft == null || !context.mounted) return;
    setState(() => _isMutating = true);
    try {
      await ref
          .read(financeRepositoryProvider)
          .saveFund(
            type: type,
            id: existing?.id,
            amount: draft.amount,
            fundDate: draft.date,
            sourceDescription: draft.sourceDescription,
            purpose: draft.purpose,
            outstandingRepaymentBalance: draft.repaymentBalance,
          );
      if (!mounted) return;
      ref.invalidate(
        fundCollectionProvider(FundQuery(type: type, period: period)),
      );
      ref.invalidate(monthlyFinancialSummaryProvider(period));
      final targetPeriod = FinancePeriod.fromDate(draft.date);
      if (targetPeriod != period) {
        ref.invalidate(
          fundCollectionProvider(FundQuery(type: type, period: targetPeriod)),
        );
        ref.invalidate(monthlyFinancialSummaryProvider(targetPeriod));
      }
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.fundSaved)),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(financeErrorMessage(context, error)),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isMutating = false);
    }
  }

  Future<void> _deactivateFund(
    BuildContext context,
    FundQuery query,
    FundRecord fund,
  ) async {
    if (_isMutating) return;
    setState(() => _isMutating = true);
    try {
      await ref.read(financeRepositoryProvider).deactivateFund(type, fund.id);
      if (!mounted) return;
      ref.invalidate(fundCollectionProvider(query));
      ref.invalidate(monthlyFinancialSummaryProvider(query.period));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.fundDeactivated)),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(financeErrorMessage(context, error)),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isMutating = false);
    }
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.received,
    required this.used,
    required this.remaining,
    required this.receivedLabel,
    required this.usedLabel,
    required this.remainingLabel,
  });

  final String received;
  final String used;
  final String remaining;
  final String receivedLabel;
  final String usedLabel;
  final String remainingLabel;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _BalanceRow(label: receivedLabel, value: received),
          _BalanceRow(label: usedLabel, value: used),
          _BalanceRow(label: remainingLabel, value: remaining),
        ],
      ),
    ),
  );
}

class _BalanceRow extends StatelessWidget {
  const _BalanceRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
  );
}

class _FundFormDialog extends StatefulWidget {
  const _FundFormDialog({
    required this.type,
    required this.initial,
    required this.period,
  });

  final FundType type;
  final FundRecord? initial;
  final FinancePeriod period;

  @override
  State<_FundFormDialog> createState() => _FundFormDialogState();
}

class _FundFormDialogState extends State<_FundFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _sourceController;
  late final TextEditingController _purposeController;
  late final TextEditingController _repaymentController;
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _amountController = TextEditingController(
      text: initial == null ? '' : (initial.amount / 100).toStringAsFixed(2),
    );
    _sourceController = TextEditingController(
      text: initial?.sourceDescription ?? '',
    );
    _purposeController = TextEditingController(text: initial?.purpose ?? '');
    _repaymentController = TextEditingController(
      text: initial?.outstandingRepaymentBalance == null
          ? ''
          : (initial!.outstandingRepaymentBalance! / 100).toStringAsFixed(2),
    );
    _date = initial?.fundDate ?? widget.period.firstDay;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _sourceController.dispose();
    _purposeController.dispose();
    _repaymentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isBorrowed = widget.type == FundType.borrowed;
    return AlertDialog(
      title: Text(l10n.fundsFormTitle),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: l10n.amountLabel,
                  prefixText: '₹ ',
                ),
                validator: (value) {
                  final amount = _minorValue(value);
                  return amount == null || amount <= 0
                      ? l10n.amountRequired
                      : null;
                },
              ),
              TextFormField(
                controller: _sourceController,
                maxLength: 200,
                decoration: InputDecoration(
                  labelText: l10n.sourceDescriptionLabel,
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? l10n.sourceRequired
                    : null,
              ),
              if (isBorrowed) ...[
                TextFormField(
                  controller: _purposeController,
                  maxLength: 500,
                  decoration: InputDecoration(labelText: l10n.purposeLabel),
                ),
                TextFormField(
                  controller: _repaymentController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: l10n.repaymentBalanceLabel,
                    prefixText: '₹ ',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return null;
                    final amount = _minorValue(value);
                    return amount == null || amount < 0
                        ? l10n.amountRequired
                        : null;
                  },
                ),
              ],
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.dateLabel),
                subtitle: Text(
                  DateFormat.yMMMd(Localizations.localeOf(context).toString())
                      .format(_date),
                ),
                trailing: const Icon(Icons.calendar_today_outlined),
                onTap: _selectDate,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(widget.initial == null ? l10n.saveFund : l10n.updateFund),
        ),
      ],
    );
  }

  Future<void> _selectDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (selected != null) setState(() => _date = selected);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      _FundDraft(
        amount: _minorValue(_amountController.text)!,
        date: _date,
        sourceDescription: _sourceController.text.trim(),
        purpose: _purposeController.text.trim().isEmpty
            ? null
            : _purposeController.text.trim(),
        repaymentBalance: _repaymentController.text.trim().isEmpty
            ? null
            : _minorValue(_repaymentController.text),
      ),
    );
  }
}

class _FundDraft {
  const _FundDraft({
    required this.amount,
    required this.date,
    required this.sourceDescription,
    required this.purpose,
    required this.repaymentBalance,
  });

  final int amount;
  final DateTime date;
  final String sourceDescription;
  final String? purpose;
  final int? repaymentBalance;
}

int? _minorValue(String? value) {
  try {
    return parseMinorUnits(value?.trim() ?? '', field: 'amount');
  } on FormatException {
    return null;
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 40),
          const SizedBox(height: 12),
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
