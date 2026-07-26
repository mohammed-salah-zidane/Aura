import 'package:aura_core/aura_core.dart';
import 'package:aura_domain/src/derived/aura_condition.dart';
import 'package:aura_domain/src/entities/astro_info.dart';
import 'package:aura_domain/src/entities/hourly_point.dart';
import 'package:meta/meta.dart';

/// One day of the forecast.
@immutable
final class ForecastDay {
  /// Creates a forecast day.
  const ForecastDay({
    required this.date,
    required this.low,
    required this.high,
    required this.condition,
    required this.conditionText,
    required this.chanceOfRainPercent,
    required this.uvIndex,
    required this.astro,
    required this.hours,
  });

  /// The local date this day describes.
  final DateTime date;

  /// The day's lowest temperature.
  final Temperature low;

  /// The day's highest temperature.
  final Temperature high;

  /// The condition that represents the day.
  final AuraCondition condition;

  /// The condition in words, from the service.
  final String conditionText;

  /// Chance of rain across the day, 0 to 100.
  final int chanceOfRainPercent;

  /// The day's highest UV index.
  final double uvIndex;

  /// Sun and moon times for the day.
  final AstroInfo astro;

  /// The day's hours, in local order. Twenty-four of them.
  final List<HourlyPoint> hours;
}
