import 'package:aura_weather_api/src/dto/astro_dto.dart';
import 'package:aura_weather_api/src/dto/day_dto.dart';
import 'package:aura_weather_api/src/dto/hour_dto.dart';
import 'package:json_annotation/json_annotation.dart';

part 'forecast_day_dto.g.dart';

/// One forecast day: its summary, its sun and moon times, and its 24 hours.
@JsonSerializable()
class ForecastDayDto {
  /// Creates a forecast day.
  const ForecastDayDto({
    required this.date,
    required this.dateEpoch,
    required this.day,
    required this.astro,
    required this.hour,
  });

  /// Decodes a forecast day from its JSON form.
  factory ForecastDayDto.fromJson(Map<String, dynamic> json) =>
      _$ForecastDayDtoFromJson(json);

  /// The day as local `yyyy-MM-dd`.
  final String date;

  /// The start of the day as a Unix timestamp.
  final int dateEpoch;

  /// The daily summary.
  final DayDto day;

  /// Sun and moon times. Already here, so `astronomy.json` is never called.
  final AstroDto astro;

  /// The 24 hours of this day, in local order.
  final List<HourDto> hour;

  /// Encodes this day back to its JSON form.
  Map<String, dynamic> toJson() => _$ForecastDayDtoToJson(this);
}
