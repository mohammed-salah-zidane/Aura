import 'package:json_annotation/json_annotation.dart';

part 'astro_dto.g.dart';

/// Sun and moon times for one day.
///
/// This object already sits inside `forecastday`, which is why Aura never
/// calls `astronomy.json`.
@JsonSerializable()
class AstroDto {
  /// Creates an astro reading.
  const AstroDto({
    required this.sunrise,
    required this.sunset,
    required this.moonrise,
    required this.moonset,
    required this.moonPhase,
    required this.moonIllumination,
    required this.isMoonUp,
    required this.isSunUp,
  });

  /// Decodes an astro reading from its JSON form.
  factory AstroDto.fromJson(Map<String, dynamic> json) =>
      _$AstroDtoFromJson(json);

  /// Local sunrise as `hh:mm a`. Can read `No sunrise` inside a polar night.
  final String sunrise;

  /// Local sunset as `hh:mm a`. Can read `No sunset` inside a polar day.
  final String sunset;

  /// Local moonrise as `hh:mm a`. Can read `No moonrise`.
  final String moonrise;

  /// Local moonset as `hh:mm a`. Can read `No moonset`.
  final String moonset;

  /// Moon phase in words, for example `Waxing Gibbous`.
  final String moonPhase;

  /// Percentage of the moon's disc lit, 0 to 100.
  final int moonIllumination;

  /// 1 when the moon is above the horizon at the time of the request.
  final int isMoonUp;

  /// 1 when the sun is above the horizon at the time of the request.
  final int isSunUp;

  /// Encodes this reading back to its JSON form.
  Map<String, dynamic> toJson() => _$AstroDtoToJson(this);
}
