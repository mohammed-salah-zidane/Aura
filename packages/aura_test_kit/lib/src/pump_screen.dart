import 'dart:convert';
import 'dart:io';

import 'package:aura_design/aura_design.dart';
import 'package:aura_l10n/aura_l10n.dart';
import 'package:flutter/material.dart' show MaterialPageRoute;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

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
  // `DateFormat` throws on a locale whose symbols were never loaded, and the
  // screens format an hour and a weekday in both of them.
  await AuraLocales.loadDateSymbols();
  final designRoot = _packageRoot(AuraFonts.package);
  for (final family in _families) {
    await _register(
      File.fromUri(designRoot.resolve('fonts/$family.ttf')),
      <String>[family, 'packages/${AuraFonts.package}/$family'],
    );
  }
  await _loadLucide();
}

/// Registers the Lucide glyphs `AuraIcons` names.
///
/// Without it every icon in a golden is an empty box, which is easy to miss
/// and looks like a design decision.
Future<void> _loadLucide() async {
  const package = 'lucide_icons_flutter';
  final root = _packageRoot(package);
  await _register(
    File.fromUri(root.resolve('assets/lucide.ttf')),
    <String>['Lucide', 'packages/$package/Lucide'],
  );
}

/// Resolves a package's directory from the workspace package config.
///
/// `Isolate.resolvePackageUri` throws under `flutter_test`, and a pub-cache
/// path differs per machine, so the config the tool already wrote is the only
/// portable answer. It also has to answer for `aura_design`, whose assets this
/// harness reads from whichever package is running the suite.
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
///
/// The locale is also given to `intl`, exactly as the composition root gives it
/// once `Localizations` has resolved. Without that a clock time formats in
/// English inside an Arabic screen, which is a defect a test would otherwise
/// bake into a golden.
///
/// [reduceMotion] sets the flag every animation in the app checks, and it is
/// **on by default** because that is the only frame a test can reason about.
/// The ambient sky repeats forever, so `pumpAndSettle` would never return on a
/// screen that has one, and a frame caught mid-entrance is a different picture
/// every time. At rest the app renders exactly what `aura.pen` draws, which is
/// also what makes the goldens a regression test for that rule.
///
/// A test that is about the motion itself passes `reduceMotion: false` and
/// drives the clock with `pump(duration)` rather than `pumpAndSettle`.
Future<void> pumpScreen(
  WidgetTester tester,
  Widget screen, {
  Locale locale = const Locale('en'),
  EdgeInsets viewPadding = iPhoneViewPadding,
  Size size = const Size(
    AuraSizes.referenceWidth,
    AuraSizes.referenceHeight,
  ),
  bool withNavigator = false,
  bool reduceMotion = true,
}) async {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = size;
  addTearDown(tester.view.reset);
  AuraLocales.adopt(locale);

  await tester.pumpWidget(
    Localizations(
      locale: locale,
      delegates: AppLocalizations.localizationsDelegates,
      child: MediaQuery(
        data: MediaQueryData(
          size: size,
          padding: viewPadding,
          viewPadding: viewPadding,
          disableAnimations: reduceMotion,
        ),
        child: Directionality(
          textDirection: _directionOf(locale),
          // A screen that opens a sheet needs the Navigator and the Overlay it
          // has in the app. Off by default, so a plain screen is pumped with
          // nothing above it that the design did not put there.
          child: withNavigator
              ? Navigator(
                  onGenerateRoute: (settings) =>
                      MaterialPageRoute<void>(builder: (context) => screen),
                )
              : screen,
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
const EdgeInsets iPhoneViewPadding = EdgeInsets.only(top: 59, bottom: 34);

TextDirection _directionOf(Locale locale) =>
    locale.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr;
