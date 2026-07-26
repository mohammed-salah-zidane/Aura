import 'package:aura_design/aura_design.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/load_aura_fonts.dart';

/// Lays out one line and returns its measured width.
double _widthOf(TextStyle style, {String text = 'Weather 35°'}) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
  )..layout();
  return painter.width;
}

int _weightOf(TextStyle style) =>
    style.fontVariations!.firstWhere((v) => v.axis == 'wght').value.round();

/// A style from each family and each size band, named for the assertion output.
const Map<String, TextStyle> _styles = <String, TextStyle>{
  'display': AuraText.display,
  'titleCity': AuraText.titleCity,
  'titleScreen': AuraText.titleScreen,
  'metricValue': AuraText.metricValue,
  'condition': AuraText.condition,
  'valueCompact': AuraText.valueCompact,
  'body': AuraText.body,
  'label': AuraText.label,
  'kicker': AuraText.kicker,
  'caption': AuraText.caption,
};

void main() {
  setUpAll(loadAuraFonts);

  group('bundled fonts', () {
    test('each family loads and lays out with real metrics', () {
      for (final family in const <String>['Fraunces', 'Outfit', 'Inter']) {
        final width = _widthOf(
          TextStyle(fontFamily: family, fontSize: 20),
        );
        expect(width, greaterThan(0), reason: '$family produced no layout');
      }
    });

    test('the three families measure differently from one another', () {
      final widths = <String, double>{
        for (final family in const <String>['Fraunces', 'Outfit', 'Inter'])
          family: _widthOf(TextStyle(fontFamily: family, fontSize: 20)),
      };
      expect(
        widths.values.toSet(),
        hasLength(3),
        reason: 'identical widths mean a fallback font is being used: $widths',
      );
    });
  });

  group('variable weight axis', () {
    // If fontVariations were ignored, every weight would measure identically
    // and the whole type scale would render at the font's default weight.
    test('a heavier wght measures wider than a lighter one', () {
      for (final family in const <String>['Fraunces', 'Outfit', 'Inter']) {
        final light = _widthOf(
          TextStyle(
            fontFamily: family,
            fontSize: 40,
            fontVariations: const <FontVariation>[FontVariation('wght', 300)],
          ),
        );
        final heavy = _widthOf(
          TextStyle(
            fontFamily: family,
            fontSize: 40,
            fontVariations: const <FontVariation>[FontVariation('wght', 700)],
          ),
        );
        expect(
          heavy,
          greaterThan(light),
          reason: '$family ignored the wght axis (light $light, heavy $heavy)',
        );
      }
    });
  });

  group('AuraText', () {
    const styles = _styles;

    test('every style drives weight through the variable axis', () {
      for (final entry in styles.entries) {
        expect(
          entry.value.fontVariations,
          isNotNull,
          reason: '${entry.key} has no fontVariations',
        );
        expect(
          entry.value.fontWeight,
          isNull,
          reason: '${entry.key} sets fontWeight, which risks a synthetic bold',
        );
      }
    });

    test('every style resolves to a bundled family in this package', () {
      // Setting `package:` makes Flutter rewrite the family, so the resolved
      // name is what has to match, not the name written in the token.
      for (final entry in styles.entries) {
        expect(
          entry.value.fontFamily,
          anyOf(<String>[
            for (final family in auraFontFamilies)
              'packages/${AuraFonts.package}/$family',
          ]),
          reason: '${entry.key} uses an unbundled family',
        );
      }
    });

    test('every style has a size', () {
      for (final entry in styles.entries) {
        expect(
          entry.value.fontSize,
          greaterThan(0),
          reason: '${entry.key} has no size',
        );
      }
    });

    test('a package-qualified style renders with its real font', () {
      // Proves the package-prefixed family actually resolves. A fallback would
      // measure the serif and the sans identically.
      final serif = _widthOf(
        AuraText.titleCard.copyWith(fontSize: 40),
        text: 'Weather',
      );
      final sans = _widthOf(
        AuraText.condition.copyWith(fontSize: 40),
        text: 'Weather',
      );
      expect(serif, greaterThan(0));
      expect(
        serif,
        isNot(closeTo(sans, 0.01)),
        reason: 'Fraunces and Outfit measured the same, so one fell back',
      );
    });

    test('the hero temperature is the largest style', () {
      final largest = styles.values
          .map((s) => s.fontSize!)
          .reduce((a, b) => a > b ? a : b);
      expect(AuraText.display.fontSize, largest);
    });

    test('weights sit inside the axis range the fonts support', () {
      for (final entry in styles.entries) {
        expect(
          _weightOf(entry.value),
          inInclusiveRange(100, 900),
          reason: '${entry.key} is outside the wght axis',
        );
      }
    });

    test('label and kicker differ only by tracking', () {
      expect(AuraText.label.fontSize, AuraText.kicker.fontSize);
      expect(_weightOf(AuraText.label), _weightOf(AuraText.kicker));
      expect(
        AuraText.label.letterSpacing,
        isNot(AuraText.kicker.letterSpacing),
      );
    });
  });

  group('Arabic fallback', () {
    // Not one of Fraunces, Outfit or Inter contains an Arabic glyph, so without
    // a bundled fallback every Arabic string would be drawn by whatever the
    // platform supplied and the Arabic build would not match the design.
    const arabic = 'الطقس صحو';

    /// The same style with the Arabic fallback removed, as a control.
    TextStyle withoutFallback(TextStyle style) => TextStyle(
      fontFamily: style.fontFamily,
      fontSize: style.fontSize,
      fontVariations: style.fontVariations,
      letterSpacing: style.letterSpacing,
      height: style.height,
    );

    test('every style declares one of the bundled Arabic families', () {
      for (final entry in _styles.entries) {
        expect(
          entry.value.fontFamilyFallback,
          anyOf(<Object>[
            <String>[
              'packages/${AuraFonts.package}/${AuraFonts.displayArabic}',
            ],
            <String>['packages/${AuraFonts.package}/${AuraFonts.textArabic}'],
          ]),
          reason: '${entry.key} would fall back to a platform font in Arabic',
        );
      }
    });

    test('the display family falls back to the kufi face', () {
      expect(AuraText.titleScreen.fontFamilyFallback, <String>[
        'packages/${AuraFonts.package}/${AuraFonts.displayArabic}',
      ]);
    });

    test('both text families fall back to the same Arabic face', () {
      expect(
        AuraText.condition.fontFamilyFallback,
        AuraText.body.fontFamilyFallback,
      );
    });

    test('Arabic lays out through the fallback, not the test placeholder', () {
      for (final entry in _styles.entries) {
        final resolved = _widthOf(entry.value, text: arabic);
        final placeholder = _widthOf(
          withoutFallback(entry.value),
          text: arabic,
        );
        expect(resolved, greaterThan(0), reason: '${entry.key} laid out empty');
        expect(
          resolved,
          isNot(closeTo(placeholder, 0.01)),
          reason:
              '${entry.key} measured Arabic identically with and without the '
              'fallback, so the bundled Arabic font is not being reached',
        );
      }
    });

    test('the fallback leaves Latin metrics untouched', () {
      // Fallback resolves per glyph, so the pen parity of every Latin screen
      // has to be bit-for-bit unaffected by adding an Arabic family behind it.
      for (final entry in _styles.entries) {
        expect(
          _widthOf(entry.value, text: 'Mostly Sunny'),
          _widthOf(withoutFallback(entry.value), text: 'Mostly Sunny'),
          reason: '${entry.key} changed Latin width when a fallback was added',
        );
      }
    });

    test('digits still come from the Latin family', () {
      // The hero temperature is the app's identity. Western digits keep it in
      // Fraunces in both locales; Arabic-Indic digits would hand the largest
      // type on the screen to the fallback face instead.
      expect(
        _widthOf(AuraText.display, text: '35°'),
        _widthOf(withoutFallback(AuraText.display), text: '35°'),
      );
    });
  });
}
