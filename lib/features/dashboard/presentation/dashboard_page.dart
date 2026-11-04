import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kaasutracker/core/localization/generated/app_localizations.dart';
import 'package:kaasutracker/core/localization/expense_category_localization.dart';
import 'package:kaasutracker/core/routing/app_router.dart';
import 'package:kaasutracker/features/dashboard/presentation/monthly_salary_dialog.dart';
import 'package:kaasutracker/features/expenses/data/expense.dart';
import 'package:kaasutracker/features/expenses/data/expense_period.dart';
import 'package:kaasutracker/features/expenses/data/expenses_provider.dart';
import 'package:kaasutracker/features/emis/data/emis_provider.dart';
import 'package:kaasutracker/features/emis/data/emi_model.dart';
import 'package:kaasutracker/features/finance/data/finance_models.dart';
import 'package:kaasutracker/features/finance/data/finance_error.dart';
import 'package:kaasutracker/features/finance/data/finance_repository.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  bool _showEmiSchedule = false;
  bool _showRecentExpenses = false;
  bool _isSavingSalary = false;
  bool _isEstablishingCarryForward = false;

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
      case 'dining':
      case 'restaurant':
        return Icons.restaurant_outlined;
      case 'travel':
      case 'transport':
      case 'fuel':
        return Icons.directions_car_outlined;
      case 'utilities':
      case 'bills':
        return Icons.receipt_long_outlined;
      case 'shopping':
        return Icons.shopping_bag_outlined;
      default:
        return Icons.account_balance_wallet_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toString();
    final currencyFormat = NumberFormat.currency(
      locale: locale,
      symbol: '₹',
      decimalDigits: 2,
    );
    final dateFormat = DateFormat.yMMMd(locale);

    final period = ref.watch(selectedFinancePeriodProvider);
    final selectedMonth = period.firstDay;
    final summaryAsync = ref.watch(monthlyFinancialSummaryProvider(period));
    final expensesAsync = ref.watch(expensesProvider);
    final emisAsync = ref.watch(emisProvider);
    final monthlyExpensesAsync = expensesAsync.whenData(
      (expenses) => expenses
          .where((expense) => expenseIsInPeriod(expense, period))
          .toList(growable: false),
    );
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.dashboardTitle),
        centerTitle: false,
        actions: [
          if (_isSavingSalary || _isEstablishingCarryForward)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            PopupMenuButton<String>(
              tooltip: l10n.fundsTitle,
              onSelected: (action) async {
                switch (action) {
                  case 'borrowed':
                    context.push(AppRoutes.borrowedFunds);
                  case 'carry-forward':
                    if (_isEstablishingCarryForward) return;
                    setState(() => _isEstablishingCarryForward = true);
                    try {
                      await ref
                          .read(financeRepositoryProvider)
                          .establishCarryForward(period);
                      if (!mounted) return;
                      ref.invalidate(monthlyFinancialSummaryProvider(period));
                      ref.invalidate(carryForwardProvider(period));
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.carryForwardEstablished)),
                      );
                    } catch (error) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(financeErrorMessage(context, error)),
                          backgroundColor: colors.error,
                        ),
                      );
                    } finally {
                      if (mounted) {
                        setState(() => _isEstablishingCarryForward = false);
                      }
                    }
                  case 'salary':
                    await _setMonthlySalary(context, period);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'borrowed',
                  child: Text(l10n.borrowedFundsTitle),
                ),
                PopupMenuItem(
                  value: 'carry-forward',
                  child: Text(l10n.establishCarryForward),
                ),
                PopupMenuItem(
                  value: 'salary',
                  child: Text(l10n.setMonthlySalary),
                ),
              ],
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.addExpense),
        icon: const Icon(Icons.add),
        label: Text(l10n.addExpense),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(monthlyFinancialSummaryProvider(period));
          ref.invalidate(expensesProvider);
          ref.invalidate(emisProvider);
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
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 88),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildMonthSelector(context, selectedMonth),
              const SizedBox(height: 16),
              _buildOverview(
                context: context,
                currencyFormat: currencyFormat,
                summaryAsync: summaryAsync,
                selectedMonth: selectedMonth,
              ),
              const SizedBox(height: 24),
              _buildEmiSchedule(context, currencyFormat, emisAsync),
              const SizedBox(height: 24),
              _buildRecentExpenses(
                context: context,
                colors: colors,
                dateFormat: dateFormat,
                currencyFormat: currencyFormat,
                expensesAsync: monthlyExpensesAsync,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMonthSelector(BuildContext context, DateTime selectedMonth) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final isCurrentMonth =
        selectedMonth.year == now.year && selectedMonth.month == now.month;

    return Row(
      children: [
        IconButton(
          tooltip: l10n.previousMonth,
          onPressed: () => _changeMonth(selectedMonth, -1),
          icon: const Icon(Icons.chevron_left),
        ),
        Expanded(
          child: Text(
            DateFormat.yMMMM(Localizations.localeOf(context).toString())
                .format(selectedMonth),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        IconButton(
          tooltip: l10n.nextMonth,
          onPressed: () => _changeMonth(selectedMonth, 1),
          icon: const Icon(Icons.chevron_right),
        ),
        if (!isCurrentMonth)
          TextButton(
            onPressed: () => _selectMonth(DateTime(now.year, now.month)),
            child: Text(l10n.today),
          ),
      ],
    );
  }

  void _changeMonth(DateTime selectedMonth, int offset) {
    _selectMonth(DateTime(selectedMonth.year, selectedMonth.month + offset));
  }

  void _selectMonth(DateTime selectedMonth) {
    ref
        .read(selectedFinancePeriodProvider.notifier)
        .select(FinancePeriod.fromDate(selectedMonth));
  }

  Future<void> _setMonthlySalary(
    BuildContext context,
    FinancePeriod period,
  ) async {
    if (_isSavingSalary) return;
    final summary = ref.read(monthlyFinancialSummaryProvider(period)).value;
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => MonthlySalaryDialog(
        period: period,
        initialAmount: summary?.baseMonthlySalary ?? 0,
        onSavingChanged: (isSaving) {
          if (mounted) setState(() => _isSavingSalary = isSaving);
        },
      ),
    );
    if (!mounted || !context.mounted || saved != true) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.salarySaved)),
    );
  }

  Widget _buildOverview({
    required BuildContext context,
    required NumberFormat currencyFormat,
    required AsyncValue<MonthlyFinancialSummary> summaryAsync,
    required DateTime selectedMonth,
  }) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return summaryAsync.when(
      loading: () => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(l10n.summaryLoading)),
              ],
            ),
          ),
        ),
      ),
      error: (error, stack) => Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(Icons.error_outline, color: colors.error, size: 36),
              const SizedBox(height: 8),
              Text(l10n.summaryUnavailable),
              const SizedBox(height: 4),
              Text(
                financeErrorMessage(context, error),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () {
                  final period = FinancePeriod.fromDate(selectedMonth);
                  ref.invalidate(monthlyFinancialSummaryProvider(period));
                },
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
      ),
      data: (summary) {
        final overspent = summary.unfundedOverspending > 0;
        final hasActivity =
            summary.totalEligibleActualExpenses > 0 ||
            summary.additionalFundsReceived > 0 ||
            summary.borrowedFundsReceived > 0 ||
            summary.openingCarryForwardBalance > 0;
        final salaryPercentage = summary.baseMonthlySalary > 0
            ? summary.salaryFundedExpenses / summary.baseMonthlySalary
            : null;
        final statusColor = overspent ? colors.error : colors.primary;
        String amount(int minorUnits) =>
            currencyFormat.format(minorUnits / 100);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (summary.baseMonthlySalary <= 0)
              Card(
                color: colors.tertiaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text(
                    l10n.salarySetupRequired,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colors.onTertiaryContainer),
                  ),
                ),
              ),
            if (!hasActivity)
              Card(
                color: colors.surfaceContainerLow,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text(l10n.emptyMonth, textAlign: TextAlign.center),
                ),
              ),
            Card(
              elevation: 0,
              color: statusColor.withValues(alpha: 0.08),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(color: statusColor.withValues(alpha: 0.22)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.baseMonthlySalary,
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(color: colors.onSurfaceVariant),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                amount(summary.baseMonthlySalary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: statusColor,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        if (salaryPercentage != null)
                          Chip(
                            label: Text(
                              l10n.percentUsed(
                                (salaryPercentage * 100).round().toString(),
                              ),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                            backgroundColor: statusColor.withValues(
                              alpha: 0.12,
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat.yMMMM(
                        Localizations.localeOf(context).toString(),
                      ).format(selectedMonth),
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: colors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: (salaryPercentage ?? 0).clamp(0.0, 1.0),
                        minHeight: 8,
                        backgroundColor: colors.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _summaryRow(
                      context,
                      l10n.salaryFundedExpenses,
                      amount(summary.salaryFundedExpenses),
                    ),
                    _summaryRow(
                      context,
                      l10n.remainingSalary,
                      amount(summary.remainingSalaryAvailable),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth >= 600
                    ? (constraints.maxWidth - 24) / 3
                    : (constraints.maxWidth - 12) / 2;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _metricTile(
                      context,
                      width: width,
                      label: l10n.carryForwardUsed,
                      value: amount(summary.carryForwardUsed),
                      detail:
                          '${l10n.carryForwardRemaining}: ${amount(summary.remainingCarryForwardAvailable)}',
                      icon: Icons.history,
                    ),
                    _metricTile(
                      context,
                      width: width,
                      label: l10n.borrowedFundsUsed,
                      value: amount(summary.borrowedFundsUsed),
                      detail:
                          '${l10n.fundsRemaining}: ${amount(summary.remainingBorrowedFundsAvailable)}',
                      icon: Icons.currency_exchange,
                    ),
                    _metricTile(
                      context,
                      width: width,
                      label: l10n.actualExpenses,
                      value: amount(summary.totalEligibleActualExpenses),
                      detail: DateFormat.yMMMM(
                        Localizations.localeOf(context).toString(),
                      ).format(selectedMonth),
                      icon: Icons.shopping_bag_outlined,
                    ),
                    _metricTile(
                      context,
                      width: width,
                      label: l10n.combinedRemaining,
                      value: amount(summary.totalRemainingFunding),
                      detail:
                          '${l10n.additionalFundsAvailable}: '
                          '${amount(summary.remainingAdditionalFundsAvailable)}',
                      icon: Icons.account_balance_outlined,
                    ),
                    if (overspent)
                      _metricTile(
                        context,
                        width: width,
                        label: l10n.unfundedOverspending,
                        value: amount(summary.unfundedOverspending),
                        detail: l10n.actualExpenses,
                        icon: Icons.warning_amber_rounded,
                        color: colors.error,
                      ),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _summaryRow(BuildContext context, String label, String value) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
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

  Widget _buildEmiSchedule(
    BuildContext context,
    NumberFormat currencyFormat,
    AsyncValue<List<EmiModel>> emisAsync,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toString();
    void toggleSchedule() {
      setState(() => _showEmiSchedule = !_showEmiSchedule);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          child: Semantics(
            button: true,
            label: _showEmiSchedule
                ? l10n.collapseEmiSchedule
                : l10n.expandEmiSchedule,
            child: Tooltip(
              message: _showEmiSchedule
                  ? l10n.collapseEmiSchedule
                  : l10n.expandEmiSchedule,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: toggleSchedule,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.emiSchedule,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      AnimatedRotation(
                        turns: _showEmiSchedule ? 0.5 : 0,
                        duration: const Duration(milliseconds: 180),
                        child: const Icon(Icons.keyboard_arrow_down),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: _showEmiSchedule
              ? Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Card(
                    elevation: 0,
                    color: colors.surfaceContainerLow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: emisAsync.when(
                        loading: () => const Padding(
                          padding: EdgeInsets.all(12),
                          child: Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        error: (error, stack) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.emiLoadError,
                              style: TextStyle(color: colors.error),
                            ),
                            TextButton(
                              onPressed: () => ref.invalidate(emisProvider),
                              child: Text(l10n.retry),
                            ),
                          ],
                        ),
                        data: (emis) {
                          final schedule = buildEmiSchedule(
                            emis,
                            now: DateTime.now(),
                          );
                          if (schedule.isEmpty) {
                            return Text(l10n.noScheduledEmis);
                          }

                          final totalScheduled = schedule.fold<double>(
                            0,
                            (total, item) => total + item.emi.amount,
                          );
                          final dueToday = schedule
                              .where(
                                (item) =>
                                    item.statusFor(DateTime.now()) ==
                                    EmiScheduleStatus.dueToday,
                              )
                              .fold<double>(
                                0,
                                (total, item) => total + item.emi.amount,
                              );
                          final nextDueDate = schedule.first.dueDate;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _summaryRow(
                                context,
                                l10n.monthlyEmiScheduled,
                                currencyFormat.format(totalScheduled),
                              ),
                              _summaryRow(
                                context,
                                l10n.emiDueToday,
                                currencyFormat.format(dueToday),
                              ),
                              _summaryRow(
                                context,
                                l10n.nextEmiDue,
                                DateFormat.yMMMd(locale).format(nextDueDate),
                              ),
                              const Divider(height: 20),
                              for (final item in schedule)
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    item.emi.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    DateFormat.yMMMd(locale)
                                        .format(item.dueDate),
                                  ),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        currencyFormat.format(item.emi.amount),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        item.statusFor(DateTime.now()) ==
                                                EmiScheduleStatus.dueToday
                                            ? l10n.emiDueToday
                                            : l10n.emiScheduled,
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(
                                              color: colors.onSurfaceVariant,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }

  Widget _metricTile(
    BuildContext context, {
    required double width,
    required String label,
    required String value,
    required String detail,
    required IconData icon,
    Color? color,
  }) {
    final colors = Theme.of(context).colorScheme;
    final valueColor = color ?? colors.onSurface;
    return SizedBox(
      width: width,
      child: Container(
        constraints: const BoxConstraints(minHeight: 112),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color ?? colors.primary),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium
                        ?.copyWith(color: colors.onSurfaceVariant),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold, color: valueColor),
            ),
            const SizedBox(height: 3),
            Text(
              detail,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentExpenses({
    required BuildContext context,
    required ColorScheme colors,
    required DateFormat dateFormat,
    required NumberFormat currencyFormat,
    required AsyncValue<List<Expense>> expensesAsync,
  }) {
    final expenses = [...(expensesAsync.value ?? const <Expense>[])]
      ..sort((a, b) => b.expenseDate.compareTo(a.expenseDate));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () =>
                setState(() => _showRecentExpenses = !_showRecentExpenses),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)!.recentExpenses,
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => context.push(AppRoutes.addExpense),
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(AppLocalizations.of(context)!.add),
                  ),
                  IconButton(
                    tooltip: _showRecentExpenses
                        ? AppLocalizations.of(context)!.collapseRecentExpenses
                        : AppLocalizations.of(context)!.expandRecentExpenses,
                    onPressed: () => setState(
                      () => _showRecentExpenses = !_showRecentExpenses,
                    ),
                    icon: AnimatedRotation(
                      turns: _showRecentExpenses ? 0.5 : 0,
                      duration: const Duration(milliseconds: 180),
                      child: const Icon(Icons.keyboard_arrow_down),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_showRecentExpenses) ...[
          const SizedBox(height: 12),
          expensesAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 36),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, stack) => Card(
              color: colors.errorContainer.withValues(alpha: 0.3),
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(Icons.error_outline, color: colors.error, size: 36),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context)!.recentExpensesLoadError,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () => ref.invalidate(expensesProvider),
                      child: Text(AppLocalizations.of(context)!.retry),
                    ),
                  ],
                ),
              ),
            ),
            data: (_) {
              if (expenses.isEmpty) {
                return Card(
                  elevation: 0,
                  color: colors.surfaceContainerLow,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 48,
                          color: colors.outline,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          AppLocalizations.of(context)!.noExpensesRecorded,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppLocalizations.of(context)!.startExpenseTracking,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: expenses.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final expense = expenses[index];
                  return Card(
                    elevation: 0,
                    color: colors.surfaceContainerLow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      onTap: int.tryParse(expense.id) == null
                          ? null
                          : () => context.push(
                              AppRoutes.expenseDetails(int.parse(expense.id)),
                            ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: colors.primaryContainer.withValues(
                          alpha: 0.6,
                        ),
                        child: Icon(
                          _getCategoryIcon(expense.category),
                          color: colors.primary,
                          size: 22,
                        ),
                      ),
                      title: Text(
                        expense.description,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Row(
                        children: [
                          Text(
                            dateFormat.format(expense.expenseDate.toLocal()),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colors.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              localizedExpenseCategory(
                                expense.category,
                                AppLocalizations.of(context)!,
                              ),
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(color: colors.onSurfaceVariant),
                            ),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            currencyFormat.format(
                              expense.eligibleAmountMinorUnits / 100,
                            ),
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colors.primary,
                                ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.chevron_right, size: 20),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ],
    );
  }
}
