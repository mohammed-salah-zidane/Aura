import 'package:flutter/animation.dart';

/// Motion tokens.
///
/// The sky is the app's largest surface, so its transition is the one piece of
/// motion that has to feel deliberate. Everything else is short and quiet.
abstract final class AuraMotion {
  /// Sky gradient crossfade when the condition changes.
  static const Duration sky = Duration(milliseconds: 600);

  /// Content settling in after data arrives.
  static const Duration content = Duration(milliseconds: 300);

  /// Press and toggle feedback.
  static const Duration control = Duration(milliseconds: 180);

  /// One full pass of a loading shimmer.
  static const Duration shimmer = Duration(milliseconds: 1400);

  /// Curve for the sky transition and for content settling.
  static const Curve skyCurve = Curves.easeOutCubic;

  /// Curve for a control responding to touch.
  static const Curve controlCurve = Curves.easeOut;
}
