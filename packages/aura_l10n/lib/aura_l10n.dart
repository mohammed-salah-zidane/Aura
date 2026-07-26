/// Aura's user-visible copy, in English and Arabic.
///
/// Every string a user can read lives in `lib/l10n/*.arb` and reaches a widget
/// through `context.l10n`. This is its own package rather than part of the app
/// because feature packages cannot import the composition root, and every
/// feature needs the same copy.
library;

// AppLocalizations carries its own `localizationsDelegates` and
// `supportedLocales`, both of which already include the Flutter globals, so
// there is nothing here to re-export from flutter_localizations.
export 'l10n/generated/app_localizations.dart' show AppLocalizations;
export 'src/aura_locales.dart';
export 'src/l10n_context.dart';
