import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaasutracker/core/theme/theme_provider.dart';
import 'package:kaasutracker/core/network/supabase_client_provider.dart';
import 'package:kaasutracker/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  final testSupabaseClient = SupabaseClient(
    'http://localhost:54321',
    'test-anon-key',
  );

  testWidgets('unauthenticated users are redirected to login', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          supabaseClientProvider.overrideWithValue(testSupabaseClient),
        ],
        child: const KaasuTrackerApp(),
      ),
    );

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Log In'), findsOneWidget);
  });

  testWidgets('uses Tamil translations when Tamil is selected', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          supabaseClientProvider.overrideWithValue(testSupabaseClient),
          appLocaleProvider.overrideWith(
            () => AppLocaleNotifier(initialLocale: const Locale('ta')),
          ),
        ],
        child: const KaasuTrackerApp(),
      ),
    );

    expect(find.text('மீண்டும் வருக'), findsOneWidget);
    expect(find.text('மின்னஞ்சல்'), findsOneWidget);
  });

  testWidgets('root app rebuilds when the application locale changes', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer(
      overrides: [supabaseClientProvider.overrideWithValue(testSupabaseClient)],
    );
    addTearDown(container.dispose);
    container.read(themeModeProvider.notifier).toggleTheme(true);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const KaasuTrackerApp(),
      ),
    );

    expect(container.read(appLocaleProvider), const Locale('en'));
    expect(find.text('Welcome back'), findsOneWidget);

    await container
        .read(appLocaleProvider.notifier)
        .setLocale(const Locale('te'));
    await tester.pumpAndSettle();

    expect(find.text('తిరిగి స్వాగతం'), findsOneWidget);
    expect(find.text('ఈమెయిల్'), findsOneWidget);
    expect(find.text('Welcome back'), findsNothing);
    expect(find.byType(KaasuTrackerApp), findsOneWidget);
    expect(
      Theme.of(tester.element(find.text('తిరిగి స్వాగతం'))).brightness,
      Brightness.dark,
    );
  });
}
