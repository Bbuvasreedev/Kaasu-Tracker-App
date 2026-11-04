import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:kaasutracker/core/localization/generated/app_localizations.dart';
import 'package:kaasutracker/core/network/api_service.dart';

String financeErrorMessage(BuildContext context, Object error) {
  final l10n = AppLocalizations.of(context)!;
  if (error is ApiAuthenticationException) return l10n.serverSessionExpired;
  if (error is TimeoutException) return l10n.serverFailure;
  if (error is! ApiException) return l10n.serverRequestFailure;
  if ((error.statusCode == 400 ||
          error.statusCode == 409 ||
          error.statusCode == 422) &&
      error.message.isNotEmpty) {
    return error.message;
  }
  return switch (error.statusCode) {
    401 => l10n.serverSessionExpired,
    403 => l10n.serverForbidden,
    404 => l10n.serverNotFound,
    >= 500 => l10n.serverFailure,
    _ => l10n.serverRequestFailure,
  };
}
