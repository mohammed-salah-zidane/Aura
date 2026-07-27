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

/// How far through its own crossing the moon has travelled, from 0 to 1.
///
/// The moon is not the sun with different times. Its rise and set are reported
/// for one calendar day, so a moon that rises in the evening sets *before* it
/// rises by the clock: Cairo answers a moonrise of 18:08 and a moonset of
/// 03:13 on the same day. A span that reads as negative is that wrap, not bad
/// data, so a day is added rather than the reading being thrown away.
///
/// Null when either boundary is missing, or when the moon is not up.
double? moonArcPosition({
  required DateTime now,
  DateTime? moonrise,
  DateTime? moonset,
}) {
  if (moonrise == null || moonset == null) return null;

  var end = moonset;
  if (!end.isAfter(moonrise)) end = end.add(const Duration(days: 1));

  var moment = now;
  if (moment.isBefore(moonrise)) {
    // Before tonight's rise, the crossing on screen is the one that began
    // yesterday evening and has not set yet.
    moment = moment.add(const Duration(days: 1));
    if (moment.isBefore(moonrise)) return null;
  }

  final span = end.difference(moonrise).inMicroseconds;
  if (span <= 0) return null;

  final elapsed = moment.difference(moonrise).inMicroseconds;
  if (elapsed < 0 || elapsed > span) return null;
  return elapsed / span;
}
