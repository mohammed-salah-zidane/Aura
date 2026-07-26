@Tags(<String>['golden'])
library;

import 'package:aura_core/aura_core.dart';
import 'package:aura_feature_settings/aura_feature_settings.dart';
import 'package:aura_providers/aura_providers.dart';
import 'package:aura_test_kit/aura_test_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(loadAuraFonts);

  for (final locale in const <Locale>[Locale('en'), Locale('ar')]) {
    testWidgets('settings ${locale.languageCode}', (tester) async {
      final container = ProviderContainer(
        overrides: <Override>[
          clockProvider.overrideWithValue(FixedClock(fixtureNow)),
          weatherRepositoryProvider.overrideWithValue(FakeWeatherRepository()),
          settingsPortProvider.overrideWithValue(FakeSettings()),
          savedCitiesPortProvider.overrideWithValue(FakeSavedCities()),
          notificationPortProvider.overrideWithValue(FakeNotifications()),
        ],
      );
      addTearDown(container.dispose);

      await pumpScreen(
        tester,
        UncontrolledProviderScope(
          container: container,
          child: SettingsScreen(onDone: () {}, version: '1.0.0'),
        ),
        locale: locale,
        size: const Size(393, 1000),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(Directionality).first,
        matchesGoldenFile('goldens/settings_${locale.languageCode}.png'),
      );
    });
  }
}
