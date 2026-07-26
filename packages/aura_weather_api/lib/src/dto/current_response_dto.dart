import 'package:aura_weather_api/src/dto/current_dto.dart';
import 'package:aura_weather_api/src/dto/location_dto.dart';
import 'package:json_annotation/json_annotation.dart';

part 'current_response_dto.g.dart';

/// The whole `current.json` response.
///
/// Used for the temperature beside a search result and for each saved city,
/// where a full forecast would be wasted quota.
@JsonSerializable()
class CurrentResponseDto {
  /// Creates a current response.
  const CurrentResponseDto({required this.location, required this.current});

  /// Decodes a current response from its JSON form.
  factory CurrentResponseDto.fromJson(Map<String, dynamic> json) =>
      _$CurrentResponseDtoFromJson(json);

  /// Where the reading is for.
  final LocationDto location;

  /// The reading for right now.
  final CurrentDto current;

  /// Encodes this response back to its JSON form.
  Map<String, dynamic> toJson() => _$CurrentResponseDtoToJson(this);
}
