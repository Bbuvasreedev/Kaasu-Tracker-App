import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaasutracker/core/localization/generated/app_localizations.dart';
import 'package:kaasutracker/features/finance/data/finance_error.dart';
import 'package:kaasutracker/features/finance/data/finance_models.dart';
import 'package:kaasutracker/features/finance/data/finance_repository.dart';

class MonthlySalaryDialog extends ConsumerStatefulWidget {
  const MonthlySalaryDialog({
    required this.period,
    required this.initialAmount,
    required this.onSavingChanged,
    super.key,
  });

  final FinancePeriod period;
  final int initialAmount;
  final ValueChanged<bool> onSavingChanged;

  @override
  ConsumerState<MonthlySalaryDialog> createState() =>
      _MonthlySalaryDialogState();
}

class _MonthlySalaryDialogState extends ConsumerState<MonthlySalaryDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialAmount > 0
          ? (widget.initialAmount / 100).toStringAsFixed(2)
          : '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int? _parseMoney(String? value) {
    try {
      return parseMinorUnits(value?.trim() ?? '', field: 'amount');
    } on FormatException {
      return null;
    }
  }

  String? _validateAmount(String? value) {
    final amount = _parseMoney(value);
    return amount == null || amount <= 0
        ? AppLocalizations.of(context)!.validSalaryRequired
        : null;
  }

  Future<void> _save() async {
    if (_isSaving || !_formKey.currentState!.validate()) return;
    final amount = _parseMoney(_controller.text);
    if (amount == null || amount <= 0) return;

    setState(() => _isSaving = true);
    widget.onSavingChanged(true);
    try {
      await ref
          .read(financeRepositoryProvider)
          .saveMonthlySalary(period: widget.period, amount: amount);
      if (!mounted) return;
      ref.invalidate(monthlyFinancialSummaryProvider(widget.period));
      setState(() => _isSaving = false);
      widget.onSavingChanged(false);
      await WidgetsBinding.instance.endOfFrame;
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(financeErrorMessage(context, error)),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted && _isSaving) {
        setState(() => _isSaving = false);
        widget.onSavingChanged(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PopScope(
      canPop: !_isSaving,
      child: AlertDialog(
        title: Text(l10n.setMonthlySalary),
        content: Form(
          key: _formKey,
          child: TextFormField(
            controller: _controller,
            autofocus: true,
            enabled: !_isSaving,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: l10n.baseMonthlySalary,
              prefixText: '₹ ',
            ),
            validator: _validateAmount,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving
                ? null
                : () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.saveFund),
          ),
        ],
      ),
    );
  }
}
