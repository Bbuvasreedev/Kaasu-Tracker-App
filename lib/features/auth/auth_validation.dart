import 'package:kaasutracker/core/localization/generated/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

String? validateEmail(String? value, AppLocalizations l10n) {
  final email = value?.trim() ?? '';
  if (email.isEmpty) return l10n.emailRequired;
  const localPart =
      r"[A-Z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[A-Z0-9!#$%&'*+/=?^_`{|}~-]+)*";
  const domainLabel = r'[A-Z0-9](?:[A-Z0-9-]*[A-Z0-9])?';
  final emailPattern = RegExp(
    '^$localPart@(?:$domainLabel\\.)+$domainLabel\$',
    caseSensitive: false,
  );
  if (!emailPattern.hasMatch(email)) {
    return l10n.emailInvalid;
  }
  return null;
}

String? validatePassword(
  String? value, {
  required bool isSignUp,
  required AppLocalizations l10n,
}) {
  if (value == null || value.isEmpty) return l10n.passwordRequired;
  if (isSignUp && value.length < 6) {
    return l10n.passwordMinLength;
  }
  return null;
}

String authenticationErrorMessage(
  Object error, {
  required bool isSignUp,
  required AppLocalizations l10n,
}) {
  if (error is AuthRetryableFetchException) {
    return l10n.authNetworkError;
  }

  if (error is AuthException) {
    final code = error.code?.toLowerCase();
    if (error.statusCode == '429' ||
        code == 'over_email_send_rate_limit' ||
        code == 'too_many_requests') {
      return l10n.tooManyAttempts;
    }

    switch (code) {
      case 'invalid_credentials':
        return l10n.invalidCredentials;
      case 'email_not_confirmed':
        return l10n.emailNotConfirmed;
      case 'user_already_exists':
        return l10n.accountAlreadyExists;
      case 'weak_password':
        return l10n.weakPassword;
    }

    if (error.message.trim().isNotEmpty) return error.message;
  }

  return isSignUp ? l10n.accountCreationFailed : l10n.signInFailed;
}
