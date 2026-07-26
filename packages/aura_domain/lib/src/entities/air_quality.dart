import 'package:aura_domain/src/derived/air_quality_scales.dart';
import 'package:meta/meta.dart';

/// An air quality reading: the published index, and the concentrations it
/// was derived from.
@immutable
final class AirQuality {
  /// Creates an air quality reading.
  const AirQuality({
    required this.usEpaIndex,
    required this.concentrations,
  });

  /// `us-epa-index`, 1 to 6, exactly as the service returns it.
  final int usEpaIndex;

  /// Each pollutant's concentration in µg/m³.
  final Map<Pollutant, double> concentrations;

  /// The EPA category for [usEpaIndex], or null if it is out of range.
  EpaCategory? get category => epaCategory(usEpaIndex);

  /// The band for one pollutant, or null when it has no reading, or when no
  /// published scale covers it.
  AirBand? bandFor(Pollutant pollutant) {
    final value = concentrations[pollutant];
    return value == null ? null : pollutantBand(pollutant, value);
  }
}
