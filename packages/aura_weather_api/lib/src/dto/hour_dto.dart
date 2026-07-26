import 'package:aura_weather_api/src/dto/condition_dto.dart';
import 'package:json_annotation/json_annotation.dart';

part 'hour_dto.g.dart';

/// One hour of a forecast day. Every day carries 24 of these.
@JsonSerializable()
class HourDto {
  /// Creates an hourly reading.
  const HourDto({
    required this.timeEpoch,
    required this.time,
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
    required this.snowCm,
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
    required this.willItRain,
    required this.chanceOfRain,
    required this.willItSnow,
    required this.chanceOfSnow,
    required this.visKm,
    required this.visMiles,
    required this.gustMph,
    required this.gustKph,
    required this.uv,
    required this.wetbulbC,
    required this.wetbulbF,
  });

  /// Decodes an hourly reading from its JSON form.
  factory HourDto.fromJson(Map<String, dynamic> json) =>
      _$HourDtoFromJson(json);

  /// The hour as a Unix timestamp.
  final int timeEpoch;

  /// The hour as local `yyyy-MM-dd HH:mm`.
  final String time;

  /// Air temperature in Celsius.
  final double tempC;

  /// Air temperature in Fahrenheit.
  final double tempF;

  /// 1 during daylight, 0 at night.
  final int isDay;

  /// The condition for this hour.
  final ConditionDto condition;

  /// Wind speed in miles per hour.
  final double windMph;

  /// Wind speed in kilometres per hour.
  final double windKph;

  /// Wind bearing in degrees.
  final int windDegree;

  /// Wind direction as a compass abbreviation.
  final String windDir;

  /// Pressure in millibars.
  final double pressureMb;

  /// Pressure in inches of mercury.
  final double pressureIn;

  /// Precipitation in millimetres.
  final double precipMm;

  /// Precipitation in inches.
  final double precipIn;

  /// Snowfall in centimetres.
  final double snowCm;

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

  /// Dew point in Celsius.
  final double dewpointC;

  /// Dew point in Fahrenheit.
  final double dewpointF;

  /// 1 when rain is expected in this hour.
  final int willItRain;

  /// Chance of rain as a percentage.
  final int chanceOfRain;

  /// 1 when snow is expected in this hour.
  final int willItSnow;

  /// Chance of snow as a percentage.
  final int chanceOfSnow;

  /// Visibility in kilometres.
  final double visKm;

  /// Visibility in miles.
  final double visMiles;

  /// Gust speed in miles per hour.
  final double gustMph;

  /// Gust speed in kilometres per hour.
  final double gustKph;

  /// UV index. Arrives as a bare integer overnight, so it is read as a number.
  final double uv;

  /// Wet bulb temperature in Celsius.
  final double wetbulbC;

  /// Wet bulb temperature in Fahrenheit.
  final double wetbulbF;

  /// Encodes this reading back to its JSON form.
  Map<String, dynamic> toJson() => _$HourDtoToJson(this);
}
