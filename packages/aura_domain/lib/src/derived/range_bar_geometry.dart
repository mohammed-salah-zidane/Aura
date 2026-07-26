/// Where one day's temperature range sits inside the whole period's range.
///
/// `start` and `extent` are fractions of the track, so a forecast row can draw
/// its bar without knowing a single temperature. Both are clamped to the
/// track, and `start + extent` never exceeds 1.
typedef RangeBar = ({double start, double extent});

/// Places a day's low-to-high span on a shared 0 to 1 track.
///
/// [periodLow] and [periodHigh] are the coldest and warmest readings across
/// every day being shown, which is what makes the rows comparable.
///
/// A period with no spread at all, which happens when every day shares one
/// temperature, fills the track: there is no meaningful position within a
/// range of zero width, and a zero-width bar would read as missing data.
RangeBar rangeBarGeometry({
  required double low,
  required double high,
  required double periodLow,
  required double periodHigh,
}) {
  final periodSpan = periodHigh - periodLow;
  if (periodSpan <= 0) return (start: 0, extent: 1);

  final start = ((low - periodLow) / periodSpan).clamp(0.0, 1.0);
  final end = ((high - periodLow) / periodSpan).clamp(0.0, 1.0);
  return (start: start, extent: (end - start).clamp(0.0, 1.0));
}
