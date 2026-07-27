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

  group('the condensed bar', () {
    testWidgets('is absent until the page scrolls', (tester) async {
      final harness = HomeHarness(snapshot: weatherFixture());
      await pumpScreen(tester, harness.screen());
      await tester.pumpAndSettle();

      expect(
        find.byType(HomeCondensedBar),
        findsOneWidget,
        reason: 'the listener itself should always be mounted',
      );
      expect(
        find.descendant(
          of: find.byType(HomeCondensedBar),
          matching: find.byType(AuraGlass),
        ),
        findsNothing,
        reason: 'the bar drew itself before anything had scrolled',
      );
    });

    testWidgets('appears once the hero has gone, carrying the place', (
      tester,
    ) async {
      final harness = HomeHarness(snapshot: weatherFixture());
      await pumpScreen(tester, harness.screen());
      await tester.pumpAndSettle();

      await _scrollTo(tester, 400);

      final bar = find.byType(HomeCondensedBar);
      expect(
        find.descendant(of: bar, matching: find.byType(AuraGlass)),
        findsWidgets,
      );
      expect(
        find.descendant(of: bar, matching: find.text('Cairo')),
        findsOneWidget,
        reason: 'the bar does not say which place is showing',
      );
    });

    testWidgets('keeps every destination the top bar had', (tester) async {
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
      await _scrollTo(tester, 400);

      final bar = find.byType(HomeCondensedBar);
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
}
