import 'package:json_annotation/json_annotation.dart';

part 'air_quality_dto.g.dart';

/// Pollutant concentrations and the two published index readings.
///
/// Concentrations are µg/m³, except carbon monoxide which WeatherAPI also
/// reports in µg/m³ despite the far larger magnitude.
@JsonSerializable()
class AirQualityDto {
  /// Creates an air quality reading.
  const AirQualityDto({
    required this.co,
    required this.no2,
    required this.o3,
    required this.so2,
    required this.pm25,
    required this.pm10,
    required this.usEpaIndex,
    required this.gbDefraIndex,
  });

  /// Decodes an air quality reading from its JSON form.
  factory AirQualityDto.fromJson(Map<String, dynamic> json) =>
      _$AirQualityDtoFromJson(json);

  /// Carbon monoxide, µg/m³.
  final double co;

  /// Nitrogen dioxide, µg/m³.
  final double no2;

  /// Ozone, µg/m³.
  final double o3;

  /// Sulphur dioxide, µg/m³.
  final double so2;

  /// Fine particulate matter under 2.5µm, µg/m³.
  @JsonKey(name: 'pm2_5')
  final double pm25;

  /// Particulate matter under 10µm, µg/m³.
  final double pm10;

  /// US EPA index, 1 to 6. This is the reading Aura shows.
  @JsonKey(name: 'us-epa-index')
  final int usEpaIndex;

  /// UK DEFRA index, 1 to 10.
  @JsonKey(name: 'gb-defra-index')
  final int gbDefraIndex;

  /// Encodes this reading back to its JSON form.
  Map<String, dynamic> toJson() => _$AirQualityDtoToJson(this);
}
