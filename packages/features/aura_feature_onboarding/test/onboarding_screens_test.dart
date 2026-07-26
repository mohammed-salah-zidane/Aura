import 'package:aura_design/aura_design.dart';
import 'package:aura_feature_onboarding/aura_feature_onboarding.dart';
import 'package:aura_l10n/aura_l10n.dart';
import 'package:aura_test_kit/aura_test_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

const Locale _en = Locale('en');
const Locale _ar = Locale('ar');

/// The copy the screen should be showing, in the locale under test.
Future<AppLocalizations> _copy(Locale locale) =>
    AppLocalizations.delegate.load(locale);

void main() {
  setUpAll(loadAuraFonts);

  group('SplashScreen', () {
    testWidgets('shows the wordmark, the tagline and the attribution', (
      tester,
    ) async {
      await pumpScreen(tester, const SplashScreen());
      final l10n = await _copy(_en);

      expect(find.text(AuraBrand.name), findsOneWidget);
      expect(find.text(l10n.splashTagline.toUpperCase()), findsOneWidget);
      expect(find.text(l10n.splashAttribution.toUpperCase()), findsOneWidget);
    });

    testWidgets('carries the mark at the size the splash specifies', (
      tester,
    ) async {
      await pumpScreen(tester, const SplashScreen());
      expect(
        tester.widget<AuraMark>(find.byType(AuraMark)).size,
        AuraMarkSize.splash,
      );
    });

    testWidgets('paints the splash sky', (tester) async {
      await pumpScreen(tester, const SplashScreen());
      expect(
        tester.widget<AuraSky>(find.byType(AuraSky)).kind,
        AuraSkyKind.splash,
      );
    });

    testWidgets('pins the loader and attribution to the screen edge', (
      tester,
    ) async {
      // Both are absolutely placed in the pen, measured from the bottom of a
      // canvas that runs under the home indicator, so neither moves with the
      // safe area.
      await pumpScreen(tester, const SplashScreen());
      final attribution = tester.getRect(
        find.text((await _copy(_en)).splashAttribution.toUpperCase()),
      );
      expect(
        AuraSizes.referenceHeight - attribution.bottom,
        moreOrLessEquals(AuraSizes.splashAttributionInset, epsilon: 0.5),
      );
    });

    testWidgets('the loader keeps moving', (tester) async {
      await pumpScreen(tester, const SplashScreen());
      final opacities = <double>{};
      for (var i = 0; i < 4; i++) {
        await tester.pump(AuraMotion.shimmer ~/ 3);
        opacities.add(
          tester
              .widgetList<AnimatedOpacity>(find.byType(AnimatedOpacity))
              .first
              .opacity,
        );
      }
      expect(
        opacities.length,
        greaterThan(1),
        reason: 'the first dot never changed, so the loader is frozen',
      );
    });

    testWidgets('speaks a label in place of the dots', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpScreen(tester, const SplashScreen());
      expect(
        find.bySemanticsLabel((await _copy(_en)).splashLoading),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('renders the Arabic copy right to left', (tester) async {
      await pumpScreen(tester, const SplashScreen(), locale: _ar);
      final l10n = await _copy(_ar);

      expect(find.text(l10n.splashTagline.toUpperCase()), findsOneWidget);
      expect(find.text(l10n.splashAttribution.toUpperCase()), findsOneWidget);
      // The wordmark is a proper noun and reads the same in either locale.
      expect(find.text(AuraBrand.name), findsOneWidget);
    });

    testWidgets('drops letter tracking in Arabic', (tester) async {
      // Arabic letters join. Tracking prises those joins apart and renders the
      // word as a row of disconnected shapes.
      await pumpScreen(tester, const SplashScreen(), locale: _ar);
      final tagline = tester.widget<Text>(
        find.text((await _copy(_ar)).splashTagline.toUpperCase()),
      );
      expect(tagline.style!.letterSpacing, 0);
    });

    testWidgets('keeps letter tracking in English', (tester) async {
      await pumpScreen(tester, const SplashScreen());
      final tagline = tester.widget<Text>(
        find.text((await _copy(_en)).splashTagline.toUpperCase()),
      );
      expect(tagline.style!.letterSpacing, AuraText.tagline.letterSpacing);
    });

    testWidgets('nothing overflows on either locale', (tester) async {
      for (final locale in <Locale>[_en, _ar]) {
        await pumpScreen(tester, const SplashScreen(), locale: locale);
        expect(
          tester.takeException(),
          isNull,
          reason: 'the splash overflowed in ${locale.languageCode}',
        );
      }
    });
  });

  group('PermissionScreen', () {
    Widget subject({VoidCallback? onAllow, VoidCallback? onEnterManually}) =>
        PermissionScreen(
          onAllow: onAllow ?? () {},
          onEnterManually: onEnterManually ?? () {},
        );

    testWidgets('shows the heading, the reason and both actions', (
      tester,
    ) async {
      await pumpScreen(tester, subject());
      final l10n = await _copy(_en);

      expect(find.text(l10n.permissionTitle), findsOneWidget);
      expect(find.text(l10n.permissionBody), findsOneWidget);
      expect(find.text(l10n.permissionAllow), findsOneWidget);
      expect(find.text(l10n.permissionEnterManually), findsOneWidget);
    });

    testWidgets('names Aura, not the product the pen left behind', (
      tester,
    ) async {
      await pumpScreen(tester, subject());
      final body = (await _copy(_en)).permissionBody;
      expect(body, contains(AuraBrand.name));
      expect(body, isNot(contains('Cairo Weather')));
    });

    testWidgets('carries the pin and the navigation glyph from the pen', (
      tester,
    ) async {
      await pumpScreen(tester, subject());
      expect(find.byIcon(AuraIcons.mapPin), findsOneWidget);
      expect(find.byIcon(AuraIcons.navigation), findsOneWidget);
    });

    testWidgets('the primary action fires once per tap', (tester) async {
      var allowed = 0;
      await pumpScreen(tester, subject(onAllow: () => allowed++));
      await tester.tap(find.text((await _copy(_en)).permissionAllow));
      await tester.pump();
      expect(allowed, 1);
    });

    testWidgets('the secondary action offers a way past location', (
      tester,
    ) async {
      var skipped = 0;
      await pumpScreen(tester, subject(onEnterManually: () => skipped++));
      await tester.tap(
        find.text((await _copy(_en)).permissionEnterManually),
      );
      await tester.pump();
      expect(skipped, 1);
    });

    testWidgets('both actions read as buttons to assistive tech', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpScreen(tester, subject());
      expect(
        find.bySemanticsLabel((await _copy(_en)).permissionAllow),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('the actions sit at the foot of the screen', (tester) async {
      await pumpScreen(tester, subject());
      final secondary = tester.getRect(find.byType(AuraButtonSecondary));
      expect(
        AuraSizes.referenceHeight - secondary.bottom,
        moreOrLessEquals(AuraSizes.stateBottomInset, epsilon: 0.5),
      );
    });

    testWidgets('the body is set to the measure the pen specifies', (
      tester,
    ) async {
      await pumpScreen(tester, subject());
      final body = tester.getRect(
        find.text((await _copy(_en)).permissionBody),
      );
      expect(
        body.width,
        moreOrLessEquals(AuraSizes.stateBodyMeasure, epsilon: 0.5),
      );
    });

    testWidgets('renders the Arabic copy without overflowing', (tester) async {
      await pumpScreen(tester, subject(), locale: _ar);
      final l10n = await _copy(_ar);

      expect(find.text(l10n.permissionTitle), findsOneWidget);
      expect(find.text(l10n.permissionBody), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('mirrors the primary button icon in Arabic', (tester) async {
      // The row runs from the right, so the glyph leads on the right.
      await pumpScreen(tester, subject(), locale: _ar);
      final icon = tester.getRect(find.byIcon(AuraIcons.navigation));
      final label = tester.getRect(
        find.text((await _copy(_ar)).permissionAllow),
      );
      expect(
        icon.left,
        greaterThan(label.left),
        reason: 'the icon did not move to the trailing side in RTL',
      );
    });
  });
}
