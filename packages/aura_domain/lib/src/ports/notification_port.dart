import 'package:aura_core/aura_core.dart';
import 'package:aura_domain/src/entities/weather_alert.dart';

/// Where notifications are scheduled.
abstract interface class NotificationPort {
  /// Asks the platform for permission. True when it was granted.
  Future<bool> requestPermission();

  /// Schedules a daily notification at [hour] local time, replacing any
  /// existing schedule. Passing null for [hour] cancels it.
  ///
  /// The copy is passed in rather than composed here. A port is a platform
  /// capability, and what the notification says is the app's own copy in the
  /// user's own locale, which only a caller with a `BuildContext` can read.
  Future<Result<void, AppFailure>> scheduleDailyForecast({
    required int? hour,
    required String title,
    required String body,
  });

  /// Shows [alert] now.
  Future<Result<void, AppFailure>> showAlert(WeatherAlert alert);

  /// Cancels everything this app has scheduled.
  Future<Result<void, AppFailure>> cancelAll();
}
