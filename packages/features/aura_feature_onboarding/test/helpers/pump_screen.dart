import 'dart:convert';
import 'dart:io';

import 'package:aura_design/aura_design.dart';
import 'package:aura_l10n/aura_l10n.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Where the design system keeps its font assets, from this package.
const String _fontsDir = '../../aura_design/fonts';

/// Every family `AuraText` can reach, primaries and Arabic fallbacks alike.
const List<String> _families = <String>[
  AuraFonts.display,
  AuraFonts.app,
  AuraFonts.system,
  AuraFonts.displayArabic,
  AuraFonts.textArabic,
];

/// Loads Aura's bundled fonts into the test binding.
///
/// Without this the renderer substitutes a placeholder where every glyph has
/// the same width, which defeats layout assertions and makes goldens
/// meaningless. Each family is registered under its bare name and under the
/// package-qualified one, because `AuraText` sets `package:`.
Future<void> loadAuraFonts() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final family in _families) {
    await _register(
      File('$_fontsDir/$family.ttf'),
      <String>[family, 'packages/${AuraFonts.package}/$family'],
    );
  }
  await _loadLucide();
}

/// Registers the Lucide glyphs `AuraIcons` names.
///
/// Icons come from a pub package rather than from this repo, so the asset is
/// found through the package config instead of a path that would only work on
/// one machine. Without it every icon in a golden is an empty box, which is
/// easy to miss and looks like a design decision.
Future<void> _loadLucide() async {
  const package = 'lucide_icons_flutter';
  final root = _packageRoot(package);
  await _register(
    File.fromUri(root.resolve('assets/lucide.ttf')),
    <String>['Lucide', 'packages/$package/Lucide'],
  );
}

/// Resolves a pub package's directory from the workspace package config.
///
/// `Isolate.resolvePackageUri` throws under `flutter_test`, and the pub cache
/// path differs per machine, so the config the tool already wrote is the only
/// portable answer.
Uri _packageRoot(String name) {
  for (
    var dir = Directory.current;
    dir.parent.path != dir.path;
    dir = dir.parent
  ) {
    final config = File('${dir.path}/.dart_tool/package_config.json');
    if (!config.existsSync()) continue;

    final packages =
        (jsonDecode(config.readAsStringSync())
                as Map<String, dynamic>)['packages']!
            as List<dynamic>;
    for (final entry in packages.cast<Map<String, dynamic>>()) {
      if (entry['name'] != name) continue;
      // rootUri is relative to the directory holding package_config.json.
      return config.parent.uri.resolve('${entry['rootUri']}/');
    }
  }
  throw StateError('$name is not on the package config');
}

/// Loads one font file under every name a style might resolve it by.
///
/// Both the bare family and the package-qualified one are registered, because
/// a style that sets `package:` resolves only the qualified name.
Future<void> _register(File file, List<String> keys) async {
  final bytes = await file.readAsBytes();
  for (final key in keys) {
    await (FontLoader(
      key,
    )..addFont(Future<ByteData>.value(ByteData.sublistView(bytes)))).load();
  }
}

/// Pumps a screen at the 393 by 852 design canvas, in [locale].
///
/// The canvas is the device the design was drawn on, so a golden taken here
/// lines up with the pen frame point for point. Text direction comes from the
/// locale rather than being passed in, so an Arabic pump exercises the same
/// resolution the real app does.
Future<void> pumpScreen(
  WidgetTester tester,
  Widget screen, {
  Locale locale = const Locale('en'),
  EdgeInsets viewPadding = _iPhonePadding,
}) async {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = const Size(
      AuraSizes.referenceWidth,
      AuraSizes.referenceHeight,
    );
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    Localizations(
      locale: locale,
      delegates: AppLocalizations.localizationsDelegates,
      child: MediaQuery(
        data: MediaQueryData(
          size: const Size(
            AuraSizes.referenceWidth,
            AuraSizes.referenceHeight,
          ),
          padding: viewPadding,
          viewPadding: viewPadding,
        ),
        child: Directionality(
          textDirection: _directionOf(locale),
          child: screen,
        ),
      ),
    ),
  );
  await tester.pump();
}

/// The safe area of the device the design canvas describes.
///
/// The pen draws a 62 point status bar and runs its canvas under the home
/// indicator, so a screen only lines up with the frame when the insets are
/// there.
const EdgeInsets _iPhonePadding = EdgeInsets.only(top: 59, bottom: 34);

TextDirection _directionOf(Locale locale) =>
    locale.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr;
