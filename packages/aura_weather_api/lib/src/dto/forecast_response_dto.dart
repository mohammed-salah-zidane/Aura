import 'package:aura_weather_api/src/dto/alert_dto.dart';
import 'package:aura_weather_api/src/dto/current_dto.dart';
import 'package:aura_weather_api/src/dto/forecast_day_dto.dart';
import 'package:aura_weather_api/src/dto/location_dto.dart';
import 'package:json_annotation/json_annotation.dart';

part 'forecast_response_dto.g.dart';

/// The whole `forecast.json` response.
///
/// One request produces everything the home screen needs: the place, the
/// current reading, the forecast days with their hours and astro, and any
/// active alerts.
@JsonSerializable()
class ForecastResponseDto {
  /// Creates a forecast response.
  const ForecastResponseDto({
    required this.location,
    required this.current,
    required this.forecast,
    this.alerts,
  });

  /// Decodes a forecast response from its JSON form.
  factory ForecastResponseDto.fromJson(Map<String, dynamic> json) =>
      _$ForecastResponseDtoFromJson(json);

  /// Where the reading is for.
  final LocationDto location;

  /// The reading for right now.
  final CurrentDto current;

  /// The forecast days, wrapped as WeatherAPI wraps them.
  final ForecastDto forecast;

  /// Active alerts, present only when the request asked for them.
  final AlertsDto? alerts;

  /// Encodes this response back to its JSON form.
  Map<String, dynamic> toJson() => _$ForecastResponseDtoToJson(this);
}

/// The `forecast` envelope. Exists because the wire nests the days one level
/// deeper than anything needs; the mapper flattens it.
@JsonSerializable()
class ForecastDto {
  /// Creates a forecast envelope.
  const ForecastDto({required this.forecastday});

  /// Decodes a forecast envelope from its JSON form.
  factory ForecastDto.fromJson(Map<String, dynamic> json) =>
      _$ForecastDtoFromJson(json);

  /// The days. Three of them on the free tier, whatever `days` asked for.
  final List<ForecastDayDto> forecastday;

  /// Encodes this envelope back to its JSON form.
  Map<String, dynamic> toJson() => _$ForecastDtoToJson(this);
}

/// The `alerts` envelope, wrapping the alert list the same way.
@JsonSerializable()
class AlertsDto {
  /// Creates an alerts envelope.
  const AlertsDto({required this.alert});

  /// Decodes an alerts envelope from its JSON form.
  factory AlertsDto.fromJson(Map<String, dynamic> json) =>
      _$AlertsDtoFromJson(json);

  /// The active alerts. Empty when there are none.
  final List<AlertDto> alert;

  /// Encodes this envelope back to its JSON form.
  Map<String, dynamic> toJson() => _$AlertsDtoToJson(this);
}
