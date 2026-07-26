import 'package:meta/meta.dart';

/// How serious an alert is, as the issuing service grades it.
enum AlertSeverity {
  /// Minimal or no threat.
  minor,

  /// Possible threat.
  moderate,

  /// Significant threat.
  severe,

  /// Extraordinary threat.
  extreme,

  /// A grade this table does not know.
  unknown;

  /// How serious this grade is, worst highest.
  ///
  /// Declaration order cannot be used for this: [unknown] is declared last so
  /// the known grades read in order, which would otherwise make an ungraded
  /// notice outrank an extreme warning. An unknown grade ranks below every
  /// known one, because it carries no claim about severity at all.
  int get rank => switch (this) {
    AlertSeverity.unknown => -1,
    AlertSeverity.minor => 0,
    AlertSeverity.moderate => 1,
    AlertSeverity.severe => 2,
    AlertSeverity.extreme => 3,
  };
}

/// Reads the issuer's `severity` string.
AlertSeverity alertSeverityFromName(String name) =>
    switch (name.trim().toLowerCase()) {
      'minor' => AlertSeverity.minor,
      'moderate' => AlertSeverity.moderate,
      'severe' => AlertSeverity.severe,
      'extreme' => AlertSeverity.extreme,
      _ => AlertSeverity.unknown,
    };

/// One active weather alert.
///
/// Every field is the issuing meteorological service's own text. Nothing here
/// is written by the app, which is why the alert screen reads as an official
/// notice rather than a summary of one.
@immutable
final class WeatherAlert {
  /// Creates an alert.
  const WeatherAlert({
    required this.event,
    required this.severity,
    required this.category,
    required this.areas,
    required this.description,
    required this.instruction,
    this.effective,
    this.expires,
  });

  /// The event name, for example `Heat Advisory`.
  final String event;

  /// How serious the issuer graded it.
  final AlertSeverity severity;

  /// The issuer's category, for example `Met`.
  final String category;

  /// The affected areas, already split.
  final List<String> areas;

  /// The issuer's full description.
  final String description;

  /// What the issuer recommends people do. Empty when they said nothing.
  final String instruction;

  /// When it takes effect, or null if the issuer gave no parsable time.
  final DateTime? effective;

  /// When it stops applying, or null if the issuer gave no parsable time.
  final DateTime? expires;
}
