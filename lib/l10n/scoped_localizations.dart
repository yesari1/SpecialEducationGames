import 'package:flutter/widgets.dart';
import 'app_localizations.dart';

/// Standalone preview/test hosts may omit the app's localization delegates.
/// Match the active profile in those hosts, and use inherited resources in app.
AppLocalizations scopedLocalizations(BuildContext context, String locale) =>
    Localizations.of<AppLocalizations>(context, AppLocalizations) ??
    lookupAppLocalizations(Locale(locale == 'tr' ? 'tr' : 'en'));
