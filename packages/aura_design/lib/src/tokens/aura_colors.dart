import 'dart:ui';

/// Every colour in Aura. Values are read from `aura.pen`.
///
/// Nothing outside this file may declare a colour literal.
abstract final class AuraColors {
  // ---------------------------------------------------------------- text

  /// Headlines and primary values.
  static const Color textPrimary = Color(0xFFFFFFFF);

  /// Body copy and condition text. White at 82%.
  static const Color textSecondary = Color(0xD1FFFFFF);

  /// Labels, captions and metric icons. White at 59%.
  static const Color textTertiary = Color(0x96FFFFFF);

  // -------------------------------------------------------------- surface

  /// Card and panel fill. White at 10%.
  static const Color glass = Color(0x1AFFFFFF);

  /// Elevated glass for pressed and selected states. White at 15%.
  static const Color glass2 = Color(0x26FFFFFF);

  /// One-pixel inner stroke on glass. White at 23%.
  static const Color border = Color(0x3BFFFFFF);

  /// Hairlines, dividers and chart gridlines. White at 8%.
  static const Color grid = Color(0x14FFFFFF);

  /// Fully clear. The app runs edge to edge, so the system bars have no fill of
  /// their own and the sky shows through them.
  static const Color transparent = Color(0x00000000);

  /// Instrument surface.
  static const Color ink = Color(0xFF0F141A);

  /// Deep instrument surface and chart chips.
  static const Color ink2 = Color(0xFF0B0E12);

  // ---------------------------------------------------------------- brand

  /// Gold. Live data, primary buttons and selection.
  static const Color accent = Color(0xFFFFD68A);

  /// Text and icons drawn on top of [accent].
  static const Color onAccent = Color(0xFF0E2A44);

  /// Core of the Aura mark.
  static const Color auraCore = Color(0xFFFBC66A);

  /// Concentric rings of the Aura mark.
  static const Color auraRing = Color(0xFFFFE9C2);

  /// Specular highlight on the Aura mark's core. White at 80%.
  static const Color auraSpecular = Color(0xCCFFFFFF);

  /// A star on the clear-night sky. Each star's own opacity is applied on top.
  static const Color starfield = Color(0xFFFFFFFF);

  // ---------------------------------------------------------------- alert

  /// Warning accent.
  static const Color alert = Color(0xFFFF8A5B);

  /// Alert banner fill.
  static const Color alertSurface = Color(0x26FF8A5B);

  /// Alert banner stroke.
  static const Color alertBorder = Color(0x66FF8A5B);

  /// Alert banner icon.
  static const Color alertIcon = Color(0xFFFFC08A);

  // ------------------------------------------------------------ structure

  /// Rain probability text in forecast rows.
  static const Color rainProbability = Color(0xFF8FC0EE);

  /// Unfilled track behind a temperature range bar. White at 17%.
  static const Color rangeBarTrack = Color(0x2BFFFFFF);

  /// Toggle track in its off position. White at 12%.
  static const Color toggleTrackOff = Color(0x1FFFFFFF);

  // ---------------------------------------------------------------- scale

  /// Severity ramp shared by the UV index and the air-quality index.
  ///
  /// Index maps to severity, not to a fixed category count: the WHO UV bands
  /// and the US EPA categories both read off this ramp, and the domain layer
  /// owns which band a value falls into.
  static const List<Color> severityScale = <Color>[
    scaleLevel1,
    scaleLevel2,
    scaleLevel3,
    scaleLevel4,
    scaleLevel5,
  ];

  /// Lowest severity. Green.
  static const Color scaleLevel1 = Color(0xFF5CD97E);

  /// Low severity. Yellow.
  static const Color scaleLevel2 = Color(0xFFF4CE3B);

  /// Moderate severity. Orange.
  static const Color scaleLevel3 = Color(0xFFF5883A);

  /// High severity. Red.
  static const Color scaleLevel4 = Color(0xFFEF4B4B);

  /// Highest severity. Purple.
  static const Color scaleLevel5 = Color(0xFFA970C9);

  // ------------------------------------------------------- condition tints

  /// Tint for the sun glyph.
  static const Color conditionSun = Color(0xFFFFD46A);

  /// Tint for the sun-behind-cloud glyph.
  static const Color conditionCloudSun = Color(0xFFEAF1F8);

  /// Tint for the cloud glyph.
  static const Color conditionCloud = Color(0xFFE4EBF2);

  /// Tint for the rain glyph.
  static const Color conditionCloudRain = Color(0xFFA9D3F0);

  /// Tint for the drizzle glyph.
  static const Color conditionCloudDrizzle = Color(0xFFBFE0F5);

  /// Tint for the lightning glyph.
  static const Color conditionCloudLightning = Color(0xFFCDB9F5);

  /// Tint for the snow-cloud glyph.
  static const Color conditionCloudSnow = Color(0xFFEAF2F8);

  /// Tint for the snowflake glyph.
  static const Color conditionSnowflake = Color(0xFFFFFFFF);

  /// Tint for the fog glyph.
  static const Color conditionCloudFog = Color(0xFFD6DEE4);

  /// Tint for the moon glyph.
  static const Color conditionMoon = Color(0xFFFFE9B0);

  /// Tint for the moon-behind-cloud glyph.
  static const Color conditionCloudMoon = Color(0xFFE8EEF5);

  /// Tint for the sunrise glyph.
  static const Color conditionSunrise = Color(0xFFFFD46A);

  /// Tint for the sunset glyph.
  static const Color conditionSunset = Color(0xFFFFB27A);

  /// Tint for the lightning-bolt glyph.
  static const Color conditionZap = Color(0xFFE9D98F);
}
