import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaasutracker/core/localization/generated/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaasutracker/core/network/supabase_client_provider.dart';
import 'package:kaasutracker/features/auth/auth_provider.dart';
import 'package:kaasutracker/features/auth/login_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  late SupabaseClient client;
  late _RecordingAuthNotifier auth;

  setUp(() {
    client = SupabaseClient('http://localhost:54321', 'test-anon-key');
    auth = _RecordingAuthNotifier(client.auth);
  });

  Future<void> pumpLoginScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          supabaseClientProvider.overrideWithValue(client),
          authProvider.overrideWithValue(auth),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: LoginScreen(),
        ),
      ),
    );
  }

  Future<void> enterCredentials(
    WidgetTester tester, {
    required String email,
    required String password,
  }) async {
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), email);
    await tester.enterText(fields.at(1), password);
  }

  testWidgets('invalid email shows local validation and skips auth', (
    tester,
  ) async {
    await pumpLoginScreen(tester);
    await enterCredentials(
      tester,
      email: 'bbuvi@@gmail.com',
      password: 'password',
    );

    await tester.tap(find.text('Log In'));
    await tester.pumpAndSettle();

    expect(find.text('Please enter a valid email address.'), findsOneWidget);
    expect(auth.lastEmail, isNull);
  });

  testWidgets('login submits the trimmed email and shows auth errors', (
    tester,
  ) async {
    await pumpLoginScreen(tester);
    await enterCredentials(
      tester,
      email: '  bbuvi@gmail.com  ',
      password: 'password',
    );

    await tester.tap(find.text('Log In'));
    await tester.pumpAndSettle();

    expect(auth.lastMethod, 'signIn');
    expect(auth.lastEmail, 'bbuvi@gmail.com');
    expect(find.text('The email or password is incorrect.'), findsOneWidget);
    expect(find.text('Please enter a valid email address.'), findsNothing);
  });

  testWidgets('sign up submits the trimmed email', (tester) async {
    await pumpLoginScreen(tester);
    await enterCredentials(
      tester,
      email: '  user+tag@example.com  ',
      password: 'password',
    );

    await tester.tap(find.text('Sign Up'));
    await tester.pumpAndSettle();

    expect(auth.lastMethod, 'signUp');
    expect(auth.lastEmail, 'user+tag@example.com');
    expect(find.text('The email or password is incorrect.'), findsNothing);
    expect(find.text('Please enter a valid email address.'), findsNothing);
  });
}

class _RecordingAuthNotifier extends AuthNotifier {
  _RecordingAuthNotifier(super.auth);

  String? lastEmail;
  String? lastMethod;

  @override
  Future<AuthResponse> signIn(String email, String password) async {
    lastEmail = email;
    lastMethod = 'signIn';
    throw const AuthApiException(
      'Invalid login credentials',
      code: 'invalid_credentials',
    );
  }

  @override
  Future<AuthResponse> signUp(String email, String password) async {
    lastEmail = email;
    lastMethod = 'signUp';
    throw const AuthApiException('Registration rejected');
  }
}
