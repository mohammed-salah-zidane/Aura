import 'package:json_annotation/json_annotation.dart';

part 'location_dto.g.dart';

/// The place a reading belongs to.
@JsonSerializable()
class LocationDto {
  /// Creates a location.
  const LocationDto({
    required this.name,
    required this.region,
    required this.country,
    required this.lat,
    required this.lon,
    required this.tzId,
    required this.localtimeEpoch,
    required this.localtime,
  });

  /// Decodes a location from its JSON form.
  factory LocationDto.fromJson(Map<String, dynamic> json) =>
      _$LocationDtoFromJson(json);

  /// City name, for example `Cairo`.
  final String name;

  /// Administrative region, for example `Al Qahirah`. Can be empty.
  final String region;

  /// Country name, for example `Egypt`.
  final String country;

  /// Latitude in degrees.
  final double lat;

  /// Longitude in degrees.
  final double lon;

  /// IANA time zone, for example `Africa/Cairo`.
  final String tzId;

  /// Local time as a Unix timestamp.
  final int localtimeEpoch;

  /// Local time as `yyyy-MM-dd HH:mm`.
  final String localtime;

  /// Encodes this location back to its JSON form.
  Map<String, dynamic> toJson() => _$LocationDtoToJson(this);
}
