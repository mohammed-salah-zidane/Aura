import 'package:flutter/painting.dart';

/// The three Aura families, bundled as assets in this package.
///
/// Fonts are bundled rather than fetched so text renders offline and golden
/// tests stay deterministic.
///
/// All three ship as variable fonts, and their axis defaults are not the
/// weights Aura uses: Fraunces defaults to `wght 900` and Outfit to `wght 100`.
/// Weight is therefore driven through `fontVariations` rather than
/// `fontWeight`, which also stops the engine synthesising a bold on top of the
/// real axis value. The remaining Fraunces axes (`opsz 9`, `SOFT 0`, `WONK 1`)
/// already match the font's named instances, so they are left at their
/// defaults.
abstract final class AuraFonts {
  /// Package that ships the font assets.
  static const String package = 'aura_design';

  /// Display serif. The identity: temperatures, city names, screen titles.
  static const String display = 'Fraunces';

  /// Geometric sans. Values, conditions and in-card UI.
  static const String app = 'Outfit';

  /// System sans. Labels, body copy, captions and the status bar.
  static const String system = 'Inter';
}

/// Every text style in Aura, named for what it labels rather than how it is
/// drawn. Values are read from `aura.pen`.
abstract final class AuraText {
  // ------------------------------------------------------ Fraunces, display

  /// Hero temperature. `35°`
  static const TextStyle display = TextStyle(
    fontFamily: AuraFonts.display,
    package: AuraFonts.package,
    fontSize: 98,
    fontVariations: <FontVariation>[FontVariation('wght', 300)],
    height: 1.05,
  );

  /// City name on the hero. `Cairo`
  static const TextStyle titleCity = TextStyle(
    fontFamily: AuraFonts.display,
    package: AuraFonts.package,
    fontSize: 34,
    fontVariations: <FontVariation>[FontVariation('wght', 500)],
  );

  /// Headline on a full-screen state. `You're Offline`
  static const TextStyle titleState = TextStyle(
    fontFamily: AuraFonts.display,
    package: AuraFonts.package,
    fontSize: 26,
    fontVariations: <FontVariation>[FontVariation('wght', 600)],
  );

  /// Large numeric read-out. `210`
  static const TextStyle readout = TextStyle(
    fontFamily: AuraFonts.display,
    package: AuraFonts.package,
    fontSize: 26,
    fontVariations: <FontVariation>[FontVariation('wght', 400)],
  );

  /// Screen title. `3-Day Forecast`
  static const TextStyle titleScreen = TextStyle(
    fontFamily: AuraFonts.display,
    package: AuraFonts.package,
    fontSize: 24,
    fontVariations: <FontVariation>[FontVariation('wght', 500)],
  );

  /// Card title, and the city on a city card. `Waxing Crescent`
  static const TextStyle titleCard = TextStyle(
    fontFamily: AuraFonts.display,
    package: AuraFonts.package,
    fontSize: 22,
    fontVariations: <FontVariation>[FontVariation('wght', 500)],
  );

  /// Smaller card title. `Waxing Crescent`
  static const TextStyle titleCardSmall = TextStyle(
    fontFamily: AuraFonts.display,
    package: AuraFonts.package,
    fontSize: 20,
    fontVariations: <FontVariation>[FontVariation('wght', 500)],
  );

  // ------------------------------------------------------------ Outfit, app

  /// Temperature on a city card. `35°`
  static const TextStyle cityCardTemperature = TextStyle(
    fontFamily: AuraFonts.app,
    package: AuraFonts.package,
    fontSize: 42,
    fontVariations: <FontVariation>[FontVariation('wght', 300)],
  );

  /// Primary value inside a metric card. `18 km/h`
  static const TextStyle metricValue = TextStyle(
    fontFamily: AuraFonts.app,
    package: AuraFonts.package,
    fontSize: 29,
    fontVariations: <FontVariation>[FontVariation('wght', 300)],
  );

  /// Current condition under the hero. `Mostly Sunny`
  static const TextStyle condition = TextStyle(
    fontFamily: AuraFonts.app,
    package: AuraFonts.package,
    fontSize: 20,
    fontVariations: <FontVariation>[FontVariation('wght', 400)],
  );

  /// Temperature in a search result. `35°`
  static const TextStyle searchResultTemperature = TextStyle(
    fontFamily: AuraFonts.app,
    package: AuraFonts.package,
    fontSize: 18,
    fontVariations: <FontVariation>[FontVariation('wght', 400)],
  );

