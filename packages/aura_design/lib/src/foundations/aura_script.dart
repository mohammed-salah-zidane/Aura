import 'package:flutter/widgets.dart';

/// Adapts a type token to the script it is about to be drawn in.
extension AuraScript on TextStyle {
  /// Drops letter tracking when the text runs right to left.
  ///
  /// Arabic is cursive. Its letters join, and the tracking that reads as
  /// refinement on a Latin small-caps label prises those joins apart, so the
  /// word renders as a row of disconnected shapes. Thirteen styles in the scale
  /// carry tracking, and every one of them can meet Arabic copy.
  ///
  /// Apply this wherever a tracked token is given a localized string. A style
  /// with no tracking is returned untouched, so it is safe on any token, and
  /// the identical instance comes back so `const` widgets stay cached.
  TextStyle forScript(BuildContext context) =>
      Directionality.of(context) == TextDirection.rtl &&
          (letterSpacing ?? 0) != 0
      ? copyWith(letterSpacing: 0)
      : this;
}
