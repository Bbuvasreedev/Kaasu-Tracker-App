import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kaasutracker/core/localization/generated/app_localizations.dart';
import 'package:kaasutracker/core/localization/expense_category_localization.dart';
import 'package:kaasutracker/core/network/api_service.dart';
import 'package:kaasutracker/features/expenses/data/receipt_scanner.dart';
import 'package:kaasutracker/features/expenses/data/expenses_provider.dart';
import 'package:kaasutracker/features/finance/data/finance_models.dart';
import 'package:kaasutracker/features/finance/data/finance_repository.dart';
import 'package:permission_handler/permission_handler.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _expenseDateFormat = DateFormat('yyyy-MM-dd');

  static const _categories = ['Travel', 'Food', 'Utilities', 'Shopping'];
  String _category = _categories.first;
  DateTime _date = DateTime.now();
  bool _isSaving = false;
  bool _isAnalyzing = false;
  ReceiptFile? _receiptFile;
  ReceiptAnalysis? _receiptAnalysis;
  String? _receiptError;

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
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

  Future<ReceiptSource?> _showImageSourcePicker() async {
    final l10n = AppLocalizations.of(context)!;
    return showModalBottomSheet<ReceiptSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.scanReceipt,
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: Text(l10n.takePhoto),
                onTap: () => Navigator.pop(context, ReceiptSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(l10n.chooseGallery),
                onTap: () => Navigator.pop(context, ReceiptSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.insert_drive_file_outlined),
                title: Text(l10n.chooseDocument),
                onTap: () => Navigator.pop(context, ReceiptSource.document),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _scanReceipt() async {
    final l10n = AppLocalizations.of(context)!;
    final source = await _showImageSourcePicker();
    if (source == null) return;

    try {
      final receipt = await ref.read(receiptMediaPickerProvider).pick(source);
      if (receipt == null || !mounted) return;
      await ref.read(receiptScannerProvider).validate(receipt);
      if (!mounted) return;
      setState(() {
        _receiptFile = receipt;
        _receiptAnalysis = null;
        _receiptError = null;
      });
    } on ReceiptPickerException catch (error) {
      if (!mounted) return;
      if (error.canOpenSettings) {
        await _showPermissionSettingsDialog(l10n);
      } else if (error.isPermissionDenied) {
        _showReceiptError(l10n.cameraPermissionDenied);
      } else {
        _showReceiptError(l10n.receiptReadError);
      }
    } on ReceiptFileException catch (error) {
      if (!mounted) return;
      _showReceiptError(_fileIssueMessage(error.issue, l10n));
    } on FileSystemException {
      if (mounted) _showReceiptError(l10n.receiptReadError);
    } catch (_) {
      if (mounted) _showReceiptError(l10n.receiptReadError);
    }
  }

  Future<void> _analyzeReceipt() async {
    final receipt = _receiptFile;
    if (receipt == null || receipt.isPdf || _isAnalyzing || _isSaving) return;
    setState(() {
      _isAnalyzing = true;
      _receiptError = null;
    });
    try {
      final analysis = await ref.read(receiptScannerProvider).analyze(receipt);
      if (!mounted) return;
      setState(() {
        _receiptAnalysis = analysis;
        if (analysis.amount != null && analysis.amount! > 0) {
          _amountController.text = analysis.amount!.toStringAsFixed(2);
        }
        final category = analysis.category;
        if (category != null && category.isNotEmpty) _category = category;
        final description = analysis.merchant ?? analysis.description;
        if (description != null) _descriptionController.text = description;
        if (analysis.expenseDate != null) _date = analysis.expenseDate!;
      });
    } on ReceiptFileException catch (error) {
      if (mounted) {
        _showReceiptError(
          _fileIssueMessage(error.issue, AppLocalizations.of(context)!),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () =>
              _receiptError = AppLocalizations.of(context)!
                  .receiptAnalysisFailed,
        );
      }
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  String _fileIssueMessage(ReceiptFileIssue issue, AppLocalizations l10n) {
    return switch (issue) {
      ReceiptFileIssue.empty => l10n.receiptEmptyFile,
      ReceiptFileIssue.tooLarge => l10n.receiptFileTooLarge,
      ReceiptFileIssue.unsupported => l10n.receiptUnsupportedFormat,
      ReceiptFileIssue.invalid => l10n.receiptInvalidFile,
      ReceiptFileIssue.pdfUnsupported => l10n.receiptPdfUnsupported,
    };
  }

  void _showReceiptError(String message) {
    setState(() => _receiptError = message);
  }

  Future<void> _showPermissionSettingsDialog(AppLocalizations l10n) async {
    final openSettings = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.cameraPermissionRequired),
        content: Text(l10n.cameraPermissionPermanent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.openAppSettings),
          ),
        ],
      ),
    );
    if (openSettings == true) await openAppSettings();
  }

  Future<void> _saveExpense() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;

    final payload = {
      'amount': double.parse(_amountController.text.trim()),
      'category': _category,
      'merchant': _receiptFile == null
          ? 'Manual Entry'
          : (_receiptAnalysis?.merchant ?? _descriptionController.text.trim()),
      'description': _descriptionController.text.trim(),
      'expenseDate': _expenseDateFormat.format(_date),
      'receiptUrl': null,
      'isConfirmed': true,
    };

    setState(() => _isSaving = true);
    try {
      await ref.read(apiServiceProvider).post('expenses', body: payload);

      ref.invalidate(expensesProvider);
      ref.invalidate(
        monthlyFinancialSummaryProvider(FinancePeriod.fromDate(_date)),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.expenseSaved)));
      context.pop();
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
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();

    final categories = [
      ..._categories,
      if (!_categories.contains(_category)) _category,
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.addExpenseTitle), centerTitle: false),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            l10n.spendQuestion,
                            style: Theme.of(context).textTheme.titleMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _amountController,
                            autofocus: true,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.displaySmall
                                ?.copyWith(
                                  color: colors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                            decoration: InputDecoration(
                              prefixText: '₹ ',
                              prefixStyle: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(color: colors.primary),
                              hintText: '0.00',
                              filled: true,
                              fillColor: colors.primaryContainer.withValues(
                                alpha: 0.35,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            validator: (value) {
                              final amount = double.tryParse(
                                value?.trim() ?? '',
                              );
                              if (amount == null ||
                                  !amount.isFinite ||
                                  amount <= 0) {
                                return l10n.amountRequired;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 28),
                          DropdownButtonFormField<String>(
                            initialValue: _category,
                            decoration: InputDecoration(
                              labelText: l10n.categoryLabel,
                              prefixIcon: Icon(Icons.category_outlined),
                              border: OutlineInputBorder(),
                            ),
                            items: categories
                                .map(
                                  (category) => DropdownMenuItem(
                                    value: category,
                                    child: Text(
                                      localizedExpenseCategory(category, l10n),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _category = value);
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          InkWell(
                            onTap: _selectDate,
                            borderRadius: BorderRadius.circular(12),
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: l10n.dateLabel,
                                prefixIcon: Icon(Icons.calendar_today_outlined),
                                border: OutlineInputBorder(),
                              ),
                              child: Text(
                                DateFormat.yMMMd(locale).format(_date),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _descriptionController,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: InputDecoration(
                              labelText: l10n.descriptionLabel,
                              hintText: l10n.expenseDescriptionHint,
                              prefixIcon: Icon(Icons.notes_outlined),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return l10n.shortDescriptionRequired;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          if (_receiptFile != null) ...[
                            _buildReceiptPreview(context, l10n),
                            const SizedBox(height: 12),
                          ],
                          if (_receiptAnalysis != null) ...[
                            _buildReceiptSuggestions(context, l10n),
                            const SizedBox(height: 12),
                          ],
                          if (_receiptError != null) ...[
                            Card(
                              color: colors.errorContainer,
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _receiptError!,
                                      style: TextStyle(
                                        color: colors.onErrorContainer,
                                      ),
                                    ),
                                    if (_receiptFile != null &&
                                        !_receiptFile!.isPdf) ...[
                                      const SizedBox(height: 8),
                                      TextButton.icon(
                                        onPressed: _isAnalyzing || _isSaving
                                            ? null
                                            : _analyzeReceipt,
                                        icon: const Icon(Icons.refresh),
                                        label: Text(l10n.retry),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          OutlinedButton.icon(
                            onPressed: _isAnalyzing || _isSaving
                                ? null
                                : _scanReceipt,
                            icon: const Icon(Icons.camera_alt_outlined),
                            label: Text(l10n.scanReceipt),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                          if (_receiptFile != null && !_receiptFile!.isPdf) ...[
                            const SizedBox(height: 8),
                            FilledButton.tonalIcon(
                              onPressed: _isAnalyzing || _isSaving
                                  ? null
                                  : _analyzeReceipt,
                              icon: const Icon(Icons.auto_awesome_outlined),
                              label: Text(l10n.analyzeReceipt),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving || _isAnalyzing
                          ? null
                          : _saveExpense,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isSaving
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(l10n.saveExpense),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isAnalyzing)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.45),
                child: Center(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 24,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(
                            l10n.analyzingReceipt,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReceiptPreview(BuildContext context, AppLocalizations l10n) {
    final colors = Theme.of(context).colorScheme;
    final receipt = _receiptFile!;
    return Card(
      color: colors.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.receiptPreview,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                IconButton(
                  tooltip: l10n.removeReceipt,
                  onPressed: _isAnalyzing || _isSaving
                      ? null
                      : () => setState(() {
                          _receiptFile = null;
                          _receiptAnalysis = null;
                          _receiptError = null;
                        }),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            if (receipt.isPdf)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.picture_as_pdf_outlined, size: 36),
                title: Text(receipt.name, maxLines: 2),
                subtitle: Text(l10n.receiptPdfUnsupported),
              )
            else
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  receipt.bytes,
                  height: 190,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => SizedBox(
                    height: 120,
                    child: Center(child: Text(l10n.receiptInvalidFile)),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Text(
              '${receipt.name} · '
              '${(receipt.bytes.length / (1024 * 1024)).toStringAsFixed(2)} MB',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptSuggestions(BuildContext context, AppLocalizations l10n) {
    final analysis = _receiptAnalysis!;
    final details = <String>[
      if (analysis.subtotal != null)
        '${l10n.receiptSubtotal}: ${analysis.subtotal}',
      if (analysis.tax != null) '${l10n.receiptTax}: ${analysis.tax}',
      if (analysis.discount != null)
        '${l10n.receiptDiscount}: ${analysis.discount}',
      if (analysis.currency != null)
        '${l10n.receiptCurrency}: ${analysis.currency}',
      if (analysis.paymentMethod != null)
        '${l10n.receiptPaymentMethod}: ${analysis.paymentMethod}',
      if (analysis.invoiceNumber != null)
        '${l10n.receiptInvoiceNumber}: ${analysis.invoiceNumber}',
      for (final item in analysis.items)
        '${item.name}${item.price == null ? '' : ': ${item.price}'}',
    ];
    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.receiptSuggestionsNotice,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (details.isNotEmpty) ...[
              const SizedBox(height: 8),
              for (final detail in details)
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(detail),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
