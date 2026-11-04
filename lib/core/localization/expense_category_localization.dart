import 'package:kaasutracker/core/localization/generated/app_localizations.dart';

String localizedExpenseCategory(String category, AppLocalizations l10n) {
  return switch (category.toLowerCase()) {
    'travel' || 'transport' || 'fuel' => l10n.categoryTravel,
    'food' || 'dining' || 'restaurant' => l10n.categoryFood,
    'utilities' || 'bills' => l10n.categoryUtilities,
    'shopping' => l10n.categoryShopping,
    _ => category,
  };
}
