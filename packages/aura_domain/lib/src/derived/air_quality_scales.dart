/// The US EPA air quality categories, indexed 1 to 6.
///
/// WeatherAPI returns the index itself as `us-epa-index`, so this is a lookup
/// rather than a calculation.
enum EpaCategory {
  /// Index 1.
  good,

  /// Index 2.
  moderate,

  /// Index 3.
  unhealthyForSensitiveGroups,

  /// Index 4.
  unhealthy,

  /// Index 5.
  veryUnhealthy,

  /// Index 6.
  hazardous,
}

/// The lowest and highest values `us-epa-index` takes.
const int lowestEpaIndex = 1;

/// The highest value `us-epa-index` takes.
const int highestEpaIndex = 6;

/// Reads `us-epa-index` as its published category.
///
/// Returns null outside 1 to 6 rather than throwing, so a value WeatherAPI
/// changes later degrades to no category instead of crashing a screen.
EpaCategory? epaCategory(int index) => switch (index) {
  1 => EpaCategory.good,
  2 => EpaCategory.moderate,
  3 => EpaCategory.unhealthyForSensitiveGroups,
  4 => EpaCategory.unhealthy,
  5 => EpaCategory.veryUnhealthy,
  6 => EpaCategory.hazardous,
  _ => null,
};

/// Where an EPA index sits along a 0 to 1 scale bar.
double epaScalePosition(int index) {
  final clamped = index.clamp(lowestEpaIndex, highestEpaIndex);
  return (clamped - lowestEpaIndex) / (highestEpaIndex - lowestEpaIndex);
}

/// The pollutants WeatherAPI reports, all in µg/m³.
enum Pollutant {
  /// Fine particulate matter under 2.5µm.
  pm25,

  /// Particulate matter under 10µm.
  pm10,

  /// Nitrogen dioxide.
  no2,

  /// Ozone.
  o3,

  /// Sulphur dioxide.
  so2,

  /// Carbon monoxide.
  co,
}

/// The European Air Quality Index bands for a single pollutant.
///
/// This is the scale the design renders, and it is the one that fits the
/// data: the EEA index is published in µg/m³, which is the unit WeatherAPI
/// returns, while the US EPA breakpoints are defined in ppm and ppb and would
/// need an assumed temperature and pressure to apply.
enum AirBand {
  /// Band 1.
  good,

  /// Band 2.
  fair,

  /// Band 3.
  moderate,

  /// Band 4.
  poor,

  /// Band 5.
  veryPoor,

  /// Band 6.
  extremelyPoor,
}

/// Upper bound of each band, in µg/m³, in [AirBand] order.
///
/// A reading at or below a bound falls in that band. The last band is
/// open-ended, so anything above the fifth bound is extremely poor.
const Map<Pollutant, List<double>> _bandCeilings = <Pollutant, List<double>>{
  Pollutant.pm25: <double>[10, 20, 25, 50, 75],
  Pollutant.pm10: <double>[20, 40, 50, 100, 150],
  Pollutant.no2: <double>[40, 90, 120, 230, 340],
  Pollutant.o3: <double>[50, 100, 130, 240, 380],
  Pollutant.so2: <double>[100, 200, 350, 500, 750],
};

/// Bands one pollutant reading against the European Air Quality Index.
///
/// Returns null for [Pollutant.co], which the index does not cover. No
/// published band exists for carbon monoxide at these concentrations, and
/// inventing one would put a descriptor on screen that no scale backs.
AirBand? pollutantBand(Pollutant pollutant, double microgramsPerCubicMetre) {
  final ceilings = _bandCeilings[pollutant];
  if (ceilings == null) return null;
  if (microgramsPerCubicMetre < 0) return null;

  for (var band = 0; band < ceilings.length; band++) {
    if (microgramsPerCubicMetre <= ceilings[band]) return AirBand.values[band];
  }
  return AirBand.extremelyPoor;
}
