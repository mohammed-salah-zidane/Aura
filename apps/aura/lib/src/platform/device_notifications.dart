import 'package:aura_core/aura_core.dart';
import 'package:aura_domain/aura_domain.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Posts and schedules notifications through the platform.
///
/// Two are used: a daily forecast the user can switch on, and a severe alert
/// posted as soon as one arrives with the reading.
final class DeviceNotifications implements NotificationPort {
  /// Creates the adapter over an already-constructed plugin.
  DeviceNotifications(this._plugin, this._clock);

  final FlutterLocalNotificationsPlugin _plugin;
  final Clock _clock;

  /// Identifies the one repeating daily notification, so scheduling again
  /// replaces it rather than stacking a second.
  static const int _dailyForecastId = 1;

  /// Alerts are posted under their own identifier so a second alert does not
  /// overwrite the first.
  static const int _alertIdBase = 100;

  static const String _dailyChannelId = 'aura.daily_forecast';
  static const String _alertChannelId = 'aura.severe_alerts';

  bool _ready = false;

  /// Loads the timezone database and registers the platform channels.
  ///
  /// Scheduling needs a real zone rather than a UTC offset, because an offset
  /// is wrong for half the year anywhere that changes its clocks.
  Future<void> initialize() async {
    if (_ready) return;
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation(await _localZoneName()));
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          // Permission is asked for when the user switches a notification on,
          // not on the first launch, so a cold start never opens with a prompt
          // the user has no context for.
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    _ready = true;
  }

  @override
  Future<bool> requestPermission() async {
    await initialize();
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final granted = await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return granted ?? false;
    }
    final granted = await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    return granted ?? false;
  }

  @override
  Future<Result<void, AppFailure>> scheduleDailyForecast({
    required int? hour,
    required String title,
    required String body,
  }) async {
    try {
      await initialize();
      await _plugin.cancel(id: _dailyForecastId);
      if (hour == null) return const Ok<void, AppFailure>(null);

      await _plugin.zonedSchedule(
        id: _dailyForecastId,
        title: title,
        body: body,
        scheduledDate: _nextOccurrenceOf(hour),
        notificationDetails: _details(
          channelId: _dailyChannelId,
          channelName: title,
          importance: Importance.defaultImportance,
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        // Repeats every day at the same wall-clock time.
        matchDateTimeComponents: DateTimeComponents.time,
      );
      return const Ok<void, AppFailure>(null);
    } on Object catch (error) {
      return Err<void, AppFailure>(Unknown(cause: error));
    }
  }

  @override
  Future<Result<void, AppFailure>> showAlert(WeatherAlert alert) async {
    try {
      await initialize();
      await _plugin.show(
        // Two alerts for the same event replace each other; two different
        // events sit side by side.
        id: _alertIdBase + (alert.event.hashCode & 0xFFFF),
        title: alert.event,
        body: alert.description,
        notificationDetails: _details(
          channelId: _alertChannelId,
          channelName: alert.event,
          importance: Importance.high,
        ),
      );
      return const Ok<void, AppFailure>(null);
    } on Object catch (error) {
      return Err<void, AppFailure>(Unknown(cause: error));
    }
  }

  @override
  Future<Result<void, AppFailure>> cancelAll() async {
    try {
      await initialize();
      await _plugin.cancelAll();
      return const Ok<void, AppFailure>(null);
    } on Object catch (error) {
      return Err<void, AppFailure>(Unknown(cause: error));
    }
  }

  NotificationDetails _details({
    required String channelId,
    required String channelName,
    required Importance importance,
  }) => NotificationDetails(
    android: AndroidNotificationDetails(
      channelId,
      channelName,
      importance: importance,
    ),
    iOS: const DarwinNotificationDetails(),
  );

  /// The next time the clock reads [hour], today if it has not passed yet.
  tz.TZDateTime _nextOccurrenceOf(int hour) {
    final now = tz.TZDateTime.from(_clock.now(), tz.local);
    final today = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour);
    return today.isAfter(now) ? today : today.add(const Duration(days: 1));
  }

  Future<String> _localZoneName() async =>
      (await FlutterTimezone.getLocalTimezone()).identifier;
}
