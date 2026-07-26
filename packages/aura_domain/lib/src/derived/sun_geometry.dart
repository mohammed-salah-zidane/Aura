/// How long the sun is up between [sunrise] and [sunset].
///
/// Null when either time is missing, which is what a polar day or a polar
/// night produces: WeatherAPI answers `No sunrise` or `No sunset` there, and
/// no duration is the honest reading of that.
Duration? daylightSpan({DateTime? sunrise, DateTime? sunset}) {
  if (sunrise == null || sunset == null) return null;
  final span = sunset.difference(sunrise);
  return span.isNegative ? null : span;
}

/// How far through the day the sun has travelled, from 0 to 1.
///
/// 0 at sunrise and any time before it, 1 at sunset and any time after. The
/// arc the design draws is a shape over this fraction, so the geometry is
/// tested here and the drawing is tested as layout.
///
/// Null when either boundary is missing, or when they are the same instant.
double? sunArcPosition({
  required DateTime now,
  DateTime? sunrise,
  DateTime? sunset,
}) {
  if (sunrise == null || sunset == null) return null;

  final span = sunset.difference(sunrise).inMicroseconds;
  if (span <= 0) return null;

  final elapsed = now.difference(sunrise).inMicroseconds;
  return (elapsed / span).clamp(0.0, 1.0);
}
