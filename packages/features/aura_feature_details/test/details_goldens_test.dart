@Tags(<String>['golden'])
library;

import 'package:aura_core/aura_core.dart';
import 'package:aura_domain/aura_domain.dart';
import 'package:aura_feature_details/aura_feature_details.dart';
import 'package:aura_providers/aura_providers.dart';
import 'package:aura_test_kit/aura_test_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(loadAuraFonts);

  final screens = <String, Widget Function()>{
    'forecast': () => ForecastScreen(onBack: () {}),
    'air_quality': () => AirQualityScreen(onBack: () {}),
    'weather_alert': () => WeatherAlertScreen(onBack: () {}),
    'sun_and_moon': () => SunAndMoonScreen(onBack: () {}),
  };

  for (final entry in screens.entries) {
    for (final locale in const <Locale>[Locale('en'), Locale('ar')]) {
      testWidgets('${entry.key} ${locale.languageCode}', (tester) async {
        final container = ProviderContainer(
          overrides: <Override>[
            clockProvider.overrideWithValue(FixedClock(fixtureNow)),
            weatherRepositoryProvider.overrideWithValue(
              FakeWeatherRepository(
                snapshot: weatherFixture(
                  alerts: <WeatherAlert>[alertFixture()],
                ),
              ),
            ),
            settingsPortProvider.overrideWithValue(FakeSettings()),
            savedCitiesPortProvider.overrideWithValue(FakeSavedCities()),
          ],
        );
        addTearDown(container.dispose);

        await pumpScreen(
          tester,
          UncontrolledProviderScope(
            container: container,
            child: entry.value(),
          ),
          locale: locale,
          size: const Size(393, 1100),
        );
        await tester.pumpAndSettle();

        await expectLater(
          find.byType(Directionality).first,
          matchesGoldenFile(
            'goldens/${entry.key}_${locale.languageCode}.png',
          ),
        );
      });
    }
  }
}
