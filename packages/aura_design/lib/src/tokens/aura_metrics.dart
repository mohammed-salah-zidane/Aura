import 'dart:ui';

/// Spacing steps. Values are read from `aura.pen`.
///
/// The design sits on a 4-point grid with a few deliberate half-steps inside
/// dense components such as hour cells and metric cards.
abstract final class AuraSpacing {
  /// 2. Hairline separation inside a stacked label.
  static const double hairline = 2;

  /// 4. Tightest grid step.
  static const double xxs = 4;

  /// 6. Half-step used inside dense cells.
  static const double xs = 6;

  /// 8. Between a label and its value.
  static const double sm = 8;

  /// 10. Half-step between rows of a metric grid.
  static const double smPlus = 10;

  /// 12. Default gap inside a card.
  static const double md = 12;

  /// 14. Between the items of a horizontal strip.
  static const double mdPlus = 14;

  /// 16. Between cards.
  static const double lg = 16;

  /// 18. Between a card and the section under it.
  static const double lgPlus = 18;

  /// 20. Screen horizontal padding, and the gap between sections.
  static const double xl = 20;

  /// 24. Around a full-screen state's content.
  static const double xxl = 24;

  /// 32. Above a primary action.
  static const double xxxl = 32;

  /// 48. Around the mark on the splash screen.
  static const double huge = 48;
}

/// Corner radii. Values are read from `aura.pen`.
abstract final class AuraRadii {
  /// 2. Scale bar and range bar tracks.
  static const double bar = 2;

  /// 9. Icon tile inside a settings row.
  static const double iconTile = 9;

  /// 14. Chips, search fields and hour cells.
  static const double chip = 14;

  /// 16. Buttons and the alert banner.
  static const double button = 16;

  /// 18. List rows.
  static const double row = 18;

  /// 22. Cards. The most common radius in the design.
  static const double card = 22;

  /// 26. Full-width panels.
  static const double panel = 26;

  /// 999. Pills, capsule buttons and toggles.
  static const double pill = 999;
}

/// Fixed component dimensions taken from the design.
abstract final class AuraSizes {
  /// Design canvas width. Layouts scale from this reference.
  static const double referenceWidth = 393;

  /// Metric card, 172 by 116.
  static const Size metricCard = Size(172, 116);

  /// City card, 400 by 116.
  static const Size cityCard = Size(400, 116);

  /// Forecast day row height.
  static const double forecastRowHeight = 54;

  /// Toggle, 46 by 28, with a 22-point knob.
  static const Size toggle = Size(46, 28);

  /// Toggle knob diameter.
  static const double toggleKnob = 22;

  /// Range bar track height.
  static const double rangeBarHeight = 6;

  /// Scale bar height under a UV metric card.
  static const double scaleBarHeight = 4;

  /// Condition icon, on the hero and in hour cells.
  static const double iconCondition = 26;

  /// Condition icon in a compact row.
  static const double iconConditionSmall = 22;

  /// Metric and UI icon.
  static const double iconUi = 18;

  /// Small metric icon inside a label row.
  static const double iconLabel = 15;

  /// Live pill indicator dot.
  static const double liveDot = 7;
}
