import 'package:aura_domain/src/entities/forecast_day.dart';
import 'package:aura_domain/src/entities/hourly_point.dart';

/// The hours from [from] onwards, across as many forecast days as it takes.
///
/// WeatherAPI returns 24 hours per day, each stamped with the place's own wall
/// clock, so a strip that starts at the current hour has to run off the end of
/// today and into tomorrow. The hour [from] falls inside is included, because
/// that hour is the one the design labels "Now".
///
/// Returns fewer than [count] entries when the forecast runs out, and an empty
/// list when every hour is already behind [from].
List<HourlyPoint> upcomingHours(
  List<ForecastDay> days, {
  required DateTime from,
  int count = 24,
}) {
  final startOfHour = DateTime(from.year, from.month, from.day, from.hour);
  final window = <HourlyPoint>[];

  for (final day in days) {
    for (final hour in day.hours) {
      if (hour.time.isBefore(startOfHour)) continue;
      window.add(hour);
      if (window.length == count) return window;
    }
  }
  return window;
}

/// Whether the sun sets during the hour beginning at [hour].
///
/// The design draws that one cell with a sunset glyph rather than the
/// condition's own, which is the only place an hour cell departs from the
/// condition it reports.
bool isSunsetHour(DateTime hour, DateTime? sunset) {
  if (sunset == null) return false;
  return sunset.year == hour.year &&
      sunset.month == hour.month &&
      sunset.day == hour.day &&
      sunset.hour == hour.hour;
}
