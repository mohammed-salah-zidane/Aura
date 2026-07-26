/// The WHO/WMO global solar UV index bands.
///
/// The published scale runs Low, Moderate, High, Very high, Extreme. Aura
/// carries a sixth band for an index of exactly zero, which the scale does
/// not name because it is the absence of a reading rather than a level of
/// one. It happens every night, and the design shows it.
enum UvBand {
  /// Index 0. No measurable ultraviolet, which is what night reads as.
  none,

  /// Index 1 to 2.
  low,

  /// Index 3 to 5.
  moderate,

  /// Index 6 to 7.
  high,

  /// Index 8 to 10.
  veryHigh,

  /// Index 11 and above.
  extreme,
}

/// The lowest index of each band, per the WHO scale.
const double _lowFloor = 1;
const double _moderateFloor = 3;
const double _highFloor = 6;
const double _veryHighFloor = 8;
const double _extremeFloor = 11;

/// Bands `current.uv` against the WHO scale.
///
/// A fractional reading falls in the band its whole part belongs to, so 2.9
/// is still Low and 3.0 is Moderate.
UvBand uvBand(double uv) {
  if (uv < _lowFloor) return UvBand.none;
  if (uv < _moderateFloor) return UvBand.low;
  if (uv < _highFloor) return UvBand.moderate;
  if (uv < _veryHighFloor) return UvBand.high;
  if (uv < _extremeFloor) return UvBand.veryHigh;
  return UvBand.extreme;
}

/// Where [uv] sits along a 0 to 1 scale bar.
///
/// The bar tops out at the start of Extreme, because the scale is open-ended
/// and a bar cannot be. Anything higher pins to the end.
double uvScalePosition(double uv) {
  if (uv <= 0) return 0;
  if (uv >= _extremeFloor) return 1;
  return uv / _extremeFloor;
}
