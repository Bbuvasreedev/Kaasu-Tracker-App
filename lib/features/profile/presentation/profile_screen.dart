import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kaasutracker/core/network/api_service.dart';
import 'package:kaasutracker/core/routing/app_router.dart';
import 'package:kaasutracker/core/theme/theme_provider.dart';
import 'package:kaasutracker/features/auth/auth_provider.dart';
import 'package:kaasutracker/features/profile/data/user_model.dart';
import 'package:kaasutracker/features/profile/data/user_profile_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _salaryController = TextEditingController();

  double _thresholdPercentage = 80.0;
  String _languagePref = 'en';
  bool _isSaving = false;
  bool _isInitialized = false;

  @override
  void dispose() {
    _salaryController.dispose();
    super.dispose();
  }

  void _populateForm(UserModel profile) {
    if (_isInitialized) return;
    _salaryController.text = profile.baseSalary.toStringAsFixed(2);
    _thresholdPercentage = profile.thresholdPercentage;
    _languagePref = profile.languagePref;
    _isInitialized = true;
  }

  Future<void> _savePreferences() async {
    if (!_formKey.currentState!.validate()) return;

    final parsedSalary = double.tryParse(_salaryController.text.trim()) ?? 0.0;

    final updatedModel = UserModel(
      baseSalary: parsedSalary,
      thresholdPercentage: _thresholdPercentage,
      languagePref: _languagePref,
    );

    setState(() => _isSaving = true);

    try {
      final api = ref.read(apiServiceProvider);
      try {
        await api.put('users/me', body: updatedModel.toJson());
      } catch (_) {
        await api.post('users/me', body: updatedModel.toJson());
      }

      ref.invalidate(userProfileProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preferences saved successfully!')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not save preferences: $error'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _signOut() async {
    try {
      await ref.read(authProvider).signOut();
      if (!mounted) return;
      context.go(AppRoutes.login);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not sign out: $error'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final currentUserEmail =
        ref.watch(authProvider).currentUser?.email ?? 'User Email';

    final themeMode = ref.watch(themeModeProvider);
    final isDarkMode = themeMode == ThemeMode.dark;

    final currentLocale = ref.watch(appLocaleProvider);
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Settings'),
        centerTitle: false,
      ),
      body: profileAsync.when(
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
                  'Error loading profile',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(userProfileProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (profile) {
          _populateForm(profile);

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // User Avatar Header
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 44,
                          backgroundColor: colors.primaryContainer,
                          child: Icon(
                            Icons.person_rounded,
                            size: 48,
                            color: colors.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          currentUserEmail,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Personal Finance & Settings',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Financial Preferences Card
                  Card(
                    elevation: 0,
                    color: colors.surfaceContainerLow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Financial Preferences',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 20),

                          // Base Monthly Salary Input
                          TextFormField(
                            controller: _salaryController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Base Monthly Salary (₹)',
                              prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              final salary = double.tryParse(value?.trim() ?? '');
                              if (salary == null || salary <= 0) {
                                return 'Please enter a valid salary amount.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          // Expense Alert Threshold %
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Alert Threshold',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              Chip(
                                label: Text(
                                  '${_thresholdPercentage.round()}%',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: colors.primary,
                                  ),
                                ),
                                backgroundColor:
                                    colors.primaryContainer.withValues(alpha: 0.5),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Get notified when monthly spending reaches this % of salary.',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: colors.onSurfaceVariant),
                          ),
                          const SizedBox(height: 8),
                          Slider(
                            value: _thresholdPercentage,
                            min: 10.0,
                            max: 100.0,
                            divisions: 18,
                            label: '${_thresholdPercentage.round()}%',
                            onChanged: (value) {
                              setState(() => _thresholdPercentage = value);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // App Settings & Features Card
                  Card(
                    elevation: 0,
                    color: colors.surfaceContainerLow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        // EMI Management Link
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 4,
                          ),
                          leading: Icon(
                            Icons.credit_card_outlined,
                            color: colors.primary,
                          ),
                          title: const Text(
                            'EMI Tracker',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: const Text(
                            'Manage monthly loan installments',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.push(AppRoutes.emis),
                        ),
                        const Divider(height: 1, indent: 56),

                        // Dark Mode Toggle
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 4,
                          ),
                          leading: Icon(
                            isDarkMode
                                ? Icons.dark_mode
                                : Icons.light_mode_outlined,
                            color: colors.primary,
                          ),
                          title: const Text(
                            'Dark Mode',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            isDarkMode ? 'Dark theme enabled' : 'Light theme enabled',
                          ),
                          trailing: Switch(
                            value: isDarkMode,
                            onChanged: (value) {
                              ref
                                  .read(themeModeProvider.notifier)
                                  .toggleTheme(value);
                            },
                          ),
                        ),
                        const Divider(height: 1, indent: 56),

                        // Language Selector
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 4,
                          ),
                          leading: Icon(
                            Icons.language_outlined,
                            color: colors.primary,
                          ),
                          title: const Text(
                            'App Language',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            currentLocale.languageCode == 'ta'
                                ? 'Tamil (தமிழ்)'
                                : 'English',
                          ),
                          trailing: DropdownButton<String>(
                            value: currentLocale.languageCode,
                            underline: const SizedBox.shrink(),
                            icon: const Icon(Icons.arrow_drop_down),
                            items: const [
                              DropdownMenuItem(
                                value: 'en',
                                child: Text('English'),
                              ),
                              DropdownMenuItem(
                                value: 'ta',
                                child: Text('தமிழ் (Tamil)'),
                              ),
                            ],
                            onChanged: (langCode) {
                              if (langCode != null) {
                                setState(() => _languagePref = langCode);
                                ref
                                    .read(appLocaleProvider.notifier)
                                    .setLocale(Locale(langCode));
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Save Preferences Button
                  ElevatedButton.icon(
                    onPressed: _isSaving ? null : _savePreferences,
                    icon: _isSaving
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: const Text('Save Preferences'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Prominent Red Sign Out Button
                  OutlinedButton.icon(
                    onPressed: _signOut,
                    icon: const Icon(Icons.logout),
                    label: const Text('Sign Out'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.error,
                      side: BorderSide(
                        color: colors.error.withValues(alpha: 0.5),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 36),

                  // App Version Footer
                  Center(
                    child: Text(
                      'Kaasu Tracker v1.0.0',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.outline,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
