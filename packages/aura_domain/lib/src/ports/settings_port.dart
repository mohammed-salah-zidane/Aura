import 'package:aura_core/aura_core.dart';
import 'package:aura_domain/src/entities/unit_preferences.dart';

/// Which notifications the user has switched on.
class NotificationPreferences {
  /// Creates a set of notification preferences.
  const NotificationPreferences({
    this.dailyForecast = false,
    this.severeAlerts = false,
    this.precipitationStart = false,
  });

  /// A forecast each morning.
  final bool dailyForecast;

  /// A push when a severe alert is issued.
  final bool severeAlerts;

  /// A push when rain or snow is about to start.
  final bool precipitationStart;

  /// A copy with the named fields replaced.
  NotificationPreferences copyWith({
    bool? dailyForecast,
    bool? severeAlerts,
    bool? precipitationStart,
  }) => NotificationPreferences(
    dailyForecast: dailyForecast ?? this.dailyForecast,
    severeAlerts: severeAlerts ?? this.severeAlerts,
    precipitationStart: precipitationStart ?? this.precipitationStart,
  );
}

/// Where the user's choices are kept.
abstract interface class SettingsPort {
  /// The stored units, or the defaults when nothing has been chosen.
  Future<Result<UnitPreferences, AppFailure>> readUnits();

  /// Stores [preferences].
  Future<Result<void, AppFailure>> writeUnits(UnitPreferences preferences);

  /// The stored notification choices, or the defaults.
  Future<Result<NotificationPreferences, AppFailure>> readNotifications();

  /// Stores [preferences].
  Future<Result<void, AppFailure>> writeNotifications(
    NotificationPreferences preferences,
  );
}
