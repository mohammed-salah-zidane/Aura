import 'package:aura_weather_api/src/dto/condition_dto.dart';
import 'package:json_annotation/json_annotation.dart';

part 'day_dto.g.dart';

/// The daily summary inside a forecast day.
@JsonSerializable()
class DayDto {
  /// Creates a daily summary.
  const DayDto({
    required this.maxtempC,
    required this.maxtempF,
    required this.mintempC,
    required this.mintempF,
    required this.avgtempC,
    required this.avgtempF,
    required this.maxwindMph,
    required this.maxwindKph,
    required this.totalprecipMm,
    required this.totalprecipIn,
    required this.totalsnowCm,
    required this.avgvisKm,
    required this.avgvisMiles,
    required this.avghumidity,
    required this.dailyWillItRain,
    required this.dailyChanceOfRain,
    required this.dailyWillItSnow,
    required this.dailyChanceOfSnow,
    required this.condition,
    required this.uv,
    required this.avgwetbulbC,
    required this.avgwetbulbF,
    required this.maxwetbulbC,
    required this.maxwetbulbF,
  });

  /// Decodes a daily summary from its JSON form.
  factory DayDto.fromJson(Map<String, dynamic> json) => _$DayDtoFromJson(json);

  /// Highest temperature of the day in Celsius.
  final double maxtempC;

  /// Highest temperature of the day in Fahrenheit.
  final double maxtempF;

  /// Lowest temperature of the day in Celsius.
  final double mintempC;

  /// Lowest temperature of the day in Fahrenheit.
  final double mintempF;

  /// Mean temperature of the day in Celsius.
  final double avgtempC;

  /// Mean temperature of the day in Fahrenheit.
  final double avgtempF;

  /// Strongest wind of the day in miles per hour.
  final double maxwindMph;

  /// Strongest wind of the day in kilometres per hour.
  final double maxwindKph;

  /// Total precipitation in millimetres.
  final double totalprecipMm;

  /// Total precipitation in inches.
  final double totalprecipIn;

  /// Total snowfall in centimetres.
  final double totalsnowCm;

  /// Mean visibility in kilometres.
  final double avgvisKm;

  /// Mean visibility in miles.
  final double avgvisMiles;

  /// Mean relative humidity as a percentage.
  final int avghumidity;

  /// 1 when rain is expected during the day.
  final int dailyWillItRain;

  /// Chance of rain as a percentage. Shown beside a forecast row.
  final int dailyChanceOfRain;

  /// 1 when snow is expected during the day.
  final int dailyWillItSnow;

  /// Chance of snow as a percentage.
  final int dailyChanceOfSnow;

  /// The condition that represents the day.
  final ConditionDto condition;

  /// Highest UV index of the day.
  final double uv;

  /// Mean wet bulb temperature in Celsius.
  final double avgwetbulbC;

  /// Mean wet bulb temperature in Fahrenheit.
  final double avgwetbulbF;

  /// Highest wet bulb temperature in Celsius.
  final double maxwetbulbC;

  /// Highest wet bulb temperature in Fahrenheit.
  final double maxwetbulbF;

  /// Encodes this summary back to its JSON form.
  Map<String, dynamic> toJson() => _$DayDtoToJson(this);
}
