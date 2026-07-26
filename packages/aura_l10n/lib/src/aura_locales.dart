import 'package:flutter/widgets.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

/// The locales Aura ships, and the formatting defaults that go with them.
///
/// ## Why the Arabic locale is `ar` and not `ar_EG`
///
/// The tag decides the numbering system, and the numbering system decides what
/// every temperature in the app looks like. `intl` follows CLDR here: `ar`
/// formats 35 as `35`, while `ar_EG` formats it as `٣٥` and renders dates and
/// clock times in Arabic-Indic digits too.
///
/// Aura ships `ar`, so digits are Western in both locales. Three reasons, in
/// order of weight:
///
/// 1. **The hero temperature is the app's identity.** It is set in Fraunces at
///    98 points, and no bundled Latin family contains an Arabic-Indic digit. In
///    Arabic-Indic the largest type on the screen would be drawn by the Arabic
///    fallback face instead, so the two locales would not look like one app.
/// 2. **It follows CLDR rather than fighting it.** `ar` already means Western
///    digits; forcing Arabic-Indic would mean overriding the default everywhere
///    a number is formatted.
/// 3. Western digits read across the whole Arab world and are what modern
///    Arabic app interfaces overwhelmingly use.
///
/// A device set to `ar-EG` still resolves here, because Flutter matches on the
/// language subtag and `ar` is the only Arabic locale on offer. Widening the
/// list to `ar_EG` later would silently switch every digit in the app, so the
/// choice is pinned by a test rather than left to the next reader.
abstract final class AuraLocales {
  /// Loads the date symbols every supported locale needs.
  ///
  /// `DateFormat` throws on a locale whose symbols were never loaded, and the
  /// bundled data covers every locale rather than only the two, so this runs
  /// once at startup instead of per screen.
  static Future<void> loadDateSymbols() => initializeDateFormatting();

  /// Makes [locale] the default for `intl`'s own formatters.
  ///
  /// `DateFormat` and `NumberFormat` read `Intl.defaultLocale` when they are
  /// given none, so this keeps them in step with what `Localizations` resolved.
  static void adopt(Locale locale) {
    Intl.defaultLocale = locale.toLanguageTag();
  }
}
