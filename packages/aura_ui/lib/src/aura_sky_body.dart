import 'package:aura_design/aura_design.dart';
import 'package:aura_domain/aura_domain.dart';

/// Which body is over the place right now, and where it sits on its arc.
///
/// Null when neither is up, which is the honest reading of a moon that has set
/// before it rises again and of a polar night with no times at all.
///
/// WeatherAPI reports no solar elevation and no azimuth, so nothing here is a
/// reported angle. The position is arithmetic over `sunrise`, `sunset`,
/// `moonrise`, `moonset` and the place's own clock, which is the same
/// derivation the sun path chart on the detail screen already draws.
AuraCelestial? skyBodyFor(WeatherSnapshot snapshot) {
  // Nothing is visible through a covered sky. Rain, snow, fog, a thunderstorm
  // and full overcast all hide the sun, so the body follows the condition the
  // service reported as well as the clock. Partly cloudy keeps it, because
  // that is the condition where the sun is out between the clouds.
  const clearEnough = <AuraCondition>{
    AuraCondition.clearDay,
    AuraCondition.clearNight,
    AuraCondition.partlyCloudy,
  };
  if (!clearEnough.contains(snapshot.current.condition)) return null;

  final astro = snapshot.today.astro;
  final now = snapshot.localTime;

  final sun = sunArcPosition(
    now: now,
    sunrise: astro.sunrise,
    sunset: astro.sunset,
  );
  // The arc clamps, so a sun that has set still reads as 1. Whether it is
  // actually up is the pair of comparisons, not the fraction.
  final sunIsUp =
      astro.sunrise != null &&
      astro.sunset != null &&
      !now.isBefore(astro.sunrise!) &&
      now.isBefore(astro.sunset!);

  if (sunIsUp && sun != null) {
    return AuraCelestial(body: AuraCelestialBody.sun, position: sun);
  }

  final moon = moonArcPosition(
    now: now,
    moonrise: astro.moonrise,
    moonset: astro.moonset,
  );
  if (moon == null) return null;

  return AuraCelestial(
    body: AuraCelestialBody.moon,
    position: moon,
    illumination: astro.moonIlluminationPercent / 100,
    isWaxing: astro.moonPhase.isWaxing,
  );
}
