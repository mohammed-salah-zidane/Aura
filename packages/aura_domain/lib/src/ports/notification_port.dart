import 'package:aura_core/aura_core.dart';
import 'package:aura_domain/src/entities/weather_alert.dart';

/// Where notifications are scheduled.
abstract interface class NotificationPort {
  /// Asks the platform for permission. True when it was granted.
  Future<bool> requestPermission();

  /// Schedules a daily forecast at [hour] local time, replacing any existing
  /// schedule. Passing null cancels it.
  Future<Result<void, AppFailure>> scheduleDailyForecast({
    required int? hour,
    required String placeName,
  });

  /// Shows [alert] now.
  Future<Result<void, AppFailure>> showAlert(WeatherAlert alert);

  /// Cancels everything this app has scheduled.
  Future<Result<void, AppFailure>> cancelAll();
}
