import 'package:aura_core/aura_core.dart';
import 'package:aura_domain/aura_domain.dart';
import 'package:aura_storage/src/guarded.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The user's choices, kept in platform preferences.
///
/// Not in the database on purpose. These are six scalars that the app reads at
/// startup and writes one at a time, and a table for them would cost a schema
/// migration every time a setting is added. The database holds documents; this
/// holds settings.
final class PreferencesStore implements SettingsPort {
  /// Creates the store over [_preferences].
  ///
  /// Tests pass an in-memory handle; the app uses [PreferencesStore.onDevice].
  const PreferencesStore(this._preferences);

  /// Opens the platform preferences the app ships with.
  PreferencesStore.onDevice() : _preferences = SharedPreferencesAsync();

  static const String _temperatureKey = 'units.temperature';
  static const String _speedKey = 'units.speed';
  static const String _precipitationKey = 'units.precipitation';
  static const String _dailyForecastKey = 'notifications.dailyForecast';
  static const String _severeAlertsKey = 'notifications.severeAlerts';
  static const String _precipitationStartKey =
      'notifications.precipitationStart';

  final SharedPreferencesAsync _preferences;

  @override
  Future<Result<UnitPreferences, AppFailure>> readUnits() => guarded(() async {
    const defaults = UnitPreferences();
    return UnitPreferences(
      temperature: _readEnum(
        await _preferences.getString(_temperatureKey),
        TemperatureUnit.values,
        defaults.temperature,
      ),
      speed: _readEnum(
        await _preferences.getString(_speedKey),
        SpeedUnit.values,
        defaults.speed,
      ),
      precipitation: _readEnum(
        await _preferences.getString(_precipitationKey),
        PrecipitationUnit.values,
        defaults.precipitation,
      ),
    );
  });

  @override
  Future<Result<void, AppFailure>> writeUnits(
    UnitPreferences preferences,
  ) => guarded<void>(() async {
    await _preferences.setString(
      _temperatureKey,
      preferences.temperature.name,
    );
    await _preferences.setString(_speedKey, preferences.speed.name);
    await _preferences.setString(
      _precipitationKey,
      preferences.precipitation.name,
    );
  });

  @override
  Future<Result<NotificationPreferences, AppFailure>> readNotifications() =>
      guarded(() async {
        const defaults = NotificationPreferences();
        return NotificationPreferences(
          dailyForecast:
              await _preferences.getBool(_dailyForecastKey) ??
              defaults.dailyForecast,
          severeAlerts:
              await _preferences.getBool(_severeAlertsKey) ??
              defaults.severeAlerts,
          precipitationStart:
              await _preferences.getBool(_precipitationStartKey) ??
              defaults.precipitationStart,
        );
      });

  @override
  Future<Result<void, AppFailure>> writeNotifications(
    NotificationPreferences preferences,
  ) => guarded<void>(() async {
    await _preferences.setBool(_dailyForecastKey, preferences.dailyForecast);
    await _preferences.setBool(_severeAlertsKey, preferences.severeAlerts);
    await _preferences.setBool(
      _precipitationStartKey,
      preferences.precipitationStart,
    );
  });

  /// Reads a stored enum name, falling back to [fallback].
  ///
  /// A name this build does not recognise was written by one that spelled the
  /// enum differently. Falling back beats throwing: the user loses a setting,
  /// not the screen.
  static T _readEnum<T extends Enum>(
    String? stored,
    List<T> values,
    T fallback,
  ) {
    if (stored == null) return fallback;
    for (final value in values) {
      if (value.name == stored) return value;
    }
    return fallback;
  }
}
