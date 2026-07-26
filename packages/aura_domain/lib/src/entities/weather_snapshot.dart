import 'package:aura_domain/src/entities/air_quality.dart';
import 'package:aura_domain/src/entities/current_conditions.dart';
import 'package:aura_domain/src/entities/forecast_day.dart';
import 'package:aura_domain/src/entities/weather_alert.dart';
import 'package:meta/meta.dart';

/// Everything one `forecast.json` call returns, as entities.
///
/// The home screen renders this and nothing else, which is the point of
/// asking for current, forecast, air quality and alerts in a single request.
@immutable
final class WeatherSnapshot {
  /// Creates a snapshot.
  const WeatherSnapshot({
    required this.placeName,
    required this.region,
    required this.country,
    required this.localTime,
    required this.current,
    required this.days,
    this.airQuality,
    this.alerts = const <WeatherAlert>[],
  });

  /// The place's name, for example `Cairo`.
  final String placeName;

  /// Its administrative region. Empty when the service gave none.
  final String region;

  /// Its country.
  final String country;

  /// The local time where the place is, which is not the device's time.
  final DateTime localTime;

  /// The reading for right now.
  final CurrentConditions current;

  /// The forecast days, soonest first. Three of them on the free tier.
  final List<ForecastDay> days;

  /// Air quality, or null when the request did not ask for it.
  final AirQuality? airQuality;

  /// Active alerts. Empty means none are active, not that none are supported.
  final List<WeatherAlert> alerts;

  /// Today, which is the first forecast day.
  ForecastDay get today => days.first;

  /// The most serious active alert, or null when there are none.
  ///
  /// The home screen has room for one banner, so when a service issues
  /// several it shows the worst rather than the first to arrive. Equal
  /// grades keep the issuer's own order.
  WeatherAlert? get headlineAlert {
    if (alerts.isEmpty) return null;
    return alerts.reduce(
      (worst, next) => next.severity.rank > worst.severity.rank ? next : worst,
    );
  }
}
