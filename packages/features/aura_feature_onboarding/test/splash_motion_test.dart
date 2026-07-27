import 'package:aura_design/aura_design.dart';
import 'package:aura_feature_onboarding/aura_feature_onboarding.dart';
import 'package:aura_l10n/aura_l10n.dart';
import 'package:aura_test_kit/aura_test_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'onboarding_screens_test.dart' show splashScreen;

const Locale _ar = Locale('ar');

AuraMark _mark(WidgetTester tester) =>
    tester.widget<AuraMark>(find.byType(AuraMark));

/// Lets the view model's timer and the exit finish.
///
/// `pumpAndSettle` is not available here: with motion on, the glow breathes
/// for as long as the screen is up, so the tree never settles.
Future<void> _drain(WidgetTester tester) async {
  await tester.pump(SplashViewModel.minimumOnScreen);
  await tester.pump(AuraMotion.splashExit);
  await tester.pump(AuraMotion.control);
}

/// The tagline's style as the screen is currently rendering it.
TextStyle _taglineStyle(WidgetTester tester, String tagline) =>
    tester.widget<Text>(find.text(tagline)).style!;

void main() {
  setUpAll(loadAuraFonts);

  group('the splash reveal', () {
    testWidgets('brings the mark out of nothing and lands on the pen frame', (
      tester,
    ) async {
      await pumpScreen(tester, splashScreen(), reduceMotion: false);

      expect(
        _mark(tester).reveal,
        0,
        reason: 'the mark was already there on the first frame',
      );

      await tester.pump(AuraMotion.splashReveal ~/ 2);
      final midway = _mark(tester).reveal;
      expect(midway, greaterThan(0));
      expect(midway, lessThan(1));

      await tester.pump(AuraMotion.splashReveal + AuraMotion.splashSettle);
      expect(
        _mark(tester).reveal,
        1,
        reason: 'the reveal did not finish on the frame the pen draws',
      );
      await _drain(tester);
    });

    testWidgets('the glow keeps breathing once the mark has arrived', (
      tester,
    ) async {
      await pumpScreen(tester, splashScreen(), reduceMotion: false);
      await tester.pump(AuraMotion.splashReveal + AuraMotion.splashSettle);

      final glows = <double>{};
      for (var i = 0; i < 4; i++) {
        await tester.pump(AuraMotion.breath ~/ 5);
        glows.add(_mark(tester).glow);
      }
      expect(
        glows.length,
        greaterThan(1),
        reason: 'the mark arrived and then went dead',
      );
      await _drain(tester);
    });

    testWidgets('the lockup arrives after the mark, not with it', (
      tester,
    ) async {
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      await pumpScreen(tester, splashScreen(), reduceMotion: false);

      double wordmarkOpacity() => tester
          .widget<Opacity>(
            find
                .ancestor(
                  of: find.text(AuraBrand.name),
                  matching: find.byType(Opacity),
                )
                .first,
          )
          .opacity;

      expect(wordmarkOpacity(), 0);
      await tester.pump(AuraMotion.splashReveal ~/ 3);
      expect(
        wordmarkOpacity(),
        0,
        reason: 'the wordmark did not wait for the mark',
      );

      await tester.pump(AuraMotion.splashReveal + AuraMotion.splashSettle);
      expect(wordmarkOpacity(), 1);
      expect(find.text(l10n.splashTagline.toUpperCase()), findsOneWidget);
      await _drain(tester);
    });

    testWidgets('the tagline settles on the tracking the pen sets', (
      tester,
    ) async {
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      final tagline = l10n.splashTagline.toUpperCase();
      await pumpScreen(tester, splashScreen(), reduceMotion: false);

      await tester.pump(AuraMotion.splashReveal ~/ 2);
      expect(
        _taglineStyle(tester, tagline).letterSpacing,
        greaterThan(AuraText.tagline.letterSpacing!),
        reason: 'the tracking did not start wide',
      );

      await tester.pump(AuraMotion.splashReveal + AuraMotion.splashSettle);
      expect(
        _taglineStyle(tester, tagline).letterSpacing,
        moreOrLessEquals(AuraText.tagline.letterSpacing!, epsilon: 0.001),
      );
      await _drain(tester);
    });

    testWidgets('in Arabic the tracking animation stays at zero throughout', (
      tester,
    ) async {
      // Arabic is cursive, so any letter-spacing prises the joins apart. The
      // animation multiplies the script's own tracking, which `forScript`
      // already zeroes, so it collapses to a plain fade without a special case.
      final l10n = await AppLocalizations.delegate.load(_ar);
      final tagline = l10n.splashTagline.toUpperCase();
      await pumpScreen(
        tester,
        splashScreen(),
        locale: _ar,
        reduceMotion: false,
      );

      for (final step in <Duration>[
        AuraMotion.splashReveal ~/ 3,
        AuraMotion.splashReveal ~/ 2,
        AuraMotion.splashReveal + AuraMotion.splashSettle,
      ]) {
        await tester.pump(step);
        expect(
          _taglineStyle(tester, tagline).letterSpacing,
          0,
          reason: 'Arabic picked up tracking mid-reveal',
        );
      }
      await _drain(tester);
    });
  });

  group('reduced motion', () {
    testWidgets('opens on the finished lockup', (tester) async {
      await pumpScreen(tester, splashScreen());
      expect(_mark(tester).reveal, 1);
      expect(_mark(tester).glow, 1);
      await _drain(tester);
    });

    testWidgets('still reports where the app should open', (tester) async {
      // The handoff must never depend on an animation finishing, or a muted
      // ticker would strand the app on the splash forever.
      SplashDestination? destination;
      await pumpScreen(
        tester,
        splashScreen(onReady: (value) => destination = value),
      );
      await tester.pump(SplashViewModel.minimumOnScreen);
      await tester.pumpAndSettle();

      expect(destination, isNotNull);
    });
  });

  testWidgets('the lockup leaves before the screen hands over', (tester) async {
    SplashDestination? destination;
    await pumpScreen(
      tester,
      splashScreen(onReady: (value) => destination = value),
      reduceMotion: false,
    );
    // The view model resolves on its own timer, and the rebuild that carries
    // the destination lands a frame or two later once Riverpod has scheduled.
    await tester.pump(SplashViewModel.minimumOnScreen);
    await tester.pump();
    await tester.pump();

    expect(
      destination,
      isNull,
      reason: 'the screen handed over before playing its exit',
    );

    double lockupOpacity() => tester
        .widget<Opacity>(
          find
              .ancestor(
                of: find.text(AuraBrand.name),
                matching: find.byType(Opacity),
              )
              .last,
        )
        .opacity;

    await tester.pump(AuraMotion.splashExit ~/ 2);
    expect(
      lockupOpacity(),
      lessThan(1),
      reason: 'the lockup is not leaving',
    );

    await tester.pump(AuraMotion.splashExit);
    expect(destination, isNotNull);
    await tester.pump(AuraMotion.control);
  });
}
