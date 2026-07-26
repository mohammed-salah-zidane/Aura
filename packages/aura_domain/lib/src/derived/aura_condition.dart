/// The weather conditions Aura draws a sky for.
///
/// Nine values for WeatherAPI's forty-seven condition codes, because the sky
/// is the thing being chosen and the design has eight of them. The words a
/// user reads still come from `condition.text`, which the API returns already
/// translated.
enum AuraCondition {
  /// Clear or sunny, during the day.
  clearDay,

  /// Clear, at night.
  clearNight,

  /// Some cloud, sun still visible.
  partlyCloudy,

  /// Cloudy or overcast.
  overcast,

  /// Mist, fog or freezing fog.
  fog,

  /// Any liquid precipitation, from patchy drizzle to torrential showers.
  rain,

  /// Any frozen precipitation: snow, sleet, ice pellets, blizzard.
  snow,

  /// Thunder, with or without precipitation.
  thunderstorm,

  /// A code this table does not know.
  ///
  /// WeatherAPI can add codes. Returning this rather than throwing, or
  /// guessing at a neighbour, lets the screen fall back to the brand sky
  /// while still showing the API's own words for the condition.
  unknown,
}

/// Clear sky. The only code whose sky depends on `is_day`.
const int _clearCode = 1000;

/// Every other condition code WeatherAPI documents, and the sky it maps to.
///
/// Sleet and ice pellets sit under [AuraCondition.snow]: the design has no
/// sleet sky, and frozen precipitation reads closer to snow than to rain.
const Map<int, AuraCondition> _byCode = <int, AuraCondition>{
  1003: AuraCondition.partlyCloudy,
  1006: AuraCondition.overcast,
  1009: AuraCondition.overcast,
  1030: AuraCondition.fog, // mist
  1135: AuraCondition.fog,
  1147: AuraCondition.fog, // freezing fog
  1063: AuraCondition.rain, // patchy rain possible
  1150: AuraCondition.rain,
  1153: AuraCondition.rain,
  1168: AuraCondition.rain, // freezing drizzle
  1171: AuraCondition.rain,
  1180: AuraCondition.rain,
  1183: AuraCondition.rain,
  1186: AuraCondition.rain,
  1189: AuraCondition.rain,
  1192: AuraCondition.rain,
  1195: AuraCondition.rain,
  1198: AuraCondition.rain, // light freezing rain
  1201: AuraCondition.rain,
  1240: AuraCondition.rain,
  1243: AuraCondition.rain,
  1246: AuraCondition.rain, // torrential shower
  1066: AuraCondition.snow, // patchy snow possible
  1069: AuraCondition.snow, // patchy sleet possible
  1072: AuraCondition.snow, // patchy freezing drizzle possible
  1114: AuraCondition.snow, // blowing snow
  1117: AuraCondition.snow, // blizzard
  1204: AuraCondition.snow, // light sleet
  1207: AuraCondition.snow,
  1210: AuraCondition.snow,
  1213: AuraCondition.snow,
  1216: AuraCondition.snow,
  1219: AuraCondition.snow,
  1222: AuraCondition.snow,
  1225: AuraCondition.snow,
  1237: AuraCondition.snow, // ice pellets
  1249: AuraCondition.snow, // light sleet showers
  1252: AuraCondition.snow,
  1255: AuraCondition.snow,
  1258: AuraCondition.snow,
  1261: AuraCondition.snow, // ice pellet showers
  1264: AuraCondition.snow,
  1087: AuraCondition.thunderstorm, // thundery outbreaks possible
  1273: AuraCondition.thunderstorm,
  1276: AuraCondition.thunderstorm,
  1279: AuraCondition.thunderstorm,
  1282: AuraCondition.thunderstorm,
};

/// Reads a WeatherAPI `condition.code` as the sky it should paint.
///
/// [isDay] comes from `is_day`, and matters only for a clear sky: everything
/// else looks the same after dark.
AuraCondition conditionFromCode(int code, {required bool isDay}) {
  if (code == _clearCode) {
    return isDay ? AuraCondition.clearDay : AuraCondition.clearNight;
  }
  return _byCode[code] ?? AuraCondition.unknown;
}

/// Every code this table knows, for tests and for auditing coverage.
Set<int> get knownConditionCodes => <int>{_clearCode, ..._byCode.keys};
