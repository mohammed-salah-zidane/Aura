import 'package:aura_core/aura_core.dart';
import 'package:aura_design/aura_design.dart';
import 'package:aura_domain/aura_domain.dart';
import 'package:aura_feature_settings/aura_feature_settings.dart';
import 'package:aura_l10n/aura_l10n.dart';
import 'package:aura_providers/aura_providers.dart';
import 'package:aura_test_kit/aura_test_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

Future<AppLocalizations> _copy([Locale locale = const Locale('en')]) =>
    AppLocalizations.delegate.load(locale);

final class _Harness {
  _Harness({bool notificationsPermitted = true})
    : notifications = FakeNotifications(permitted: notificationsPermitted),
      settings = FakeSettings() {
    container = ProviderContainer(
      overrides: <Override>[
        clockProvider.overrideWithValue(FixedClock(fixtureNow)),
        weatherRepositoryProvider.overrideWithValue(FakeWeatherRepository()),
        settingsPortProvider.overrideWithValue(settings),
        savedCitiesPortProvider.overrideWithValue(FakeSavedCities()),
        notificationPortProvider.overrideWithValue(notifications),
      ],
    );
    addTearDown(container.dispose);
  }

  final FakeNotifications notifications;
  final FakeSettings settings;
  late final ProviderContainer container;

  SettingsViewModel get viewModel =>
      container.read(settingsViewModelProvider.notifier);

  Widget screen({VoidCallback? onDone}) => UncontrolledProviderScope(
    container: container,
    child: SettingsScreen(onDone: onDone ?? () {}, version: '1.0.0'),
  );
}

void main() {
  setUpAll(loadAuraFonts);

  group('SettingsViewModel', () {
    test('build reads the stored units and notification choices', () async {
      final harness = _Harness()
        ..settings.units = const UnitPreferences(
          speed: SpeedUnit.milesPerHour,
        );

      final state = await harness.container.read(
        settingsViewModelProvider.future,
      );
      expect(state.units.speed, SpeedUnit.milesPerHour);
    });

    test('selectTemperature stores the choice', () async {
      final harness = _Harness();
      await harness.container.read(settingsViewModelProvider.future);

      await harness.viewModel.selectTemperature(TemperatureUnit.fahrenheit);

      expect(harness.settings.units.temperature, TemperatureUnit.fahrenheit);
    });

    test('selectTemperature changes the units every screen reads', () async {
      final harness = _Harness();
      await harness.container.read(settingsViewModelProvider.future);

      await harness.viewModel.selectTemperature(TemperatureUnit.fahrenheit);

      final shared = await harness.container.read(
        unitPreferencesProvider.future,
      );
      expect(shared.temperature, TemperatureUnit.fahrenheit);
    });

    test(
      'setDailyForecast schedules the notification when switched on',
      () async {
        final harness = _Harness();
        await harness.container.read(settingsViewModelProvider.future);

        await harness.viewModel.setDailyForecast(
          enabled: true,
          title: 'Today in Cairo',
          body: 'Open Aura for today.',
        );

        expect(harness.notifications.scheduledHour, isNotNull);
        expect(harness.settings.notifications.dailyForecast, isTrue);
      },
    );

    test('setDailyForecast cancels the schedule when switched off', () async {
      final harness = _Harness();
      await harness.container.read(settingsViewModelProvider.future);
      await harness.viewModel.setDailyForecast(
        enabled: true,
        title: 'Today in Cairo',
        body: 'Open Aura for today.',
      );

      await harness.viewModel.setDailyForecast(
        enabled: false,
        title: 'Today in Cairo',
        body: 'Open Aura for today.',
      );

      expect(harness.notifications.scheduledHour, isNull);
      expect(harness.settings.notifications.dailyForecast, isFalse);
    });

    test(
      'setDailyForecast a refused permission leaves the switch off',
      () async {
        // A switch that reads on while nothing is ever delivered is worse than
        // one that stayed off.
        final harness = _Harness(notificationsPermitted: false);
        await harness.container.read(settingsViewModelProvider.future);

        await harness.viewModel.setDailyForecast(
          enabled: true,
          title: 'Today in Cairo',
          body: 'Open Aura for today.',
        );

        expect(harness.settings.notifications.dailyForecast, isFalse);
        expect(harness.notifications.scheduledHour, isNull);
      },
    );

    test('setSevereAlerts stores the choice', () async {
      final harness = _Harness();
      await harness.container.read(settingsViewModelProvider.future);

      await harness.viewModel.setSevereAlerts(enabled: true);

      expect(harness.settings.notifications.severeAlerts, isTrue);
    });
  });

  group('SettingsScreen', () {
    testWidgets('build shows every group the design draws', (tester) async {
      final harness = _Harness();
      await pumpScreen(tester, harness.screen());
      await tester.pumpAndSettle();
      final l10n = await _copy();

      for (final heading in <String>[
        l10n.settingsUnits,
        l10n.settingsNotificationsSection,
        l10n.settingsGeneral,
        l10n.settingsAbout,
      ]) {
        expect(find.text(heading.toUpperCase()), findsOneWidget);
      }
    });

    testWidgets('build reports the units in force', (tester) async {
      final harness = _Harness();
      await pumpScreen(tester, harness.screen());
      await tester.pumpAndSettle();
      final l10n = await _copy();

      expect(find.text(l10n.unitCelsius), findsOneWidget);
      expect(find.text(l10n.unitSpeedKilometersPerHour), findsOneWidget);
      expect(find.text(l10n.unitMillimetres), findsOneWidget);
    });

    testWidgets('build a unit row opens a picker and applies the choice', (
      tester,
    ) async {
      final harness = _Harness();
      await pumpScreen(tester, harness.screen(), withNavigator: true);
      await tester.pumpAndSettle();
      final l10n = await _copy();

      await tester.tap(find.text(l10n.settingsTemperature));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.unitFahrenheit));
      await tester.pumpAndSettle();

      expect(harness.settings.units.temperature, TemperatureUnit.fahrenheit);
    });

    testWidgets('build a notification switch asks the platform first', (
      tester,
    ) async {
      final harness = _Harness();
      await pumpScreen(tester, harness.screen());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(AuraToggle).first);
      await tester.pumpAndSettle();

      expect(harness.notifications.scheduledHour, isNotNull);
    });

    testWidgets('build reports the build the user is running', (tester) async {
      final harness = _Harness();
      await pumpScreen(tester, harness.screen());
      await tester.pumpAndSettle();

      expect(find.text('1.0.0'), findsOneWidget);
    });

    testWidgets('build names the weather service, as the free tier requires', (
      tester,
    ) async {
      final harness = _Harness();
      await pumpScreen(tester, harness.screen());
      await tester.pumpAndSettle();

      expect(
        find.text((await _copy()).settingsDataSourceValue),
        findsOneWidget,
      );
    });

    testWidgets('build closes when the back button is tapped', (tester) async {
      var done = 0;
      final harness = _Harness();
      await pumpScreen(tester, harness.screen(onDone: () => done++));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(AuraIcons.chevronLeft));
      await tester.pump();

      expect(done, 1);
    });

    testWidgets('build renders the Arabic screen without overflowing', (
      tester,
    ) async {
      final harness = _Harness();
      await pumpScreen(tester, harness.screen(), locale: const Locale('ar'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
