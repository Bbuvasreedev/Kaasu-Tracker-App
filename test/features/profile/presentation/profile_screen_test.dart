import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kaasutracker/core/localization/generated/app_localizations.dart';
import 'package:kaasutracker/core/network/api_service.dart';
import 'package:kaasutracker/core/network/supabase_client_provider.dart';
import 'package:kaasutracker/features/auth/auth_provider.dart';
import 'package:kaasutracker/features/profile/data/user_model.dart';
import 'package:kaasutracker/features/profile/data/user_profile_provider.dart';
import 'package:kaasutracker/features/profile/presentation/profile_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  late SupabaseClient mockSupabase;

  setUp(() {
    mockSupabase = SupabaseClient(
      'http://localhost:54321',
      'test-anon-key',
      httpClient: MockClient((_) async => http.Response('{}', 200)),
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
  });

  Widget createHarness({dynamic profileOverride, ApiService? apiServiceOverride}) {
    return ProviderScope(
      overrides: [
        supabaseClientProvider.overrideWithValue(mockSupabase),
        authStateStreamProvider.overrideWith((ref) => const Stream.empty()),
        if (apiServiceOverride != null)
          apiServiceProvider.overrideWithValue(apiServiceOverride),
        if (profileOverride != null) profileOverride,
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ProfileScreen(),
      ),
    );
  }

  testWidgets('displays default profile for newly registered user when backend returns 404', (
    tester,
  ) async {
    final client = MockClient((request) async {
      if (request.url.path.endsWith('/users/me')) {
        return http.Response('{"message":"User not found"}', 404);
      }
      return http.Response('', 404);
    });

    final api = ApiService(
      client: client,
      supabase: mockSupabase,
      baseUrl: Uri.parse('http://localhost:8080/api/v1/'),
      accessTokenProvider: () => 'test-token',
    );

    await tester.pumpWidget(
      createHarness(apiServiceOverride: api),
    );
    await tester.pumpAndSettle();

    expect(find.text('Profile & Settings'), findsOneWidget);
    expect(find.text('Error loading profile'), findsNothing);
    expect(
      tester.widget<TextFormField>(find.byType(TextFormField)).controller?.text,
      '0.00',
    );
    expect(find.text('80%'), findsOneWidget);
  });

  testWidgets('displays loaded profile and allows updating preferences', (
    tester,
  ) async {
    await tester.pumpWidget(
      createHarness(
        profileOverride: userProfileProvider.overrideWith(
          (ref) async => const UserModel(
            email: 'user@example.com',
            baseSalary: 50000,
            thresholdPercentage: 75,
            languagePref: 'en',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Profile & Settings'), findsOneWidget);
    expect(
      tester.widget<TextFormField>(find.byType(TextFormField)).controller?.text,
      '50000.00',
    );
    expect(find.text('75%'), findsOneWidget);
    expect(find.text('Save Preferences'), findsOneWidget);
  });

  testWidgets('shows error state when load fails and Retry button is present', (
    tester,
  ) async {
    await tester.pumpWidget(
      createHarness(
        profileOverride: userProfileProvider.overrideWith(
          (ref) async => throw const ApiException(
            statusCode: 500,
            message: 'Server error',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Error loading profile'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('updates form fields when profile data changes to prevent stale data', (
    tester,
  ) async {
    UserModel currentProfile = UserModel(
      email: 'user1@example.com',
      baseSalary: 45000,
      thresholdPercentage: 70,
      languagePref: 'en',
    );

    final container = ProviderContainer(
      overrides: [
        supabaseClientProvider.overrideWithValue(mockSupabase),
        authStateStreamProvider.overrideWith((ref) => const Stream.empty()),
        userProfileProvider.overrideWith((ref) async => currentProfile),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ProfileScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester.widget<TextFormField>(find.byType(TextFormField)).controller?.text,
      '45000.00',
    );
    expect(find.text('70%'), findsOneWidget);

    currentProfile = UserModel(
      email: 'user2@example.com',
      baseSalary: 90000,
      thresholdPercentage: 90,
      languagePref: 'en',
    );
    container.invalidate(userProfileProvider);
    await tester.pumpAndSettle();

    expect(
      tester.widget<TextFormField>(find.byType(TextFormField)).controller?.text,
      '90000.00',
    );
    expect(find.text('90%'), findsOneWidget);
  });
}
