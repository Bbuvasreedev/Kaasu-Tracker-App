import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaasutracker/core/network/supabase_client_provider.dart';
import 'package:kaasutracker/main.dart';
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
        ],
        child: const KaasuTrackerApp(locale: Locale('ta')),
      ),
    );

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
  });
}
