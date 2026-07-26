import 'package:aura_core/aura_core.dart';
import 'package:aura_domain/src/derived/aura_condition.dart';
import 'package:meta/meta.dart';

/// One hour of the forecast strip.
@immutable
final class HourlyPoint {
  /// Creates an hourly point.
  const HourlyPoint({
    required this.time,
    required this.temperature,
    required this.condition,
    required this.conditionText,
    required this.isDay,
    required this.chanceOfRainPercent,
  });

  /// The local hour this point describes.
  final DateTime time;

  /// Air temperature for the hour.
  final Temperature temperature;

  /// The condition for the hour.
  final AuraCondition condition;

  /// The condition in words, from the service.
  final String conditionText;

  /// Whether the hour falls in daylight.
  final bool isDay;

  /// Chance of rain, 0 to 100.
  final int chanceOfRainPercent;
}