  /// High and low, and hour-cell temperatures. `H:37°`
  static const TextStyle temperature = TextStyle(
    fontFamily: AuraFonts.app,
    package: AuraFonts.package,
    fontSize: 17,
    fontVariations: <FontVariation>[FontVariation('wght', 500)],
  );

  /// Primary button label. `Try Again`
  static const TextStyle buttonPrimary = TextStyle(
    fontFamily: AuraFonts.app,
    package: AuraFonts.package,
    fontSize: 16,
    fontVariations: <FontVariation>[FontVariation('wght', 600)],
  );

  /// Secondary button label. `Use Saved Data`
  static const TextStyle buttonSecondary = TextStyle(
    fontFamily: AuraFonts.app,
    package: AuraFonts.package,
    fontSize: 16,
    fontVariations: <FontVariation>[FontVariation('wght', 500)],
  );

  /// Settings row label. `Temperature`
  static const TextStyle rowLabel = TextStyle(
    fontFamily: AuraFonts.app,
    package: AuraFonts.package,
    fontSize: 15,
    fontVariations: <FontVariation>[FontVariation('wght', 500)],
  );

  /// Multi-line summary paragraph above the hourly strip.
  static const TextStyle summary = TextStyle(
    fontFamily: AuraFonts.app,
    package: AuraFonts.package,
    fontSize: 15,
    fontVariations: <FontVariation>[FontVariation('wght', 400)],
    height: 1.35,
  );

  /// Search field placeholder. `Search for a city or airport`
  static const TextStyle placeholder = TextStyle(
    fontFamily: AuraFonts.app,
    package: AuraFonts.package,
    fontSize: 15,
    fontVariations: <FontVariation>[FontVariation('wght', 400)],
  );

  /// Hour label in the hourly strip. `3 PM`
  static const TextStyle hourTime = TextStyle(
    fontFamily: AuraFonts.app,
    package: AuraFonts.package,
    fontSize: 13,
    fontVariations: <FontVariation>[FontVariation('wght', 400)],
  );

  /// Hour label for the current hour. `Now`
  static const TextStyle hourTimeNow = TextStyle(
    fontFamily: AuraFonts.app,
    package: AuraFonts.package,
    fontSize: 13,
    fontVariations: <FontVariation>[FontVariation('wght', 600)],
  );

  /// Sub-line under a metric value. `NW · gusts 22`
  static const TextStyle metricSub = TextStyle(
    fontFamily: AuraFonts.app,
    package: AuraFonts.package,
    fontSize: 12.5,
    fontVariations: <FontVariation>[FontVariation('wght', 400)],
  );

  // -------------------------------------------------------- Inter, system

  /// Status-bar clock. `2:34`
  static const TextStyle statusTime = TextStyle(
    fontFamily: AuraFonts.system,
    package: AuraFonts.package,
    fontSize: 17,
    fontVariations: <FontVariation>[FontVariation('wght', 600)],
  );

  /// Daily high in a forecast row. `37°`
  static const TextStyle forecastHigh = TextStyle(
    fontFamily: AuraFonts.system,
    package: AuraFonts.package,
    fontSize: 16,
    fontVariations: <FontVariation>[FontVariation('wght', 600)],
  );

  /// Daily low in a forecast row. `25°`
  static const TextStyle forecastLow = TextStyle(
    fontFamily: AuraFonts.system,
    package: AuraFonts.package,
    fontSize: 16,
    fontVariations: <FontVariation>[FontVariation('wght', 500)],
  );

  /// Day name in a forecast row. `Mon`
  static const TextStyle forecastDay = TextStyle(
    fontFamily: AuraFonts.system,
    package: AuraFonts.package,
    fontSize: 15,
    fontVariations: <FontVariation>[FontVariation('wght', 500)],
  );

  /// Alert banner title. `Heat Advisory`
  static const TextStyle alertTitle = TextStyle(
    fontFamily: AuraFonts.system,
    package: AuraFonts.package,
    fontSize: 14,
    fontVariations: <FontVariation>[FontVariation('wght', 600)],
  );

  /// Long-form body copy.
  static const TextStyle body = TextStyle(
    fontFamily: AuraFonts.system,
    package: AuraFonts.package,
    fontSize: 14,
    fontVariations: <FontVariation>[FontVariation('wght', 400)],
    height: 1.45,
  );

  /// Body copy in a tighter block, such as a bulleted instruction.
  static const TextStyle bodyTight = TextStyle(
    fontFamily: AuraFonts.system,
    package: AuraFonts.package,
    fontSize: 14,
    fontVariations: <FontVariation>[FontVariation('wght', 400)],
    height: 1.4,
  );

