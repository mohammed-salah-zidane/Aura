import 'package:json_annotation/json_annotation.dart';

part 'condition_dto.g.dart';

/// A weather condition as WeatherAPI reports it.
@JsonSerializable()
class ConditionDto {
  /// Creates a condition.
  const ConditionDto({
    required this.text,
    required this.icon,
    required this.code,
  });

  /// Decodes a condition from its JSON form.
  factory ConditionDto.fromJson(Map<String, dynamic> json) =>
      _$ConditionDtoFromJson(json);

  /// The condition in words, already translated when `lang` was sent.
  final String text;

  /// The URL of WeatherAPI's own icon. Aura draws its own and ignores this.
  final String icon;

  /// The condition code, 1000 to 1282. Aura maps this, never [text].
  final int code;

  /// Encodes this condition back to its JSON form.
  Map<String, dynamic> toJson() => _$ConditionDtoToJson(this);
}
