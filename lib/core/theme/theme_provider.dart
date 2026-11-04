import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.light;

  void toggleTheme(bool isDark) {
    state = isDark ? ThemeMode.dark : ThemeMode.light;
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

class AppLocaleNotifier extends Notifier<Locale> {
  AppLocaleNotifier({this.initialLocale = const Locale('en')});

  static const preferenceKey = 'app_locale';
  static const supportedLanguageCodes = <String>[
    'en',
    'ta',
    'te',
    'ml',
    'kn',
    'hi',
  ];

  final Locale initialLocale;

  @override
  Locale build() => initialLocale;

  Future<void> setLocale(Locale newLocale) async {
    if (!supportedLanguageCodes.contains(newLocale.languageCode)) {
      throw ArgumentError.value(newLocale, 'newLocale', 'Unsupported locale');
    }
    state = newLocale;
    final saved = await SharedPreferences.getInstance().then(
      (preferences) =>
          preferences.setString(preferenceKey, newLocale.languageCode),
    );
    if (!saved) {
      throw StateError('The selected language could not be saved locally.');
    }
  }
}

final appLocaleProvider = NotifierProvider<AppLocaleNotifier, Locale>(
  AppLocaleNotifier.new,
);

Future<Locale> loadSavedAppLocale() async {
  final preferences = await SharedPreferences.getInstance();
  final savedCode = preferences.getString(AppLocaleNotifier.preferenceKey);
  if (savedCode == null ||
      !AppLocaleNotifier.supportedLanguageCodes.contains(savedCode)) {
    return const Locale('en');
  }
  return Locale(savedCode);
}
