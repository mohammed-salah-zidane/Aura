import 'package:aura_core/aura_core.dart';
import 'package:aura_design/aura_design.dart';
import 'package:aura_domain/aura_domain.dart';
import 'package:aura_feature_home/aura_feature_home.dart';
import 'package:aura_l10n/aura_l10n.dart';
import 'package:aura_test_kit/aura_test_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/home_harness.dart';

/// The page, as opposed to the hourly strip, which also scrolls.
final Finder _page = find.byWidgetPredicate(
  (widget) =>
      widget is Scrollable && widget.axisDirection == AxisDirection.down,
);

/// Scrolls the page to [points] and lets the listeners answer.
///
/// Driven through the position rather than a drag, because what is under test
/// is what the offset does to the hero and the bar, not the gesture that
/// produced it.
Future<void> _scrollTo(WidgetTester tester, double points) async {
  tester.state<ScrollableState>(_page).position.jumpTo(points);
  await tester.pump();
}

/// A reading whose sky has no ambient layer.
///
/// A test that leaves motion on cannot use `pumpAndSettle` against a weather
/// sky, because its ambient layer repeats for as long as the screen is up. An
/// unknown condition resolves to the brand sky, which is still, so the entrance
/// and the parallax can be driven to completion.
WeatherSnapshot _stillSky() => weatherFixture(condition: AuraCondition.unknown);

