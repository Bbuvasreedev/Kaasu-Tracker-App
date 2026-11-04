import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kaasutracker/core/localization/generated/app_localizations.dart';
import 'package:kaasutracker/core/localization/generated/app_localizations_en.dart';
import 'package:kaasutracker/core/network/api_service.dart';
import 'package:kaasutracker/core/network/supabase_client_provider.dart';
import 'package:kaasutracker/core/theme/theme_provider.dart';
import 'package:kaasutracker/features/auth/login_screen.dart';
import 'package:kaasutracker/features/profile/data/user_model.dart';
import 'package:kaasutracker/features/profile/data/user_profile_provider.dart';
import 'package:kaasutracker/features/profile/presentation/profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'English is the default and invalid saved locales fall back to English',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(appLocaleProvider), const Locale('en'));
      SharedPreferences.setMockInitialValues({'app_locale': 'not-a-locale'});
      expect(await loadSavedAppLocale(), const Locale('en'));
    },
  );

  test('every configured locale has translated resources for app UI', () {
    expect(
      AppLocalizations.supportedLocales.map((locale) => locale.languageCode),
      containsAll(<String>['en', 'ta', 'te', 'ml', 'kn', 'hi']),
    );

    final englishWelcome = AppLocalizationsEn().welcomeBack;
    for (final locale in AppLocalizations.supportedLocales) {
      final strings = lookupAppLocalizations(locale);
      if (locale.languageCode != 'en') {
        expect(strings.welcomeBack, isNot(englishWelcome));
      }
      expect(strings.welcomeBack, isNot(contains('\uFFFD')));
      expect(strings.expenseSaved, isNotEmpty);
      expect(strings.profileSettings, isNotEmpty);
    }
  });

  testWidgets(
    'locale switching updates login UI without changing route or theme',
    (tester) async {
      final testSupabaseClient = _createSupabaseClient();
      final container = ProviderContainer(
        overrides: [
          supabaseClientProvider.overrideWithValue(testSupabaseClient),
        ],
      );
      addTearDown(container.dispose);
      container.read(themeModeProvider.notifier).toggleTheme(true);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const _LocalizedHarness(home: LoginScreen()),
        ),
      );
      expect(find.text('Welcome back'), findsOneWidget);

      await container
          .read(appLocaleProvider.notifier)
          .setLocale(const Locale('ta'));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('மீண்டும் வருக'), findsOneWidget);
      expect(
        Theme.of(tester.element(find.byType(LoginScreen))).brightness,
        Brightness.dark,
      );
    },
  );

  testWidgets('Tamil, Telugu, Malayalam, Kannada and Hindi render in the UI', (
    tester,
  ) async {
    final testSupabaseClient = _createSupabaseClient();
    final container = ProviderContainer(
      overrides: [supabaseClientProvider.overrideWithValue(testSupabaseClient)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const _LocalizedHarness(home: LoginScreen()),
      ),
    );

    const locales = <String, String>{
      'ta': 'மீண்டும் வருக',
      'te': 'తిరిగి స్వాగతం',
      'ml': 'വീണ്ടും സ്വാഗതം',
      'kn': 'ಮತ್ತೆ ಸ್ವಾಗತ',
      'hi': 'वापसी पर स्वागत है',
    };
    for (final entry in locales.entries) {
      await container
          .read(appLocaleProvider.notifier)
          .setLocale(Locale(entry.key));
      await tester.pumpAndSettle();
      expect(find.text(entry.value), findsOneWidget);
    }
  });

  test('locale is restored from local preferences', () async {
    final firstRun = ProviderContainer();
    addTearDown(firstRun.dispose);
    await firstRun
        .read(appLocaleProvider.notifier)
        .setLocale(const Locale('te'));

    final restored = await loadSavedAppLocale();
    final restartedRun = ProviderContainer(
      overrides: [
        appLocaleProvider.overrideWith(
          () => AppLocaleNotifier(initialLocale: restored),
        ),
      ],
    );
    addTearDown(restartedRun.dispose);

    expect(restartedRun.read(appLocaleProvider), const Locale('te'));
    expect(await loadSavedAppLocale(), const Locale('te'));
  });

  testWidgets(
    'Save Preferences applies the draft language and preserves theme',
    (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final testSupabaseClient = _createSupabaseClient();
      final api = ApiService(
        client: MockClient((_) async => http.Response('', 200)),
        supabase: testSupabaseClient,
        accessTokenProvider: () => 'test-token',
      );
      final container = ProviderContainer(
        overrides: [
          supabaseClientProvider.overrideWithValue(testSupabaseClient),
          apiServiceProvider.overrideWithValue(api),
          userProfileProvider.overrideWith(
            (ref) async => const UserModel(
              baseSalary: 50000,
              thresholdPercentage: 80,
              languagePref: 'en',
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      container.read(themeModeProvider.notifier).toggleTheme(true);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const _LocalizedHarness(home: ProfileScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('తెలుగు (Telugu)').last);
      await tester.pumpAndSettle();

      expect(container.read(appLocaleProvider), const Locale('te'));
      expect(find.text('ప్రొఫైల్ & సెట్టింగ్‌లు'), findsOneWidget);

      await tester.tap(find.text('ప్రాధాన్యతలను సేవ్ చేయి'));
      await tester.pumpAndSettle();

      expect(container.read(appLocaleProvider), const Locale('te'));
      expect(find.text('ప్రొఫైల్ & సెట్టింగ్‌లు'), findsOneWidget);
      expect(container.read(themeModeProvider), ThemeMode.dark);
    },
  );
}

SupabaseClient _createSupabaseClient() => SupabaseClient(
  'http://localhost:54321',
  'test-anon-key',
  authOptions: const AuthClientOptions(autoRefreshToken: false),
);

class _LocalizedHarness extends ConsumerWidget {
  const _LocalizedHarness({required this.home});

  final Widget home;

  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp(
    locale: ref.watch(appLocaleProvider),
    themeMode: ref.watch(themeModeProvider),
    theme: ThemeData.light(),
    darkTheme: ThemeData.dark(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  );
}
