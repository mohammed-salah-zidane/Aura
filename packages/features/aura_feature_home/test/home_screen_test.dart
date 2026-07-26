import 'package:aura_core/aura_core.dart';
import 'package:aura_design/aura_design.dart';
import 'package:aura_domain/aura_domain.dart';
import 'package:aura_feature_home/aura_feature_home.dart';
import 'package:aura_l10n/aura_l10n.dart';
import 'package:aura_test_kit/aura_test_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/home_harness.dart';

const Locale _ar = Locale('ar');

Future<AppLocalizations> _copy([Locale locale = const Locale('en')]) =>
    AppLocalizations.delegate.load(locale);

void main() {
  setUpAll(loadAuraFonts);

  group('while the first reading is on its way', () {
    testWidgets('build shows the loading screen, not an empty sky', (
      tester,
    ) async {
      final harness = HomeHarness(delay: const Duration(seconds: 1));
      await pumpScreen(tester, harness.screen());

      expect(find.byType(HomeLoading), findsOneWidget);
      expect(find.text((await _copy()).homeLoadingStatus), findsOneWidget);
      await tester.pumpAndSettle(const Duration(seconds: 2));
    });

    testWidgets('build shimmers rather than spinning where content goes', (
      tester,
    ) async {
      final harness = HomeHarness(delay: const Duration(seconds: 1));
      await pumpScreen(tester, harness.screen());

      expect(find.byType(AuraSkeleton), findsWidgets);
      await tester.pumpAndSettle(const Duration(seconds: 2));
    });
  });

  group('with a reading', () {
    testWidgets('build shows the place, the reading and the condition', (
      tester,
    ) async {
      final harness = HomeHarness();
      await pumpScreen(tester, harness.screen());
      await tester.pumpAndSettle();

      expect(find.text('Cairo'), findsOneWidget);
      expect(find.text('35°'), findsWidgets);
      expect(find.text('Sunny'), findsOneWidget);
    });

    testWidgets('build paints the sky the condition asks for', (tester) async {
      final harness = HomeHarness(
        snapshot: weatherFixture(condition: AuraCondition.thunderstorm),
      );
      await pumpScreen(tester, harness.screen());
      await tester.pumpAndSettle();

      expect(
        tester.widget<AuraSky>(find.byType(AuraSky)).kind,
        AuraSkyKind.thunderstorm,
      );
    });

    testWidgets('build renders every reading the API returns for a metric', (
      tester,
    ) async {
      final harness = HomeHarness();
      await pumpScreen(tester, harness.screen());
      await tester.pumpAndSettle();
      final l10n = await _copy();

      expect(find.text('15 km/h'), findsOneWidget);
      expect(find.text(l10n.metricWindSub('NW', '22')), findsOneWidget);
      expect(find.text(l10n.metricDewPoint('19°')), findsOneWidget);
      expect(find.text('1013'), findsOneWidget);
      expect(find.text('29.92 inHg'), findsOneWidget);
    });

    testWidgets('build leaves a metric sub-line empty when no field backs it', (
      tester,
    ) async {
      // The pen writes "Warmer than air" under the apparent temperature and
      // "Crystal clear" under visibility. WeatherAPI returns neither.
      final harness = HomeHarness();
      await pumpScreen(tester, harness.screen());
      await tester.pumpAndSettle();

      expect(find.text('Warmer than air'), findsNothing);
      expect(find.text('Crystal clear'), findsNothing);
    });

    testWidgets('build writes no narrative above the hourly strip', (
      tester,
    ) async {
      final harness = HomeHarness();
      await pumpScreen(tester, harness.screen());
      await tester.pumpAndSettle();

      // Every string on the screen traces to a field, a published scale or the
      // app's own chrome. A sentence about the day is none of those.
      final sentences = tester
          .widgetList<Text>(find.byType(Text))
          .map((text) => text.data ?? '')
          .where((line) => line.split(' ').length > 12);
      expect(sentences, isEmpty);
    });

    testWidgets('build starts the hourly strip at the current hour', (
      tester,
    ) async {
      final harness = HomeHarness();
      await pumpScreen(tester, harness.screen());
      await tester.pumpAndSettle();

      expect(find.text((await _copy()).hourNow), findsOneWidget);
    });

    testWidgets('build shows the air quality card only when the API sent one', (
      tester,
    ) async {
      final l10n = await _copy();
      final harness = HomeHarness(
        snapshot: weatherFixture(airQuality: null),
      );
      await pumpScreen(tester, harness.screen());
      await tester.pumpAndSettle();

      expect(
        find.text(l10n.sectionAirQuality.toUpperCase()),
        findsNothing,
      );
    });

    testWidgets('build shows the alert banner only when one is active', (
      tester,
    ) async {
      final harness = HomeHarness();
      await pumpScreen(tester, harness.screen());
      await tester.pumpAndSettle();
      expect(find.byType(AuraAlertBanner), findsNothing);

      final alerted = HomeHarness(
        snapshot: weatherFixture(alerts: <WeatherAlert>[alertFixture()]),
      );
      await pumpScreen(tester, alerted.screen());
      await tester.pumpAndSettle();
      expect(find.byType(AuraAlertBanner), findsOneWidget);
      expect(find.text('Heat Advisory'), findsOneWidget);
    });

    testWidgets('build opens the detail behind each card', (tester) async {
      var forecast = 0;
      var air = 0;
      var astro = 0;
      final harness = HomeHarness();
      await pumpScreen(
        tester,
        harness.screen(
          onOpenForecast: () => forecast++,
          onOpenAirQuality: () => air++,
          onOpenSunAndMoon: () => astro++,
        ),
        // The page is taller than a phone. Pumping it whole is what lets a tap
        // land on a card that would otherwise be below the fold.
        size: const Size(AuraSizes.referenceWidth, 2000),
      );
      await tester.pumpAndSettle();
      final l10n = await _copy();

      await tester.tap(find.text(l10n.sectionForecast.toUpperCase()));
      await tester.tap(find.text(l10n.sectionAirQuality.toUpperCase()));
      await tester.tap(find.text(l10n.sectionSunAndMoon.toUpperCase()));
      await tester.pump();

      expect(<int>[forecast, air, astro], <int>[1, 1, 1]);
    });

    testWidgets('build reads the temperature in the stored unit', (
      tester,
    ) async {
      final harness = HomeHarness()
        ..settings.units = const UnitPreferences(
          temperature: TemperatureUnit.fahrenheit,
        );
      await pumpScreen(tester, harness.screen());
      await tester.pumpAndSettle();

      expect(find.text('95°'), findsWidgets);
      expect(find.text('35°'), findsNothing);
    });
  });

  group('when the service cannot be reached', () {
    testWidgets('build offers the stored reading and says how old it is', (
      tester,
    ) async {
      final harness = HomeHarness(
        fetchedAt: fixtureNow.subtract(const Duration(hours: 2)),
      );
      await pumpScreen(tester, harness.screen());
      await tester.pumpAndSettle();
      final l10n = await _copy();

      expect(find.text(l10n.offlineTitle), findsOneWidget);
      expect(find.text(l10n.offlineUseSavedData), findsOneWidget);
      expect(
        find.textContaining(l10n.homeLastUpdated(l10n.durationHours(2))),
        findsOneWidget,
      );
    });

    testWidgets('build shows the stored reading once the user accepts it', (
      tester,
    ) async {
      final harness = HomeHarness(
        fetchedAt: fixtureNow.subtract(const Duration(hours: 2)),
      );
      await pumpScreen(tester, harness.screen());
      await tester.pumpAndSettle();

      await tester.tap(find.text((await _copy()).offlineUseSavedData));
      await tester.pumpAndSettle();

      expect(find.text('Cairo'), findsOneWidget);
      expect(find.text('35°'), findsWidgets);
    });

    testWidgets('build names the failure and offers a way forward', (
      tester,
    ) async {
      final harness = HomeHarness(failure: const RateLimited());
      await pumpScreen(tester, harness.screen());
      await tester.pumpAndSettle();
      final l10n = await _copy();

      expect(find.text(l10n.failureRateLimitedTitle), findsOneWidget);
      expect(find.text(l10n.offlineTryAgain), findsOneWidget);
      // There is nothing stored, so there is nothing to offer.
      expect(find.text(l10n.offlineUseSavedData), findsNothing);
    });

    testWidgets('build asks again when the user says so', (tester) async {
      final harness = HomeHarness(failure: const NoConnection());
      await pumpScreen(tester, harness.screen());
      await tester.pumpAndSettle();
      final before = harness.repository.snapshotCalls;

      await tester.tap(find.text((await _copy()).offlineTryAgain));
      await tester.pumpAndSettle();

      expect(harness.repository.snapshotCalls, greaterThan(before));
    });
  });

  group('in Arabic', () {
    testWidgets('build renders the whole screen without overflowing', (
      tester,
    ) async {
      final harness = HomeHarness();
      await pumpScreen(tester, harness.screen(), locale: _ar);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        find.text((await _copy(_ar)).metricWind.toUpperCase()),
        findsOneWidget,
      );
    });

    testWidgets('build drops the tracking that would break Arabic joins', (
      tester,
    ) async {
      final harness = HomeHarness();
      await pumpScreen(tester, harness.screen(), locale: _ar);
      await tester.pumpAndSettle();

      final kicker = tester.widget<Text>(
        find.text((await _copy(_ar)).homeCurrentLocation.toUpperCase()),
      );
      expect(kicker.style!.letterSpacing, 0);
    });
  });
}