void main() {
  setUpAll(loadAuraFonts);

  group('the sky follows the condition', () {
    testWidgets('each condition brings its own ambient layer', (tester) async {
      // The animation is keyed off the same enum the gradient is, so a screen
      // cannot end up raining over a clear sky.
      const expected = <AuraCondition, AuraAmbientKind>{
        AuraCondition.clearDay: AuraAmbientKind.breath,
        AuraCondition.clearNight: AuraAmbientKind.twinkle,
        AuraCondition.partlyCloudy: AuraAmbientKind.drift,
        AuraCondition.overcast: AuraAmbientKind.drift,
        AuraCondition.fog: AuraAmbientKind.drift,
        AuraCondition.rain: AuraAmbientKind.rain,
        AuraCondition.snow: AuraAmbientKind.snow,
        AuraCondition.thunderstorm: AuraAmbientKind.rain,
      };

      for (final entry in expected.entries) {
        final harness = HomeHarness(
          snapshot: weatherFixture(condition: entry.key),
        );
        await pumpScreen(tester, harness.screen());
        await tester.pumpAndSettle();

        expect(
          tester.widget<AuraSky>(find.byType(AuraSky)).kind.ambient.kind,
          entry.value,
          reason: '${entry.key.name} drew the wrong ambient layer',
        );
      }
    });

    testWidgets('a condition the domain does not know moves nothing', (
      tester,
    ) async {
      final harness = HomeHarness(
        snapshot: weatherFixture(condition: AuraCondition.unknown),
      );
      await pumpScreen(tester, harness.screen());
      await tester.pumpAndSettle();

      expect(
        tester.widget<AuraSky>(find.byType(AuraSky)).kind.ambient.kind,
        AuraAmbientKind.none,
      );
    });
  });

  group('sections arrive staggered', () {
    testWidgets('every section is wrapped, in reading order', (tester) async {
      final harness = HomeHarness(snapshot: weatherFixture());
      await pumpScreen(tester, harness.screen());
      await tester.pumpAndSettle();

      final entrances = tester
          .widgetList<AuraEntrance>(find.byType(AuraEntrance))
          .toList();
      expect(entrances.length, greaterThan(1));
      for (var i = 0; i < entrances.length; i++) {
        expect(entrances[i].index, i, reason: 'section $i is out of order');
      }
    });

    testWidgets('a refresh does not replay the entrance', (tester) async {
      // The screen keeps the previous reading through a refresh on purpose.
      // Replaying the arrival would blank what that behaviour protects.
      final harness = HomeHarness(snapshot: _stillSky());
      await pumpScreen(tester, harness.screen(), reduceMotion: false);
      await tester.pumpAndSettle();

      final before = tester
          .widgetList<Opacity>(find.byType(Opacity))
          .map((o) => o.opacity)
          .toList();
      expect(before, everyElement(1.0));

      await harness.container.read(homeViewModelProvider.notifier).refresh();
      await tester.pump();

      expect(
        tester.widgetList<Opacity>(find.byType(Opacity)).map((o) => o.opacity),
        everyElement(1.0),
        reason: 'the sections faded out again on a refresh',
      );
      await tester.pumpAndSettle();
    });
  });

  group('the floating bar', () {
    testWidgets('is up when the page opens', (tester) async {
      final harness = HomeHarness(snapshot: weatherFixture());
      await pumpScreen(tester, harness.screen());
      await tester.pumpAndSettle();

      expect(find.byType(HomeBottomBar), findsOneWidget);
      expect(
        tester
            .widget<AnimatedOpacity>(
              find
                  .descendant(
                    of: find.byType(HomeBottomBar),
                    matching: find.byType(AnimatedOpacity),
                  )
                  .first,
            )
            .opacity,
        1,
      );
    });

    testWidgets('carries every destination the page needs', (tester) async {
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      var search = 0;
      var saved = 0;
      var settings = 0;

      final harness = HomeHarness(snapshot: weatherFixture());
      await pumpScreen(
        tester,
        harness.screen(
          onOpenSearch: () => search++,
          onOpenSavedCities: () => saved++,
          onOpenSettings: () => settings++,
        ),
      );
      await tester.pumpAndSettle();

      final bar = find.byType(HomeBottomBar);
      for (final label in <String>[
        l10n.homeSearch,
        l10n.homeSavedCities,
        l10n.homeSettings,
      ]) {
        await tester.tap(
          find.descendant(of: bar, matching: find.bySemanticsLabel(label)),
        );
        await tester.pump();
      }

      expect(<int>[search, saved, settings], <int>[1, 1, 1]);
    });

    testWidgets('gets out of the way going down and returns coming up', (
      tester,
    ) async {
      final harness = HomeHarness(snapshot: weatherFixture());
      await pumpScreen(tester, harness.screen());
      await tester.pumpAndSettle();

      double opacity() => tester
          .widget<AnimatedOpacity>(
            find
                .descendant(
                  of: find.byType(HomeBottomBar),
                  matching: find.byType(AnimatedOpacity),
                )
                .first,
          )
          .opacity;

      await _scrollTo(tester, 400);
      expect(opacity(), 0, reason: 'the bar stayed over the content');

      await _scrollTo(tester, 300);
      expect(opacity(), 1, reason: 'the bar did not come back');
    });

    testWidgets('the content clears the bar rather than ending under it', (
      tester,
    ) async {
      // The page runs beneath the glass on purpose, so only the last card has
      // to be given room.
      expect(
        HomeContent.padding.bottom,
        greaterThanOrEqualTo(HomeBottomBar.scrimHeight),
      );
    });

    testWidgets('one place shows no dots to page through', (tester) async {
      final harness = HomeHarness(snapshot: weatherFixture());
      await pumpScreen(tester, harness.screen());
      await tester.pumpAndSettle();

      expect(find.byType(HomePageDots), findsOneWidget);
      expect(
        tester.widget<HomePageDots>(find.byType(HomePageDots)).count,
        1,
        reason: 'the device position is the only place saved',
      );
    });

    testWidgets('a dot for every saved place, plus the device position', (
      tester,
    ) async {
      final harness = HomeHarness(
        snapshot: weatherFixture(),
        saved: <SavedCity>[
          SavedCity(
            location: const LocationRef(query: 'Giza'),
            name: 'Giza',
            country: 'Egypt',
            addedAt: fixtureNow,
          ),
          SavedCity(
            location: const LocationRef(query: 'Luxor'),
            name: 'Luxor',
            country: 'Egypt',
            addedAt: fixtureNow,
          ),
        ],
      );
      await pumpScreen(tester, harness.screen());
      await tester.pumpAndSettle();

      final dots = tester.widget<HomePageDots>(find.byType(HomePageDots));
      expect(dots.count, 3);
      expect(dots.index, 0, reason: 'the device position leads the set');
    });
  });

  group('reduced motion', () {
    testWidgets('shows every section at once, with nothing part-faded', (
      tester,
    ) async {
      final harness = HomeHarness(snapshot: weatherFixture());
      await pumpScreen(tester, harness.screen());
      await tester.pumpAndSettle();

      expect(
        tester.widgetList<AuraEntrance>(find.byType(AuraEntrance)).isNotEmpty,
        isTrue,
      );
      expect(
        tester.widgetList<Opacity>(find.byType(Opacity)).map((o) => o.opacity),
        everyElement(1.0),
      );
    });

    testWidgets('leaves the hero where the design puts it while scrolling', (
      tester,
    ) async {
      final harness = HomeHarness(snapshot: weatherFixture());
      await pumpScreen(tester, harness.screen());
      await tester.pumpAndSettle();

      final before = tester.getTopLeft(find.byType(HomeHero));
      await _scrollTo(tester, 60);
      final after = tester.getTopLeft(find.byType(HomeHero));

      expect(
        before.dy - after.dy,
        moreOrLessEquals(60, epsilon: 0.5),
        reason: 'the hero parallaxed with motion reduced',
      );
    });
  });

  testWidgets('the hero parallaxes behind the content as it scrolls', (
    tester,
  ) async {
    final harness = HomeHarness(snapshot: _stillSky());
    await pumpScreen(tester, harness.screen(), reduceMotion: false);
    await tester.pumpAndSettle();

    final before = tester.getTopLeft(find.byType(HomeHero));
    await _scrollTo(tester, 60);
    final after = tester.getTopLeft(find.byType(HomeHero));

    // It lags the page rather than tracking it, so it travels less than the
    // distance scrolled.
    expect(
      before.dy - after.dy,
      moreOrLessEquals(60 * (1 - AuraMotion.heroParallax), epsilon: 0.5),
    );
    await tester.pumpAndSettle();
  });

  group('the body riding the sky', () {
    AuraCelestial? bodyOf(WidgetTester tester) =>
        tester.widget<AuraSky>(find.byType(AuraSky)).celestial;

    testWidgets('the sun rides the sky in the middle of the day', (
      tester,
    ) async {
      // The fixture's clock reads 14:34, between its sunrise and its sunset.
      final harness = HomeHarness(snapshot: weatherFixture());
      await pumpScreen(tester, harness.screen());
      await tester.pumpAndSettle();

      final body = bodyOf(tester);
      expect(body?.body, AuraCelestialBody.sun);
      expect(body!.position, inInclusiveRange(0, 1));
    });

    testWidgets('the moon takes over once the sun is down', (tester) async {
      final harness = HomeHarness(
        snapshot: weatherFixture(
          condition: AuraCondition.clearNight,
          localTime: DateTime(2026, 7, 26, 21, 30),
        ),
      );
      await pumpScreen(tester, harness.screen());
      await tester.pumpAndSettle();

      final body = bodyOf(tester);
      expect(body?.body, AuraCelestialBody.moon);
      expect(body!.illumination, inInclusiveRange(0, 1));
    });

    testWidgets('a day with no sun times falls through to the moon', (
      tester,
    ) async {
      // WeatherAPI answers `No sunrise` at high latitudes, which is a real
      // reading rather than a parse failure. The moon still has times, so the
      // honest answer is the moon rather than an empty sky.
      final harness = HomeHarness(snapshot: weatherFixture(hasSunTimes: false));
      await pumpScreen(tester, harness.screen());
      await tester.pumpAndSettle();

      expect(bodyOf(tester)?.body, AuraCelestialBody.moon);
    });

    testWidgets('no screen without a reading claims to know where the sun is', (
      tester,
    ) async {
      final harness = HomeHarness(failure: const NoConnection());
      await pumpScreen(tester, harness.screen());
      await tester.pumpAndSettle();

      expect(bodyOf(tester), isNull);
    });
  });
}
