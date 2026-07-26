import 'package:aura_core/aura_core.dart';
import 'package:aura_domain/aura_domain.dart';
import 'package:aura_storage/aura_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  late PreferencesStore store;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    store = PreferencesStore(SharedPreferencesAsync());
  });

  group('units before anything is chosen', () {
    test('readUnits returns the defaults', () async {
      final units = (await store.readUnits()).valueOrNull;

      expect(units, const UnitPreferences());
      expect(units?.temperature, TemperatureUnit.celsius);
      expect(units?.speed, SpeedUnit.kilometersPerHour);
      expect(units?.precipitation, PrecipitationUnit.millimeters);
    });
  });

  group('units after a write', () {
    test('readUnits returns what was written', () async {
      const chosen = UnitPreferences(
        temperature: TemperatureUnit.fahrenheit,
        speed: SpeedUnit.milesPerHour,
        precipitation: PrecipitationUnit.inches,
      );

      expect((await store.writeUnits(chosen)).isOk, isTrue);

      expect((await store.readUnits()).valueOrNull, chosen);
    });

    test('writeUnits replaces rather than merges', () async {
      await store.writeUnits(
        const UnitPreferences(temperature: TemperatureUnit.fahrenheit),
      );
      await store.writeUnits(const UnitPreferences());

      expect((await store.readUnits()).valueOrNull, const UnitPreferences());
    });

    test('readUnits returns one changed unit without changing the '
        'others', () async {
      await store.writeUnits(
        const UnitPreferences(speed: SpeedUnit.milesPerHour),
      );

      final units = (await store.readUnits()).valueOrNull;

      expect(units?.speed, SpeedUnit.milesPerHour);
      expect(units?.temperature, TemperatureUnit.celsius);
      expect(units?.precipitation, PrecipitationUnit.millimeters);
    });
  });

  // A name this build does not know was written by one that spelled the enum
  // differently. The user loses a setting, not the screen.
  group('units stored by a build that spelled them differently', () {
    test('readUnits falls back to the default for a name it does not '
        'know', () async {
      final preferences = SharedPreferencesAsync();
      await preferences.setString('units.temperature', 'kelvin');

      final units = (await store.readUnits()).valueOrNull;

      expect(units?.temperature, TemperatureUnit.celsius);
    });

    test('readUnits keeps the units it can still read', () async {
      final preferences = SharedPreferencesAsync();
      await preferences.setString('units.temperature', 'kelvin');
      await preferences.setString('units.speed', 'milesPerHour');

      final units = (await store.readUnits()).valueOrNull;

      expect(units?.temperature, TemperatureUnit.celsius);
      expect(units?.speed, SpeedUnit.milesPerHour);
    });
  });

  group('notifications', () {
    test('readNotifications returns everything off before anything is '
        'chosen', () async {
      final chosen = (await store.readNotifications()).valueOrNull;

      expect(chosen?.dailyForecast, isFalse);
      expect(chosen?.severeAlerts, isFalse);
      expect(chosen?.precipitationStart, isFalse);
    });

    test('readNotifications returns what was written', () async {
      const chosen = NotificationPreferences(
        dailyForecast: true,
        severeAlerts: true,
      );

      expect((await store.writeNotifications(chosen)).isOk, isTrue);

      final read = (await store.readNotifications()).valueOrNull;
      expect(read?.dailyForecast, isTrue);
      expect(read?.severeAlerts, isTrue);
      expect(read?.precipitationStart, isFalse);
    });

    test('writeNotifications switches one back off', () async {
      await store.writeNotifications(
        const NotificationPreferences(dailyForecast: true, severeAlerts: true),
      );
      await store.writeNotifications(
        const NotificationPreferences(severeAlerts: true),
      );

      final read = (await store.readNotifications()).valueOrNull;
      expect(read?.dailyForecast, isFalse);
      expect(read?.severeAlerts, isTrue);
    });

    test('notifications and units do not overwrite each other', () async {
      await store.writeUnits(
        const UnitPreferences(temperature: TemperatureUnit.fahrenheit),
      );
      await store.writeNotifications(
        const NotificationPreferences(dailyForecast: true),
      );

      expect(
        (await store.readUnits()).valueOrNull?.temperature,
        TemperatureUnit.fahrenheit,
      );
      expect(
        (await store.readNotifications()).valueOrNull?.dailyForecast,
        isTrue,
      );
    });
  });

  group('when preferences are unreachable', () {
    setUp(() {
      // SharedPreferencesAsync captures the platform when it is constructed,
      // so the store has to be built after the platform is swapped.
      SharedPreferencesAsyncPlatform.instance = _FailingPreferences();
      store = PreferencesStore(SharedPreferencesAsync());
    });

    test('readUnits reports a failure rather than throwing', () async {
      expect((await store.readUnits()).failureOrNull, isA<Unknown>());
    });

    test('writeUnits reports a failure rather than throwing', () async {
      expect(
        (await store.writeUnits(const UnitPreferences())).failureOrNull,
        isA<Unknown>(),
      );
    });

    test('readNotifications reports a failure rather than throwing', () async {
      expect((await store.readNotifications()).failureOrNull, isA<Unknown>());
    });

    test('writeNotifications reports a failure rather than throwing', () async {
      expect(
        (await store.writeNotifications(
          const NotificationPreferences(),
        )).failureOrNull,
        isA<Unknown>(),
      );
    });
  });
}

/// Stands in for the platform refusing every call, which is what a revoked
/// container or a corrupt preferences file looks like from here.
base class _FailingPreferences extends InMemorySharedPreferencesAsync {
  _FailingPreferences() : super.empty();

  @override
  Future<String?> getString(String key, SharedPreferencesOptions options) =>
      Future<String?>.error(StateError('preferences are unreachable'));

  @override
  Future<bool?> getBool(String key, SharedPreferencesOptions options) =>
      Future<bool?>.error(StateError('preferences are unreachable'));

  @override
  Future<bool> setString(
    String key,
    String value,
    SharedPreferencesOptions options,
  ) => Future<bool>.error(StateError('preferences are unreachable'));

  @override
  Future<bool> setBool(
    String key,
    bool value,
    SharedPreferencesOptions options,
  ) => Future<bool>.error(StateError('preferences are unreachable'));
}
