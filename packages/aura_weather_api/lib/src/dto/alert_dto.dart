import 'package:json_annotation/json_annotation.dart';

part 'alert_dto.g.dart';

/// One active weather alert, as issued by a national meteorological service.
///
/// An empty `alerts.alert[]` means there is no active alert, not that the
/// tier does not support them.
@JsonSerializable()
class AlertDto {
  /// Creates an alert.
  const AlertDto({
    required this.headline,
    required this.msgtype,
    required this.severity,
    required this.urgency,
    required this.areas,
    required this.category,
    required this.certainty,
    required this.event,
    required this.note,
    required this.effective,
    required this.expires,
    required this.desc,
    required this.instruction,
    this.identifier,
  });

  /// Decodes an alert from its JSON form.
  factory AlertDto.fromJson(Map<String, dynamic> json) =>
      _$AlertDtoFromJson(json);

  /// The issuing service's own identifier. Absent from some feeds.
  final String? identifier;

  /// The full one-line headline, including who issued it and until when.
  final String headline;

  /// `Alert`, `Update` or `Cancel`.
  final String msgtype;

  /// `Minor`, `Moderate`, `Severe` or `Extreme`.
  final String severity;

  /// `Immediate`, `Expected`, `Future`, `Past` or `Unknown`.
  final String urgency;

  /// The affected areas, separated by semicolons.
  final String areas;

  /// The event category, for example `Met` for meteorological.
  final String category;

  /// `Observed`, `Likely`, `Possible`, `Unlikely` or `Unknown`.
  final String certainty;

  /// The event name, for example `Heat Advisory`.
  final String event;

  /// A free-text note. Frequently empty.
  final String note;

  /// When the alert takes effect, as an ISO 8601 string with an offset.
  final String effective;

  /// When the alert stops applying, as an ISO 8601 string with an offset.
  final String expires;

  /// The full description. Carries newlines and the issuer's own headings.
  final String desc;

  /// What the issuer recommends people do.
  final String instruction;

  /// Encodes this alert back to its JSON form.
  Map<String, dynamic> toJson() => _$AlertDtoToJson(this);
}
