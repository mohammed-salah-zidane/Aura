import 'dart:io';

import 'package:aura_design/aura_design.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Families bundled by this package.
const List<String> auraFontFamilies = <String>[
  AuraFonts.display,
  AuraFonts.app,
  AuraFonts.system,
];

/// Loads Aura's bundled fonts into the test binding.
///
/// Without this, the test renderer falls back to a placeholder font where every
/// glyph measures the same width, which silently defeats both layout
/// assertions and golden comparisons.
///
/// Each family is registered twice. `AuraText` sets `package:`, so Flutter
/// resolves those styles against `packages/aura_design/<family>` rather than
/// the bare family name, and a test that registered only the bare name would
/// still render a fallback.
Future<void> loadAuraFonts() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final family in auraFontFamilies) {
    final bytes = await File('fonts/$family.ttf').readAsBytes();
    for (final key in <String>[
      family,
      'packages/${AuraFonts.package}/$family',
    ]) {
      await (FontLoader(
        key,
      )..addFont(Future<ByteData>.value(ByteData.sublistView(bytes)))).load();
    }
  }
}
