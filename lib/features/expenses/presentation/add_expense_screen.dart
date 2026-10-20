import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:kaasutracker/core/network/api_service.dart';
import 'package:kaasutracker/features/expenses/data/expenses_provider.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imagePicker = ImagePicker();
  final _dateFormat = DateFormat.yMMMd();
  final _expenseDateFormat = DateFormat('yyyy-MM-dd');

  static const _categories = ['Travel', 'Food', 'Utilities', 'Shopping'];
  String _category = _categories.first;
  DateTime _date = DateTime.now();
  bool _isSaving = false;
  bool _isAnalyzing = false;

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

  Future<ImageSource?> _showImageSourcePicker() async {
    return showModalBottomSheet<ImageSource>(
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
                'Scan Receipt',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Take a Photo (Camera)'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from Gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _scanReceipt() async {
    final source = await _showImageSourcePicker();
    if (source == null) return;

    try {
      final image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (image == null || !mounted) return;

      setState(() => _isAnalyzing = true);

      final imageBytes = await image.readAsBytes();
      final base64Image = base64Encode(imageBytes);

      final response = await ref
          .read(apiServiceProvider)
          .analyzeReceipt(base64Image);

      final analysis = _parseAnalysisResponse(response);

      if (!mounted) return;
      setState(() {
        _amountController.text = analysis.amount;
        _descriptionController.text = analysis.description;
        _category = analysis.category;
        _date = analysis.date;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Receipt analyzed. Details automatically populated!'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not analyze receipt: $error'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  _ExpenseAnalysis _parseAnalysisResponse(Map<String, dynamic> response) {
    final amountValue = response['amount'];
    final categoryValue = response['category'];
    final descriptionValue = response['description'] ?? response['merchant'];
    final dateValue = response['expenseDate'];

    final amount = amountValue is num
        ? amountValue.toDouble()
        : amountValue is String
            ? double.tryParse(amountValue)
            : null;

    if (amount == null || !amount.isFinite || amount <= 0) {
      throw const FormatException(
        'Analysis response must include a valid positive amount.',
      );
    }

    final categoryStr = (categoryValue is String && categoryValue.trim().isNotEmpty)
        ? categoryValue.trim()
        : 'Shopping';

    final descriptionStr = (descriptionValue is String && descriptionValue.trim().isNotEmpty)
        ? descriptionValue.trim()
        : 'Receipt Expense';

    DateTime parsedDate = DateTime.now();
    if (dateValue is String && dateValue.trim().isNotEmpty) {
      try {
        parsedDate = DateTime.parse(dateValue.trim());
      } catch (_) {
        parsedDate = DateTime.now();
      }
    }

    return _ExpenseAnalysis(
      amount: amount.toStringAsFixed(2),
      category: categoryStr,
      description: descriptionStr,
      date: parsedDate,
    );
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;

    final payload = {
      'amount': double.parse(_amountController.text.trim()),
      'category': _category,
      'merchant': 'Manual Entry',
      'description': _descriptionController.text.trim(),
      'expenseDate': _expenseDateFormat.format(_date),
      'receiptUrl': null,
      'isConfirmed': true,
    };

    setState(() => _isSaving = true);
    try {
      await ref.read(apiServiceProvider).post('expenses', body: payload);

      ref.invalidate(expensesProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expense saved successfully.')),
      );
      context.pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not save expense: $error'),
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

    final categories = [
      ..._categories,
      if (!_categories.contains(_category)) _category,
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Add expense'), centerTitle: false),
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
                            'How much did you spend?',
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
                                return 'Enter an amount greater than zero.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 28),
                          DropdownButtonFormField<String>(
                            initialValue: _category,
                            decoration: const InputDecoration(
                              labelText: 'Category',
                              prefixIcon: Icon(Icons.category_outlined),
                              border: OutlineInputBorder(),
                            ),
                            items: categories
                                .map(
                                  (category) => DropdownMenuItem(
                                    value: category,
                                    child: Text(category),
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
                              decoration: const InputDecoration(
                                labelText: 'Date',
                                prefixIcon: Icon(Icons.calendar_today_outlined),
                                border: OutlineInputBorder(),
                              ),
                              child: Text(_dateFormat.format(_date)),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _descriptionController,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: const InputDecoration(
                              labelText: 'Description',
                              hintText: 'What was this expense for?',
                              prefixIcon: Icon(Icons.notes_outlined),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Add a short description.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          OutlinedButton.icon(
                            onPressed: _isAnalyzing || _isSaving
                                ? null
                                : _scanReceipt,
                            icon: const Icon(Icons.camera_alt_outlined),
                            label: const Text('Scan Receipt'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
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
                          : const Text('Save Expense'),
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
                            'Analyzing receipt…',
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
}

class _ExpenseAnalysis {
  const _ExpenseAnalysis({
    required this.amount,
    required this.category,
    required this.description,
    required this.date,
  });

  final String amount;
  final String category;
  final String description;
  final DateTime date;
}
