/// The eight moon phases WeatherAPI names in `astro.moon_phase`.
enum MoonPhase {
  /// New moon.
  newMoon,

  /// Waxing crescent.
  waxingCrescent,

  /// First quarter.
  firstQuarter,

  /// Waxing gibbous.
  waxingGibbous,

  /// Full moon.
  fullMoon,

  /// Waning gibbous.
  waningGibbous,

  /// Last quarter.
  lastQuarter,

  /// Waning crescent.
  waningCrescent,

  /// A phase name this table does not know.
  unknown;

  /// Whether the lit fraction is growing.
  ///
  /// Drives which limb of the disc the shadow sits on. False for the new and
  /// full moons, where there is no limb to choose, and for [unknown].
  bool get isWaxing => switch (this) {
    MoonPhase.waxingCrescent ||
    MoonPhase.firstQuarter ||
    MoonPhase.waxingGibbous => true,
    MoonPhase.newMoon ||
    MoonPhase.fullMoon ||
    MoonPhase.waningGibbous ||
    MoonPhase.lastQuarter ||
    MoonPhase.waningCrescent ||
    MoonPhase.unknown => false,
  };
}

const Map<String, MoonPhase> _byName = <String, MoonPhase>{
  'new moon': MoonPhase.newMoon,
  'waxing crescent': MoonPhase.waxingCrescent,
  'first quarter': MoonPhase.firstQuarter,
  'waxing gibbous': MoonPhase.waxingGibbous,
  'full moon': MoonPhase.fullMoon,
  'waning gibbous': MoonPhase.waningGibbous,
  'last quarter': MoonPhase.lastQuarter,
  'waning crescent': MoonPhase.waningCrescent,
};

/// Reads `astro.moon_phase` as a phase.
///
/// Matching is case-insensitive and ignores surrounding space, because the
/// value is a display string on the wire rather than an identifier. An
/// unrecognised name returns [MoonPhase.unknown] instead of throwing.
MoonPhase moonPhaseFromName(String name) =>
    _byName[name.trim().toLowerCase()] ?? MoonPhase.unknown;
