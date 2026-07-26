import 'package:aura_weather_api/src/dto/air_quality_dto.dart';
import 'package:aura_weather_api/src/dto/condition_dto.dart';
import 'package:json_annotation/json_annotation.dart';

part 'current_dto.g.dart';

/// The reading for right now.
///
/// Mirrors the wire shape field for field, including the imperial duplicates.
/// Deciding which of a pair to use belongs to the mapper, not here.
@JsonSerializable()
class CurrentDto {
  /// Creates a current reading.
  const CurrentDto({
    required this.lastUpdatedEpoch,
    required this.lastUpdated,
    required this.tempC,
    required this.tempF,
    required this.isDay,
    required this.condition,
    required this.windMph,
    required this.windKph,
    required this.windDegree,
    required this.windDir,
    required this.pressureMb,
    required this.pressureIn,
    required this.precipMm,
    required this.precipIn,
    required this.humidity,
    required this.cloud,
    required this.feelslikeC,
    required this.feelslikeF,
    required this.windchillC,
    required this.windchillF,
    required this.heatindexC,
    required this.heatindexF,
    required this.dewpointC,
    required this.dewpointF,
    required this.visKm,
    required this.visMiles,
    required this.uv,
    required this.gustMph,
    required this.gustKph,
    required this.willItRain,
    required this.chanceOfRain,
    required this.willItSnow,
    required this.chanceOfSnow,
    required this.wetbulbC,
    required this.wetbulbF,
    this.airQuality,
  });

  /// Decodes a current reading from its JSON form.
  factory CurrentDto.fromJson(Map<String, dynamic> json) =>
      _$CurrentDtoFromJson(json);

  /// When the reading was taken, as a Unix timestamp.
  final int lastUpdatedEpoch;

  /// When the reading was taken, as local `yyyy-MM-dd HH:mm`.
  final String lastUpdated;

  /// Air temperature in Celsius.
  final double tempC;

  /// Air temperature in Fahrenheit.
  final double tempF;

  /// 1 during daylight, 0 at night. Drives the day and night condition icons.
  final int isDay;

  /// The condition right now.
  final ConditionDto condition;

  /// Wind speed in miles per hour.
  final double windMph;

  /// Wind speed in kilometres per hour.
  final double windKph;

  /// Wind bearing in degrees.
  final int windDegree;

  /// Wind direction as a compass abbreviation, for example `NNW`.
  final String windDir;

  /// Pressure in millibars.
  final double pressureMb;

  /// Pressure in inches of mercury. Rendered as the pressure sub-line.
  final double pressureIn;

  /// Precipitation in millimetres.
  final double precipMm;

  /// Precipitation in inches.
  final double precipIn;

  /// Relative humidity as a percentage.
  final int humidity;

  /// Cloud cover as a percentage.
  final int cloud;

  /// Apparent temperature in Celsius.
  final double feelslikeC;

  /// Apparent temperature in Fahrenheit.
  final double feelslikeF;

  /// Wind chill in Celsius.
  final double windchillC;

  /// Wind chill in Fahrenheit.
  final double windchillF;

  /// Heat index in Celsius.
  final double heatindexC;

  /// Heat index in Fahrenheit.
  final double heatindexF;

  /// Dew point in Celsius. Rendered as the humidity sub-line.
  final double dewpointC;

  /// Dew point in Fahrenheit.
  final double dewpointF;

  /// Visibility in kilometres.
  final double visKm;

  /// Visibility in miles.
  final double visMiles;

  /// UV index. Banded against the WHO scale for display.
  final double uv;

  /// Gust speed in miles per hour.
  final double gustMph;

  /// Gust speed in kilometres per hour. Rendered as the wind sub-line.
  final double gustKph;

  /// 1 when rain is expected.
  final int willItRain;

  /// Chance of rain as a percentage.
  final int chanceOfRain;

  /// 1 when snow is expected.
  final int willItSnow;

  /// Chance of snow as a percentage.
  final int chanceOfSnow;

  /// Wet bulb temperature in Celsius.
  final double wetbulbC;

  /// Wet bulb temperature in Fahrenheit.
  final double wetbulbF;

  /// Air quality, present only when the request asked for it.
  final AirQualityDto? airQuality;

  /// Encodes this reading back to its JSON form.
  Map<String, dynamic> toJson() => _$CurrentDtoToJson(this);
}
