import 'package:aura_domain/src/derived/moon_phase.dart';
import 'package:meta/meta.dart';

/// Sun and moon times for one day.
///
/// Every time is nullable because WeatherAPI answers `No sunrise`, `No sunset`
/// or `No moonrise` at high latitudes, and a polar day is a real reading
/// rather than a parse failure.
@immutable
final class AstroInfo {
  /// Creates an astro reading.
  const AstroInfo({
    required this.moonPhase,
    required this.moonIlluminationPercent,
    this.sunrise,
    this.sunset,
    this.moonrise,
    this.moonset,
  });

  /// Local sunrise, or null on a day without one.
  final DateTime? sunrise;

  /// Local sunset, or null on a day without one.
  final DateTime? sunset;

  /// Local moonrise, or null on a day without one.
  final DateTime? moonrise;

  /// Local moonset, or null on a day without one.
  final DateTime? moonset;

  /// The moon phase.
  final MoonPhase moonPhase;

  /// How much of the moon's disc is lit, 0 to 100.
  final int moonIlluminationPercent;
}
