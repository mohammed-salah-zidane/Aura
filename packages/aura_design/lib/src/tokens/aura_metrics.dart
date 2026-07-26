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

  /// 7. Between the loading dots on the splash screen.
  static const double xsPlus = 7;

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

  /// 26. Between the parts of the splash lockup.
  static const double xxlPlus = 26;

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

  /// 12. The note chip on a full-screen state.
  static const double note = 12;

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

  /// Design canvas height. Only absolutely-placed decoration needs it; laid-out
  /// content takes its height from the real screen.
  static const double referenceHeight = 852;

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

  /// Icon on the alert banner.
  static const double iconBanner = 20;

  /// Metric and UI icon.
  static const double iconUi = 18;

  /// Chevron on a card heading, and the glyph inside a settings row's tile.
  static const double iconSmall = 16;

  /// Glyph beside a note or a location kicker.
  static const double iconCaption = 12;

  /// Small metric icon inside a label row.
  static const double iconLabel = 15;

  /// Live pill indicator dot.
  static const double liveDot = 7;

  /// The circular settings button in the brand bar.
  static const double brandButton = 34;

  /// Glyph in the bottom bar.
  static const double iconBottomBar = 22;

  /// The filled glyph marking the current-location page in the bottom bar.
  static const double pagerCurrent = 13;

  /// A page dot in the bottom bar.
  static const double pagerDot = 7;

  /// The note chip's glyph on a full-screen state.
  static const double iconNote = 14;

  /// Marker on an index scale bar, and the width of its stroke.
  static const double scaleIndicator = 12;

  /// Stroke around that marker, so it reads against any band under it.
  static const double scaleIndicatorStroke = 2;

  /// Index scale bar on a card.
  static const double indexScaleHeight = 8;

  /// Index scale bar on a detail screen, where it carries end labels.
  static const double indexScaleHeightLarge = 10;

  /// Divider between the columns of the sun and moon card.
  static const double astroDividerHeight = 46;

  /// Splash loading dot.
  static const double splashDot = 6;

  /// Icon disc on a full-screen state.
  static const double stateIconDisc = 88;

  /// Icon inside that disc.
  static const double iconState = 36;

  /// Gap above the disc, inside the content padding.
  static const double stateHeadroom = 90;

  /// Measure the body copy on a full-screen state is set to.
  ///
  /// Narrower than the content width, so the paragraph breaks where the design
  /// breaks it rather than running the full 345 points.
  static const double stateBodyMeasure = 300;

  /// Gap below a full-screen state's actions.
  ///
  /// Measured from the screen edge, not the safe area: the design canvas is a
  /// 393 by 852 screen and runs under the home indicator, and the pen sets the
  /// secondary button against that edge on purpose.
  static const double stateBottomInset = 30;

  /// Gap from the bottom of the screen to the splash loader.
  ///
  /// The splash pins its loader and its attribution rather than laying them
  /// out, and the design canvas runs to the very bottom edge of the screen, so
  /// these are measured from that edge and not from the safe area.
  static const double splashLoaderInset = 94;

  /// Gap from the bottom of the screen to the splash attribution.
  static const double splashAttributionInset = 50;
}
