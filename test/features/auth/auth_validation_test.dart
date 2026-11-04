import 'package:flutter_test/flutter_test.dart';
import 'package:kaasutracker/core/localization/generated/app_localizations_en.dart';
import 'package:kaasutracker/features/auth/auth_validation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  final l10n = AppLocalizationsEn();

  group('email validation', () {
    test('accepts common valid email formats after trimming', () {
      for (final email in [
        'bbuvi@gmail.com',
        'user.name@example.com',
        'user+tag@example.com',
        'USER@EXAMPLE.COM',
        '  bbuvi@gmail.com  ',
      ]) {
        expect(validateEmail(email, l10n), isNull, reason: email);
      }
    });

    test('rejects empty and malformed email addresses', () {
      for (final email in [
        '',
        'bbuvi',
        'bbuvi@',
        '@gmail.com',
        'bbuvi@gmail',
        'bbuvi@@gmail.com',
        'bbuvi..test@gmail.com',
        'bbuvi@-gmail.com',
      ]) {
        expect(validateEmail(email, l10n), isNotNull, reason: email);
      }
    });

    test('keeps server-side email errors distinct from local validation', () {
      const errorMessage = 'Supabase rejected the email address.';
      expect(
        authenticationErrorMessage(
          const AuthApiException(errorMessage, code: 'email_address_invalid'),
          isSignUp: false,
          l10n: l10n,
        ),
        errorMessage,
      );
      expect(
        authenticationErrorMessage(
          const AuthApiException(errorMessage, code: 'validation_failed'),
          isSignUp: false,
          l10n: l10n,
        ),
        errorMessage,
      );
    });
  });

  group('password validation', () {
    test('requires a value for login and enforces sign-up minimum length', () {
      expect(validatePassword('', isSignUp: false, l10n: l10n), isNotNull);
      expect(validatePassword('short', isSignUp: false, l10n: l10n), isNull);
      expect(validatePassword('short', isSignUp: true, l10n: l10n), isNotNull);
      expect(
        validatePassword('long-enough', isSignUp: true, l10n: l10n),
        isNull,
      );
    });
  });

  group('authentication error messages', () {
    test(
      'distinguishes login, confirmation, duplicate and rate-limit errors',
      () {
        expect(
          authenticationErrorMessage(
            const AuthApiException('invalid', code: 'invalid_credentials'),
            isSignUp: false,
            l10n: l10n,
          ),
          'The email or password is incorrect.',
        );
        expect(
          authenticationErrorMessage(
            const AuthApiException('unconfirmed', code: 'email_not_confirmed'),
            isSignUp: false,
            l10n: l10n,
          ),
          'Please confirm your email address before signing in.',
        );
        expect(
          authenticationErrorMessage(
            const AuthApiException('duplicate', code: 'user_already_exists'),
            isSignUp: true,
            l10n: l10n,
          ),
          'An account with this email already exists. Please log in.',
        );
        expect(
          authenticationErrorMessage(
            const AuthApiException('rate limited', statusCode: '429'),
            isSignUp: true,
            l10n: l10n,
          ),
          'Too many attempts. Please wait a while before trying again.',
        );
      },
    );

    test('explains weak-password and network failures', () {
      expect(
        authenticationErrorMessage(
          AuthWeakPasswordException(
            message: 'weak',
            statusCode: '422',
            reasons: const [],
          ),
          isSignUp: true,
          l10n: l10n,
        ),
        'Choose a stronger password and try again.',
      );
      expect(
        authenticationErrorMessage(
          AuthRetryableFetchException(),
          isSignUp: false,
          l10n: l10n,
        ),
        'Could not reach the authentication service. Check your connection and try again.',
      );
    });
  });
}
