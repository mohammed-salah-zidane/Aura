import 'package:aura_core/aura_core.dart';
import 'package:aura_design/aura_design.dart';
import 'package:aura_domain/aura_domain.dart';
import 'package:aura_feature_details/aura_feature_details.dart';
import 'package:aura_l10n/aura_l10n.dart';
import 'package:aura_providers/aura_providers.dart';
import 'package:aura_test_kit/aura_test_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

const Locale _ar = Locale('ar');

Future<AppLocalizations> _copy([Locale locale = const Locale('en')]) =>
    AppLocalizations.delegate.load(locale);

final class _Harness {
  _Harness({WeatherSnapshot? snapshot, AppFailure? failure})
    : repository = FakeWeatherRepository(
        snapshot: snapshot,
        failure: failure,
      ) {
    container = ProviderContainer(
      overrides: <Override>[
        clockProvider.overrideWithValue(FixedClock(fixtureNow)),
        weatherRepositoryProvider.overrideWithValue(repository),
        settingsPortProvider.overrideWithValue(FakeSettings()),
        savedCitiesPortProvider.overrideWithValue(FakeSavedCities()),
      ],
    );
    addTearDown(container.dispose);
  }

  final FakeWeatherRepository repository;
  late final ProviderContainer container;

  Widget host(Widget screen) =>
      UncontrolledProviderScope(container: container, child: screen);
}

Future<void> _pump(WidgetTester tester, Widget screen, {Locale? locale}) async {
  await pumpScreen(
    tester,
    screen,
    locale: locale ?? const Locale('en'),
    size: const Size(393, 1600),
  );
  await tester.pumpAndSettle();
}

/// A reading whose overall category shares its name with no pollutant band.
///
/// Category 3 is the only one of the six whose words appear nowhere in the
/// European band names, so counting band chips on the screen counts chips.
WeatherSnapshot _distinctAir() => weatherFixture(
  airQuality: const AirQuality(
    usEpaIndex: 3,
    concentrations: <Pollutant, double>{
      Pollutant.pm25: 8.2,
      Pollutant.pm10: 14,
      Pollutant.o3: 68,
      Pollutant.no2: 12,
      Pollutant.so2: 4,
      Pollutant.co: 210,
    },
  ),
);

