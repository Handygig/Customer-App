import 'package:flutter/material.dart';
import 'package:customer_app/l10n/app_localizations.dart';

extension LocalizedBuildContext on BuildContext {
  AppLocalizations get loc =>
      AppLocalizations.of(this) ?? lookupAppLocalizations(const Locale('en'));
}