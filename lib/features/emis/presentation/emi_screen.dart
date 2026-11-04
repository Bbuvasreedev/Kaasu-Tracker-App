import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:kaasutracker/core/localization/generated/app_localizations.dart';
import 'package:kaasutracker/features/emis/data/emi_model.dart';
import 'package:kaasutracker/features/emis/data/emis_provider.dart';

class EmiScreen extends ConsumerWidget {
  const EmiScreen({super.key});

  void _showAddEmiBottomSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) =>
          _AddEmiFormSheet(onSave: () => ref.invalidate(emisProvider)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final currencyFormat = NumberFormat.currency(
      locale: locale,
      symbol: '₹',
      decimalDigits: 2,
    );
    final emisAsync = ref.watch(emisProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.emiTrackerTitle), centerTitle: false),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEmiBottomSheet(context, ref),
        icon: const Icon(Icons.add),
        label: Text(l10n.addEmi),
      ),
      body: emisAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: colors.error),
                const SizedBox(height: 16),
                Text(
                  l10n.emiLoadError,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(emisProvider),
                  child: Text(l10n.retry),
                ),
              ],
            ),
          ),
        ),
        data: (emis) {
          if (emis.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.credit_card_off_outlined,
                      size: 64,
                      color: colors.outline,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.noActiveEmis,
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.addEmiDescription,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 88),
            itemCount: emis.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final emi = emis[index];
              return _EmiCard(
                emi: emi,
                currencyFormat: currencyFormat,
                onStatusChanged: (isActive) async {
                  await ref
                      .read(emiRepositoryProvider)
                      .updateEmiStatus(id: emi.id, isActive: isActive);
                  ref.invalidate(emisProvider);
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _EmiCard extends StatefulWidget {
  const _EmiCard({
    required this.emi,
    required this.currencyFormat,
    required this.onStatusChanged,
  });

  final EmiModel emi;
  final NumberFormat currencyFormat;
  final Future<void> Function(bool isActive) onStatusChanged;

  @override
  State<_EmiCard> createState() => _EmiCardState();
}

class _EmiCardState extends State<_EmiCard> {
  bool _isUpdating = false;

  Future<void> _changeStatus(bool isActive) async {
    final l10n = AppLocalizations.of(context)!;
    if (!isActive) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.deactivateEmiTitle),
          content: Text(l10n.deactivateEmiConfirmation(widget.emi.title)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.deactivateEmi),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }

    setState(() => _isUpdating = true);
    try {
      await widget.onStatusChanged(isActive);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.emiStatusUpdated)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.emiStatusUpdateFailed),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final emi = widget.emi;
    final statusLabel = emi.isCompleted
        ? l10n.emiCompleted
        : emi.isActive
        ? l10n.active
        : l10n.inactive;

    return Card(
      elevation: 0,
      color: emi.isActive || emi.isCompleted
          ? colors.surfaceContainerLow
          : colors.surfaceContainerLow.withValues(alpha: 0.7),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    emi.title,
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                if (!emi.isCompleted)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        statusLabel,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: emi.isActive
                                  ? colors.primary
                                  : colors.onSurfaceVariant,
                            ),
                      ),
                      if (_isUpdating)
                        const SizedBox(
                          width: 40,
                          height: 32,
                          child: Center(
                            child: SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        )
                      else
                        Switch.adaptive(
                          value: emi.isActive,
                          onChanged: _changeStatus,
                        ),
                    ],
                  )
                else
                  Chip(
                    label: Text(statusLabel),
                    backgroundColor: colors.tertiaryContainer,
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              widget.currencyFormat.format(emi.amount),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.primary,
              ),
            ),
            const SizedBox(height: 12),
            _EmiDetailRow(
              icon: Icons.calendar_today_outlined,
              text: l10n.dueOnEveryMonth(emi.dueDateDay.toString()),
            ),
            if (emi.startDate != null)
              _EmiDetailRow(
                icon: Icons.event_outlined,
                text: l10n.emiStartDate(_formatDate(context, emi.startDate!)),
              ),
            if (emi.endDate != null)
              _EmiDetailRow(
                icon: Icons.event_available_outlined,
                text: l10n.emiEndDate(_formatDate(context, emi.endDate!)),
              ),
            if (emi.durationMonths != null)
              _EmiDetailRow(
                icon: Icons.timelapse_outlined,
                text: l10n.emiDurationMonths(emi.durationMonths!),
              ),
            if (emi.totalInstallments != null)
              _EmiDetailRow(
                icon: Icons.format_list_numbered_outlined,
                text: l10n.emiTotalInstallments(emi.totalInstallments!),
              ),
            if (emi.paidInstallments != null &&
                emi.totalInstallments != null) ...[
              const SizedBox(height: 10),
              Text(
                l10n.emiInstallmentProgress(
                  emi.paidInstallments!,
                  emi.totalInstallments!,
                  emi.remainingInstallments ??
                      (emi.totalInstallments! - emi.paidInstallments!),
                ),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: emi.totalInstallments! > 0
                    ? (emi.paidInstallments! / emi.totalInstallments!).clamp(
                        0,
                        1,
                      )
                    : 0,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(BuildContext context, DateTime date) =>
      DateFormat.yMMMd(Localizations.localeOf(context).toString()).format(date);
}

class _EmiDetailRow extends StatelessWidget {
  const _EmiDetailRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: colors.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: colors.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddEmiFormSheet extends ConsumerStatefulWidget {
  const _AddEmiFormSheet({required this.onSave});

  final VoidCallback onSave;

  @override
  ConsumerState<_AddEmiFormSheet> createState() => _AddEmiFormSheetState();
}

class _AddEmiFormSheetState extends ConsumerState<_AddEmiFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _customDurationController = TextEditingController();

  int _selectedDueDateDay = 5;
  int _selectedDurationMonths = 12;
  DateTime _selectedStartDate = DateTime.now();
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _customDurationController.dispose();
    super.dispose();
  }

  Future<void> _submitEmi() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;

    final title = _titleController.text.trim();
    final amount = double.parse(_amountController.text.trim());
    final durationMonths = _selectedDurationMonths == 0
        ? int.parse(_customDurationController.text.trim())
        : _selectedDurationMonths;

    setState(() => _isSaving = true);

    try {
      await ref
          .read(emiRepositoryProvider)
          .addEmi(
            title: title,
            amount: amount,
            dueDateDay: _selectedDueDateDay,
            startDate: _selectedStartDate,
            durationMonths: durationMonths,
          );

      widget.onSave();

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.emiAdded)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.operationFailedWithDetails(error.toString())),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final l10n = AppLocalizations.of(context)!;
    final durationMonths = _selectedDurationMonths == 0
        ? int.tryParse(_customDurationController.text.trim())
        : _selectedDurationMonths;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, bottomInset + 24),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.addNewEmi,
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // Title Input
              TextFormField(
                controller: _titleController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: l10n.emiTitle,
                  hintText: l10n.emiTitleHint,
                  prefixIcon: Icon(Icons.title_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.emiTitleRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Amount Input
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: l10n.monthlyAmount,
                  hintText: '0.00',
                  prefixIcon: Icon(Icons.currency_rupee),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final amount = double.tryParse(value?.trim() ?? '');
                  if (amount == null || !amount.isFinite || amount <= 0) {
                    return l10n.positiveAmountRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<int>(
                initialValue: _selectedDurationMonths,
                decoration: InputDecoration(
                  labelText: l10n.emiDuration,
                  prefixIcon: const Icon(Icons.timelapse_outlined),
                  border: const OutlineInputBorder(),
                ),
                items: [
                  for (final months in [6, 12, 24, 36, 48, 60])
                    DropdownMenuItem(
                      value: months,
                      child: Text(l10n.emiDurationMonths(months)),
                    ),
                  DropdownMenuItem(
                    value: 0,
                    child: Text(l10n.emiCustomDuration),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedDurationMonths = value);
                  }
                },
              ),
              if (_selectedDurationMonths == 0) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _customDurationController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: l10n.emiCustomDurationMonths,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (_selectedDurationMonths != 0) return null;
                    final months = int.tryParse(value?.trim() ?? '');
                    if (months == null || months <= 0) {
                      return l10n.emiDurationRequired;
                    }
                    return null;
                  },
                ),
              ],
              if (durationMonths != null && durationMonths > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    l10n.emiDurationYears(
                      durationMonths,
                      (durationMonths / 12).toStringAsFixed(
                        durationMonths % 12 == 0 ? 0 : 1,
                      ),
                    ),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _isSaving
                    ? null
                    : () async {
                        final selected = await showDatePicker(
                          context: context,
                          initialDate: _selectedStartDate,
                          firstDate: DateTime(1900),
                          lastDate: DateTime(2100),
                        );
                        if (selected != null && mounted) {
                          setState(() => _selectedStartDate = selected);
                        }
                      },
                icon: const Icon(Icons.event_outlined),
                label: Text(
                  l10n.emiStartDate(
                    DateFormat.yMMMd(Localizations.localeOf(context).toString())
                        .format(_selectedStartDate),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Due Date Day Dropdown
              DropdownButtonFormField<int>(
                initialValue: _selectedDueDateDay,
                decoration: InputDecoration(
                  labelText: l10n.dueDateDay,
                  prefixIcon: Icon(Icons.calendar_month_outlined),
                  border: OutlineInputBorder(),
                ),
                items: List.generate(
                  31,
                  (index) => DropdownMenuItem<int>(
                    value: index + 1,
                    child: Text(l10n.dayOfMonth(index + 1)),
                  ),
                ),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedDueDateDay = value);
                  }
                },
              ),
              const SizedBox(height: 24),

              // Submit Button
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _submitEmi,
                icon: _isSaving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check),
                label: Text(l10n.saveEmi),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
