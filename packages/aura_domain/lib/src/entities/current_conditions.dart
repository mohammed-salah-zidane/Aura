import 'package:aura_core/aura_core.dart';
import 'package:aura_domain/src/derived/aura_condition.dart';
import 'package:aura_domain/src/derived/uv_band.dart';
import 'package:meta/meta.dart';

/// The reading for right now.
///
/// Every field here is one WeatherAPI returns. There is no narrative summary
/// and no qualitative descriptor: where the design shows a sub-line, it shows
/// another real field.
@immutable
final class CurrentConditions {
  /// Creates a current reading.
  const CurrentConditions({
    required this.observedAt,
    required this.temperature,
    required this.feelsLike,
    required this.condition,
    required this.conditionText,
    required this.isDay,
    required this.windSpeed,
    required this.windDirection,
    required this.gustSpeed,
    required this.humidityPercent,
    required this.dewPoint,
    required this.pressure,
    required this.pressureInchesOfMercury,
    required this.visibility,
    required this.uvIndex,
    required this.cloudPercent,
  });

  /// When the service last updated this reading.
  final DateTime observedAt;

  /// Air temperature.
  final Temperature temperature;

  /// Apparent temperature.
  final Temperature feelsLike;

  /// The sky to paint.
  final AuraCondition condition;

  /// The condition in words, from `condition.text`. Already translated by the
  /// service when the request carried a `lang`, so it is never composed here.
  final String conditionText;

  /// Whether it is daylight where the reading was taken.
  final bool isDay;

  /// Wind speed.
  final Speed windSpeed;

  /// Wind direction as a compass abbreviation, for example `NNW`.
  final String windDirection;

  /// Gust speed.
  final Speed gustSpeed;

  /// Relative humidity, 0 to 100.
  final int humidityPercent;

  /// Dew point. The design shows this under humidity.
  final Temperature dewPoint;

  /// Atmospheric pressure.
  final Pressure pressure;

  /// Pressure as the service reports it in inches of mercury.
  ///
  /// Taken from `pressure_in` rather than converted, because converting from
  /// millibars rounds to a different last digit than the service publishes.
  final double pressureInchesOfMercury;

  /// Visibility.
  final Distance visibility;

  /// UV index.
  final double uvIndex;

  /// Cloud cover, 0 to 100.
  final int cloudPercent;

  /// The WHO band for [uvIndex].
  UvBand get uvSeverity => uvBand(uvIndex);
}
