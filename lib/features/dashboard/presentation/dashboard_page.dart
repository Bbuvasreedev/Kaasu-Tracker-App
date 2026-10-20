import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kaasutracker/core/routing/app_router.dart';
import 'package:kaasutracker/features/emis/data/emi_model.dart';
import 'package:kaasutracker/features/emis/data/emis_provider.dart';
import 'package:kaasutracker/features/expenses/data/expense.dart';
import 'package:kaasutracker/features/expenses/data/expenses_provider.dart';
import 'package:kaasutracker/features/profile/data/user_model.dart';
import 'package:kaasutracker/features/profile/data/user_profile_provider.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  String _formatOrdinalDay(int day) {
    if (day >= 11 && day <= 13) {
      return '${day}th';
    }
    switch (day % 10) {
      case 1:
        return '${day}st';
      case 2:
        return '${day}nd';
      case 3:
        return '${day}rd';
      default:
        return '${day}th';
    }
  }

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
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);
    final dateFormat = DateFormat.yMMMd();

    final profileAsync = ref.watch(userProfileProvider);
    final expensesAsync = ref.watch(expensesProvider);
    final emisAsync = ref.watch(emisProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        centerTitle: false,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.addExpense),
        icon: const Icon(Icons.add),
        label: const Text('Add expense'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(userProfileProvider);
          ref.invalidate(expensesProvider);
          ref.invalidate(emisProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 88),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Financial Overview Card
              _buildOverviewCard(
                context: context,
                colors: colors,
                currencyFormat: currencyFormat,
                profileAsync: profileAsync,
                expensesAsync: expensesAsync,
                emisAsync: emisAsync,
              ),
              const SizedBox(height: 28),

              // 2. Recent Expenses Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Expenses',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  TextButton.icon(
                    onPressed: () => context.push(AppRoutes.addExpense),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add'),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 3. Expenses List View
              expensesAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 36),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, stack) => Card(
                  color: colors.errorContainer.withValues(alpha: 0.3),
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Icon(Icons.error_outline, color: colors.error, size: 36),
                        const SizedBox(height: 8),
                        Text(
                          'Could not load recent expenses',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton(
                          onPressed: () => ref.invalidate(expensesProvider),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (expenses) {
                  if (expenses.isEmpty) {
                    return Card(
                      elevation: 0,
                      color: colors.surfaceContainerLow,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              size: 48,
                              color: colors.outline,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No expenses recorded yet',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tap + Add expense to start tracking.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: colors.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // Sort expenses by date descending
                  final sortedExpenses = [...expenses]
                    ..sort((a, b) => b.expenseDate.compareTo(a.expenseDate));

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: sortedExpenses.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final expense = sortedExpenses[index];
                      return Card(
                        elevation: 0,
                        color: colors.surfaceContainerLow,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          leading: CircleAvatar(
                            backgroundColor:
                                colors.primaryContainer.withValues(alpha: 0.6),
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
                              Text(dateFormat.format(expense.expenseDate.toLocal())),
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
                                  expense.category,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: colors.onSurfaceVariant,
                                      ),
                                ),
                              ),
                            ],
                          ),
                          trailing: Text(
                            currencyFormat.format(expense.amount),
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colors.primary,
                                ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewCard({
    required BuildContext context,
    required ColorScheme colors,
    required NumberFormat currencyFormat,
    required AsyncValue<UserModel> profileAsync,
    required AsyncValue<List<Expense>> expensesAsync,
    required AsyncValue<List<EmiModel>> emisAsync,
  }) {
    final now = DateTime.now();

    final profile = profileAsync.value;
    final double salary = profile?.baseSalary ?? 0.0;
    final double thresholdPercentage = profile?.thresholdPercentage ?? 80.0;

    final expensesList = expensesAsync.value ?? [];
    final currentMonthExpenses = expensesList.where((e) {
      return e.expenseDate.year == now.year && e.expenseDate.month == now.month;
    }).toList();
    final double totalSpent = currentMonthExpenses.fold<double>(
      0.0,
      (sum, e) => sum + e.amount,
    );

    final emisList = emisAsync.value ?? [];
    final activeEmis = emisList.where((e) => e.isActive).toList();
    final double totalEmis = activeEmis.fold<double>(
      0.0,
      (sum, e) => sum + e.amount,
    );

    final double totalConsumed = totalSpent + totalEmis;
    final double consumedRatio =
        salary > 0 ? (totalConsumed / salary).clamp(0.0, 1.0) : 0.0;
    final int consumedPercentage =
        salary > 0 ? ((totalConsumed / salary) * 100).round() : 0;

    // Next EMI Due Date calculation
    String nextEmiDueText = 'None';
    if (activeEmis.isNotEmpty) {
      final today = DateTime(now.year, now.month, now.day);
      DateTime? earliestCandidate;

      for (final emi in activeEmis) {
        final dayClamped = emi.dueDateDay.clamp(1, 28);
        DateTime dueThisMonth = DateTime(now.year, now.month, dayClamped);
        DateTime candidate;
        if (dueThisMonth.isAfter(today) || dueThisMonth.isAtSameMomentAs(today)) {
          candidate = dueThisMonth;
        } else {
          candidate = DateTime(now.year, now.month + 1, dayClamped);
        }

        if (earliestCandidate == null || candidate.isBefore(earliestCandidate)) {
          earliestCandidate = candidate;
        }
      }

      if (earliestCandidate != null) {
        nextEmiDueText =
            '${DateFormat.MMM().format(earliestCandidate)} ${_formatOrdinalDay(earliestCandidate.day)}';
      }
    }

    final isWarning = consumedPercentage >= thresholdPercentage;

    return Card(
      elevation: 0,
      color: isWarning
          ? colors.errorContainer.withValues(alpha: 0.25)
          : colors.primaryContainer.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Monthly Base Salary',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      currencyFormat.format(salary),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colors.primary,
                          ),
                    ),
                  ],
                ),
                Chip(
                  label: Text(
                    '$consumedPercentage% Used',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: isWarning ? colors.error : colors.primary,
                    ),
                  ),
                  backgroundColor: isWarning
                      ? colors.errorContainer
                      : colors.primaryContainer,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Consumed Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: consumedRatio,
                minHeight: 8,
                backgroundColor: colors.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isWarning ? colors.error : colors.primary,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Financial Summary Metrics Grid
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    context: context,
                    colors: colors,
                    label: 'Spent this month',
                    value: currencyFormat.format(totalSpent),
                    icon: Icons.shopping_bag_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricTile(
                    context: context,
                    colors: colors,
                    label: 'Monthly EMIs',
                    value: currencyFormat.format(totalEmis),
                    icon: Icons.credit_card_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    context: context,
                    colors: colors,
                    label: 'Next EMI Due',
                    value: nextEmiDueText,
                    icon: Icons.event_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricTile(
                    context: context,
                    colors: colors,
                    label: 'Remaining',
                    value: currencyFormat.format(
                      (salary - totalConsumed).clamp(0.0, double.infinity),
                    ),
                    icon: Icons.account_balance_outlined,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required BuildContext context,
    required ColorScheme colors,
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: colors.onSurfaceVariant),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}