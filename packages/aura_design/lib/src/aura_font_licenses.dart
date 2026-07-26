import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Adds the bundled fonts' Open Font Licenses to Flutter's licence registry, so
/// they appear in the app's own licence page.
///
/// The OFL requires its text to travel with the font. Flutter collects package
/// `LICENSE` files automatically but not arbitrary assets, so the five OFL
/// texts are registered by hand. Call this once from `main`, before `runApp`;
/// the registry reads lazily, so nothing loads unless a user opens the page.
void registerAuraFontLicenses() {
  LicenseRegistry.addLicense(_loadFontLicenses);
}

/// One entry per bundled family, each attributed to the family it covers.
const Map<String, String> _licenseAssets = <String, String>{
  'Fraunces': 'fonts/OFL-Fraunces.txt',
  'Inter': 'fonts/OFL-Inter.txt',
  'Noto Kufi Arabic': 'fonts/OFL-NotoKufiArabic.txt',
  'Noto Sans Arabic': 'fonts/OFL-NotoSansArabic.txt',
  'Outfit': 'fonts/OFL-Outfit.txt',
};

Stream<LicenseEntry> _loadFontLicenses() async* {
  for (final entry in _licenseAssets.entries) {
    final text = await rootBundle.loadString(
      'packages/aura_design/${entry.value}',
    );
    yield LicenseEntryWithLineBreaks(<String>[entry.key], text);
  }
}
