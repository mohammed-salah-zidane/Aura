import 'package:aura_core/aura_core.dart';
import 'package:aura_domain/aura_domain.dart';
import 'package:aura_providers/aura_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';

/// What the settings screen shows.
@immutable
final class SettingsUiState {
  /// Creates a settings state.
  const SettingsUiState({
    required this.units,
    required this.notifications,
    required this.placeName,
  });

  /// The units every reading in the app is drawn in.
  final UnitPreferences units;

  /// Which notifications are switched on.
  final NotificationPreferences notifications;

  /// The place the daily notification will be about.
  final String placeName;
}

/// The settings screen's state.
final settingsViewModelProvider =
    AsyncNotifierProvider<SettingsViewModel, SettingsUiState>(
      SettingsViewModel.new,
      isAutoDispose: true,
    );

/// Reads the stored choices, and applies each one as it is made.
///
/// Units are app-wide state, so writing one here changes every screen at once
/// rather than this one telling the others.
final class SettingsViewModel extends AsyncNotifier<SettingsUiState> {
  /// When the daily forecast is delivered, in the place's own local time.
  ///
  /// A forecast is worth having before the day starts, and the design offers
  /// no control over the hour, so the app picks one rather than asking.
  static const int _dailyForecastHour = 7;

  @override
  Future<SettingsUiState> build() async {
    final units = await ref.watch(unitPreferencesProvider.future);
    final notifications = await ref.watch(
      notificationPreferencesProvider.future,
    );
    final feed = await ref.watch(weatherFeedProvider.future);

    return SettingsUiState(
      units: units,
      notifications: notifications,
      placeName: feed.valueOrNull?.snapshot.placeName ?? '',
    );
  }

  /// Changes the temperature scale everywhere.
  Future<void> selectTemperature(TemperatureUnit unit) =>
      _select((units) => units.copyWith(temperature: unit));

  /// Changes the wind speed unit everywhere.
  Future<void> selectSpeed(SpeedUnit unit) =>
      _select((units) => units.copyWith(speed: unit));

  /// Changes the precipitation unit everywhere.
  Future<void> selectPrecipitation(PrecipitationUnit unit) =>
      _select((units) => units.copyWith(precipitation: unit));

  Future<void> _select(UnitPreferences Function(UnitPreferences) change) async {
    final current = await ref.read(unitPreferencesProvider.future);
    await ref.read(unitPreferencesProvider.notifier).select(change(current));
  }

  /// Switches the daily forecast on or off, and schedules it either way.
  ///
  /// Permission is asked for at the moment the user asks for a notification,
  /// which is the only moment they have any context for the prompt. Refusing
  /// leaves the switch off rather than on and silent.
  Future<void> setDailyForecast({
    required bool enabled,
    required String title,
    required String body,
  }) async {
    if (enabled && !await _permitted()) return;

    await _store((preferences) => preferences.copyWith(dailyForecast: enabled));
    await ref
        .read(notificationPortProvider)
        .scheduleDailyForecast(
          hour: enabled ? _dailyForecastHour : null,
          title: title,
          body: body,
        );
  }

  /// Switches the severe alert notification on or off.
  Future<void> setSevereAlerts({required bool enabled}) async {
    if (enabled && !await _permitted()) return;
    await _store((preferences) => preferences.copyWith(severeAlerts: enabled));
  }

  /// Switches the precipitation notification on or off.
  Future<void> setPrecipitationStart({required bool enabled}) async {
    if (enabled && !await _permitted()) return;
    await _store(
      (preferences) => preferences.copyWith(precipitationStart: enabled),
    );
  }

  Future<bool> _permitted() =>
      ref.read(notificationPortProvider).requestPermission();

  Future<void> _store(
    NotificationPreferences Function(NotificationPreferences) change,
  ) async {
    final current = await ref.read(notificationPreferencesProvider.future);
    await ref
        .read(notificationPreferencesProvider.notifier)
        .select(change(current));
  }
}