void main() {
  setUpAll(loadAuraFonts);

  group('DetailsViewModel', () {
    test('build carries the reading, the units and the clock', () async {
      final harness = _Harness();
      final state = await harness.container.read(
        detailsViewModelProvider.future,
      );

      expect(state.valueOrNull?.snapshot.placeName, 'Cairo');
      expect(state.valueOrNull?.now, fixtureNow);
    });

    test('build reports the failure rather than inventing a reading', () async {
      final harness = _Harness(failure: const ServerError());
      final state = await harness.container.read(
        detailsViewModelProvider.future,
      );

      expect(state.failureOrNull, const ServerError());
    });
  });

  group('ForecastScreen', () {
    testWidgets('build lists every day the free tier returns', (tester) async {
      final harness = _Harness();
      await _pump(tester, harness.host(ForecastScreen(onBack: () {})));
      final l10n = await _copy();

      expect(find.byType(AuraForecastRow), findsNWidgets(3));
      expect(find.text(l10n.dayToday), findsOneWidget);
      expect(find.text(l10n.forecastTitle), findsOneWidget);
    });

    testWidgets('build says why there are three days and not ten', (
      tester,
    ) async {
      final harness = _Harness();
      await _pump(tester, harness.host(ForecastScreen(onBack: () {})));

      expect(find.text((await _copy()).forecastTierNote), findsOneWidget);
    });

    testWidgets('build shows a rain chance only when there is one', (
      tester,
    ) async {
      // The fixture's third day is the only one with a chance above zero.
      final harness = _Harness();
      await _pump(tester, harness.host(ForecastScreen(onBack: () {})));

      expect(find.text('10%'), findsOneWidget);
      expect(find.text('0%'), findsNothing);
    });

    testWidgets('build follows the live condition rather than a fixed sky', (
      tester,
    ) async {
      final harness = _Harness(
        snapshot: weatherFixture(condition: AuraCondition.rain),
      );
      await _pump(tester, harness.host(ForecastScreen(onBack: () {})));

      expect(
        tester.widget<AuraSky>(find.byType(AuraSky)).kind,
        AuraSkyKind.rain,
      );
    });

    testWidgets('build goes back when asked', (tester) async {
      var back = 0;
      final harness = _Harness();
      await _pump(tester, harness.host(ForecastScreen(onBack: () => back++)));

      await tester.tap(find.byType(AuraCircleButton));
      await tester.pump();
      expect(back, 1);
    });
  });

  group('AirQualityScreen', () {
    testWidgets('build shows the published category and where it sits', (
      tester,
    ) async {
      // Index 2 rather than 1, so the category on the hero cannot be confused
      // with the per-pollutant band of the same name.
      final harness = _Harness(snapshot: _distinctAir());
      await _pump(tester, harness.host(AirQualityScreen(onBack: () {})));
      final l10n = await _copy();

      expect(
        find.text(l10n.epaUnhealthyForSensitiveGroups),
        findsOneWidget,
      );
      expect(find.text(l10n.airQualityIndexName), findsOneWidget);
      expect(find.text(l10n.airQualityLevel('3')), findsOneWidget);
      expect(find.byType(AuraIndexScaleBar), findsOneWidget);
    });

    testWidgets('build lists every pollutant the service reported', (
      tester,
    ) async {
      final harness = _Harness();
      await _pump(tester, harness.host(AirQualityScreen(onBack: () {})));
      final l10n = await _copy();

      for (final name in <String>[
        l10n.pollutantPm25,
        l10n.pollutantPm10,
        l10n.pollutantOzone,
        l10n.pollutantNo2,
        l10n.pollutantSo2,
        l10n.pollutantCo,
      ]) {
        expect(find.text(name), findsOneWidget);
      }
    });

    testWidgets('build gives carbon monoxide no band, none being published', (
      tester,
    ) async {
      final harness = _Harness(snapshot: _distinctAir());
      await _pump(tester, harness.host(AirQualityScreen(onBack: () {})));
      final l10n = await _copy();

      // Five of the six pollutants are banded; the sixth has no published
      // scale in µg/m³, so it shows a reading and nothing else.
      final banded =
          <String>[
                l10n.airBandGood,
                l10n.airBandFair,
                l10n.airBandModerate,
                l10n.airBandPoor,
                l10n.airBandVeryPoor,
                l10n.airBandExtremelyPoor,
              ]
              .map((band) => find.text(band).evaluate().length)
              .reduce(
                (a, b) => a + b,
              );
      expect(banded, 5);
    });
  });

  group('WeatherAlertScreen', () {
    testWidgets('build shows the notice in the issuer own words', (
      tester,
    ) async {
      final alert = alertFixture();
      final harness = _Harness(
        snapshot: weatherFixture(alerts: <WeatherAlert>[alert]),
      );
      await _pump(tester, harness.host(WeatherAlertScreen(onBack: () {})));

      expect(find.text(alert.event), findsOneWidget);
      expect(find.text(alert.headline), findsOneWidget);
      expect(find.text(alert.description), findsOneWidget);
    });

    testWidgets('build splits the instruction where the issuer broke it', (
      tester,
    ) async {
      final harness = _Harness(
        snapshot: weatherFixture(alerts: <WeatherAlert>[alertFixture()]),
      );
      await _pump(tester, harness.host(WeatherAlertScreen(onBack: () {})));

      expect(find.byIcon(AuraIcons.success), findsNWidgets(2));
    });

    testWidgets('build lists the areas the notice covers', (tester) async {
      final harness = _Harness(
        snapshot: weatherFixture(alerts: <WeatherAlert>[alertFixture()]),
      );
      await _pump(tester, harness.host(WeatherAlertScreen(onBack: () {})));

      expect(find.text('Cairo'), findsOneWidget);
      expect(find.text('Giza'), findsOneWidget);
    });

    testWidgets('build says so when no alert is in effect', (tester) async {
      final harness = _Harness();
      await _pump(tester, harness.host(WeatherAlertScreen(onBack: () {})));

      expect(find.text((await _copy()).alertNone), findsOneWidget);
    });
  });

  group('SunAndMoonScreen', () {
    testWidgets('build draws the arc, the times and the phase', (tester) async {
      final harness = _Harness();
      await _pump(tester, harness.host(SunAndMoonScreen(onBack: () {})));
      final l10n = await _copy();

      expect(find.byType(AuraSunPath), findsOneWidget);
      expect(find.byType(AuraMoonPhase), findsOneWidget);
      expect(find.text('05:14'), findsOneWidget);
      expect(find.text('19:02'), findsOneWidget);
      expect(find.text(l10n.astroDaylight('13', '48')), findsOneWidget);
      expect(find.text(l10n.moonWaxingCrescent), findsOneWidget);
    });

    testWidgets('build says there is no sunrise where there is none', (
      tester,
    ) async {
      // A polar day is a real reading, not a parse failure.
      final harness = _Harness(snapshot: weatherFixture(hasSunTimes: false));
      await _pump(tester, harness.host(SunAndMoonScreen(onBack: () {})));
      final l10n = await _copy();

      expect(find.text(l10n.astroNoSunrise), findsOneWidget);
      expect(find.text(l10n.astroNoSunset), findsOneWidget);
    });
  });

  group('in Arabic', () {
    // One test per screen: a loop would dispose a container mid-test and leave
    // Riverpod's own dispose timer pending when the binding checks.
    for (final entry in <String, Widget Function()>{
      'forecast': () => ForecastScreen(onBack: () {}),
      'air quality': () => AirQualityScreen(onBack: () {}),
      'weather alert': () => WeatherAlertScreen(onBack: () {}),
      'sun and moon': () => SunAndMoonScreen(onBack: () {}),
    }.entries) {
      testWidgets('build ${entry.key} renders without overflowing', (
        tester,
      ) async {
        final harness = _Harness(
          snapshot: weatherFixture(alerts: <WeatherAlert>[alertFixture()]),
        );
        await _pump(tester, harness.host(entry.value()), locale: _ar);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
