import 'package:flutter/widgets.dart';

/// Motion tokens.
///
/// The sky is the app's largest surface, so its transition is the one piece of
/// motion that has to feel deliberate. Everything else is short and quiet.
///
/// `aura.pen` authors no motion at all, so nothing here is extracted from it.
/// The rule the durations below are held to instead is that every animation
/// resolves to the composition the pen *does* author: motion is how a screen
/// arrives at its frame, never a change to the frame itself.
abstract final class AuraMotion {
  /// Sky gradient crossfade when the condition changes.
  static const Duration sky = Duration(milliseconds: 600);

  /// Content settling in after data arrives.
  static const Duration content = Duration(milliseconds: 300);

  /// Press and toggle feedback.
  static const Duration control = Duration(milliseconds: 180);

  /// One full pass of a loading shimmer.
  static const Duration shimmer = Duration(milliseconds: 1400);

  /// One section rising into place on the home screen.
  static const Duration entrance = Duration(milliseconds: 460);

  /// Delay between one section's entrance and the next.
  ///
  /// Wide enough that the cascade is legible as one section following another
  /// rather than the page fading in as a block.
  static const Duration entranceStagger = Duration(milliseconds: 75);

  /// How far a section is scaled down when it starts arriving.
  static const double entranceScale = 0.94;

  /// The splash mark blooming out of the dark.
  static const Duration splashReveal = Duration(milliseconds: 900);

  /// The wordmark and tagline resolving behind it.
  static const Duration splashSettle = Duration(milliseconds: 600);

  /// The splash lockup leaving, once the app knows where it is going.
  static const Duration splashExit = Duration(milliseconds: 320);

  /// One full breath of a glow or a bloom.
  ///
  /// Long on purpose. At this period the change between two consecutive frames
  /// is below what the eye resolves, so the light reads as alive rather than
  /// as animated.
  static const Duration breath = Duration(milliseconds: 5200);

  /// The sun or the moon sweeping its arc to now, on the first reading.
  ///
  /// Long enough to read as the day retraced rather than as a slide, and short
  /// enough that the content waiting on it never feels held back.
  static const Duration celestialArrival = Duration(milliseconds: 1400);

  /// The body easing to a new spot when the reading changes.
  static const Duration celestialShift = Duration(milliseconds: 600);

  /// One star's full fade cycle.
  static const Duration twinkle = Duration(milliseconds: 3400);

  /// How far a control shrinks under a finger.
  static const double pressScale = 0.98;

  /// How far a section travels as it rises into place.
  ///
  /// Far enough to read as arriving rather than as a flicker. Below the 24
  /// point gap between sections, so a card never overlaps the one above it on
  /// the way in.
  static const double entranceRise = 20;

  /// How far the splash wordmark travels as it resolves.
  static const double splashRise = 14;

  /// Points of scroll over which the hero condenses into the top bar.
  ///
  /// Slightly less than the hero's own height, so the choreography completes
  /// before the first card reaches the pinned bar.
  static const double heroCondenseRange = 200;

  /// Curve for the sky transition and for content settling.
  static const Curve skyCurve = Curves.easeOutCubic;

  /// Curve for a control responding to touch.
  static const Curve controlCurve = Curves.easeOut;

  /// Curve for a section arriving.
  static const Curve entranceCurve = Curves.easeOutCubic;

  /// Curve for anything that breathes or drifts, which has no start or end.
  static const Curve breathCurve = Curves.easeInOut;
}

/// Whether this view should animate.
///
/// Every repeating animation in the app asks before it starts. That is an
/// accessibility requirement first, and it is also what makes the goldens
/// deterministic: an animation that repeats forever never settles, so
/// `pumpAndSettle` hangs on a screen that has one.
///
/// The contract is **rest on the frame `aura.pen` draws**. Motion in this app
/// is only ever how a screen arrives at its frame, never a change to the frame,
/// so switching it off can always land on the design itself.
///
/// Decorative layers are dropped rather than frozen. The ambient weather marks
/// say nothing the gradient, the glyph and the condition text do not already
/// say, and a still rain field would be an artefact nobody designed. Anything
/// the pen does draw stays, at the value it draws it.
extension AuraMotionPreference on BuildContext {
  /// Whether the platform has asked for motion to be reduced.
  bool get prefersReducedMotion =>
      MediaQuery.maybeDisableAnimationsOf(this) ?? false;
}
