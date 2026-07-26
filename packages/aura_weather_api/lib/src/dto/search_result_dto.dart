import 'package:json_annotation/json_annotation.dart';

part 'search_result_dto.g.dart';

/// One autocomplete match from `search.json`.
@JsonSerializable()
class SearchResultDto {
  /// Creates a search result.
  const SearchResultDto({
    required this.id,
    required this.name,
    required this.region,
    required this.country,
    required this.lat,
    required this.lon,
    required this.url,
  });

  /// Decodes a search result from its JSON form.
  factory SearchResultDto.fromJson(Map<String, dynamic> json) =>
      _$SearchResultDtoFromJson(json);

  /// WeatherAPI's own identifier for the place.
  final int id;

  /// City name.
  final String name;

  /// Administrative region. Can be empty.
  final String region;

  /// Country name.
  final String country;

  /// Latitude in degrees.
  final double lat;

  /// Longitude in degrees.
  final double lon;

  /// WeatherAPI's slug for the place, usable as a `q` value.
  final String url;

  /// Encodes this result back to its JSON form.
  Map<String, dynamic> toJson() => _$SearchResultDtoToJson(this);
}
