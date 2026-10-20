// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'KaasuTracker';

  @override
  String get splashTitle => 'KaasuTracker';

  @override
  String get splashSubtitle => 'Your money, made clear.';

  @override
  String get continueToDashboard => 'Continue';

  @override
  String get dashboardTitle => 'Your dashboard';

  @override
  String get dashboardPlaceholder => 'Your finances at a glance.';
}