  /// Single-line body text, such as a settings row value. `Automatic`
  static const TextStyle bodyValue = TextStyle(
    fontFamily: AuraFonts.system,
    package: AuraFonts.package,
    fontSize: 14,
    fontVariations: <FontVariation>[FontVariation('wght', 400)],
  );

  /// Temperature in a compact forecast strip. `37°`
  static const TextStyle forecastTemperatureSmall = TextStyle(
    fontFamily: AuraFonts.system,
    package: AuraFonts.package,
    fontSize: 13,
    fontVariations: <FontVariation>[FontVariation('wght', 600)],
  );

  /// Metric card label. `PRESSURE`
  static const TextStyle label = TextStyle(
    fontFamily: AuraFonts.system,
    package: AuraFonts.package,
    fontSize: 12,
    fontVariations: <FontVariation>[FontVariation('wght', 600)],
    letterSpacing: 0.6,
  );

  /// Location kicker above the hero. `CURRENT LOCATION`
  static const TextStyle kicker = TextStyle(
    fontFamily: AuraFonts.system,
    package: AuraFonts.package,
    fontSize: 12,
    fontVariations: <FontVariation>[FontVariation('wght', 600)],
    letterSpacing: 1.4,
  );

  /// Pollutant name in the air-quality list. `PM2.5`
  static const TextStyle pollutantLabel = TextStyle(
    fontFamily: AuraFonts.system,
    package: AuraFonts.package,
    fontSize: 12,
    fontVariations: <FontVariation>[FontVariation('wght', 600)],
    letterSpacing: 0.4,
  );

  /// Chip and supporting note text. `Level 1 of 6 · Low health risk`
  static const TextStyle chip = TextStyle(
    fontFamily: AuraFonts.system,
    package: AuraFonts.package,
    fontSize: 12,
    fontVariations: <FontVariation>[FontVariation('wght', 500)],
  );

  /// Secondary caption. `Queensland, Australia`
  static const TextStyle caption = TextStyle(
    fontFamily: AuraFonts.system,
    package: AuraFonts.package,
    fontSize: 12,
    fontVariations: <FontVariation>[FontVariation('wght', 400)],
  );

  /// Hour index on an instrument chart. `01`
  static const TextStyle chartIndex = TextStyle(
    fontFamily: AuraFonts.system,
    package: AuraFonts.package,
    fontSize: 12,
    fontVariations: <FontVariation>[FontVariation('wght', 700)],
    letterSpacing: 2.4,
  );

  /// Tracked caption. `SAT 25 JUL · UPDATED 2:34 PM`
  static const TextStyle captionTracked = TextStyle(
    fontFamily: AuraFonts.system,
    package: AuraFonts.package,
    fontSize: 11,
    fontVariations: <FontVariation>[FontVariation('wght', 500)],
    letterSpacing: 0.6,
  );

  /// Section heading in settings and detail screens. `UNITS`
  static const TextStyle sectionLabel = TextStyle(
    fontFamily: AuraFonts.system,
    package: AuraFonts.package,
    fontSize: 11,
    fontVariations: <FontVariation>[FontVariation('wght', 600)],
    letterSpacing: 1.4,
  );

  /// Widely tracked location kicker. `CAIRO, EGYPT`
  static const TextStyle kickerWide = TextStyle(
    fontFamily: AuraFonts.system,
    package: AuraFonts.package,
    fontSize: 11,
    fontVariations: <FontVariation>[FontVariation('wght', 600)],
    letterSpacing: 2,
  );

  /// Small tracked label under an astro value. `SUNRISE`
  static const TextStyle astroLabel = TextStyle(
    fontFamily: AuraFonts.system,
    package: AuraFonts.package,
    fontSize: 10,
    fontVariations: <FontVariation>[FontVariation('wght', 600)],
    letterSpacing: 0.8,
  );

  /// End label on a scale bar. `HAZARDOUS`
  static const TextStyle scaleEndLabel = TextStyle(
    fontFamily: AuraFonts.system,
    package: AuraFonts.package,
    fontSize: 10,
    fontVariations: <FontVariation>[FontVariation('wght', 600)],
    letterSpacing: 0.5,
  );

  /// Alert metadata label. `EFFECTIVE`
  static const TextStyle metaLabel = TextStyle(
    fontFamily: AuraFonts.system,
    package: AuraFonts.package,
    fontSize: 10,
    fontVariations: <FontVariation>[FontVariation('wght', 600)],
    letterSpacing: 1,
  );
}
