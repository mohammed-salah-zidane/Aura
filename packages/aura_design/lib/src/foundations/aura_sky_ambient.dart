import 'dart:math' show pi, sin;
import 'dart:ui';

import 'package:aura_design/src/tokens/aura_colors.dart';

/// What kind of marks a sky's ambient layer draws.
enum AuraAmbientKind {
  /// Nothing moves. The sky is its two fills and no more.
  none,

  /// The light itself breathes, with no marks drawn over it.
  breath,

  /// Points fading in and out on their own phases.
  twinkle,

  /// Wide soft bands drifting sideways.
  drift,

  /// Slanted lines falling.
  rain,

  /// Points descending with a lateral sway.
  snow,
}

/// The moving layer a sky carries over its two fills.
///
/// `aura.pen` authors none of this: the design is a still, and a still cannot
/// say what rain does. What the pen *does* author is every colour below, so the
/// constraint this layer is held to is that it introduces no new colour. Count,
/// size and speed are the only new values, and they are named here rather than
/// at a call site.
class AuraAmbient {
  /// Creates an ambient layer.
  const AuraAmbient({
    required this.kind,
    this.color = AuraColors.transparent,
    this.count = 0,
    this.opacity = 0,
    this.length = 0,
    this.thickness = 0,
    this.slant = 0,
    this.speed = 1,
    this.sway = 0,
    this.flash = 0,
  });

  /// A sky with nothing moving over it.
  static const AuraAmbient still = AuraAmbient(kind: AuraAmbientKind.none);

  /// Which marks to draw.
  final AuraAmbientKind kind;

  /// The mark colour. Always a token already read from the pen.
  final Color color;

  /// How many marks are on screen at once.
  final int count;

  /// Peak alpha of a mark.
  final double opacity;

  /// Mark length, as a fraction of the canvas height.
  final double length;

  /// Mark thickness in points, or point diameter for [AuraAmbientKind.snow].
  final double thickness;

  /// Horizontal drift over one fall, as a fraction of the canvas width.
  final double slant;

  /// How many cycles a mark completes per full phase turn.
  final double speed;

  /// Lateral sway amplitude, as a fraction of the canvas width.
  final double sway;

  /// Peak alpha of a full-canvas flash, or zero for a sky that does not flash.
  final double flash;
}

/// The ambient layer of each sky.
///
/// These are tuned to be **seen**. The weather is the reason the app exists, so
/// the sky saying what it is doing is the app working rather than decoration
/// competing with the content. The ceiling is legibility: the hero temperature
/// and the card copy sit directly on this, so a mark may be obvious and must
/// never be dense enough to read through.
abstract final class AuraAmbients {
  /// Clear day. The haze over the horizon breathes; nothing is drawn over it.
  static const AuraAmbient clearDay = AuraAmbient(
    kind: AuraAmbientKind.breath,
    color: AuraColors.conditionSun,
    opacity: 0.16,
    speed: 1.4,
  );

  /// Clear night. The eleven stars the pen draws, fading on their own phases.
  static const AuraAmbient clearNight = AuraAmbient(
    kind: AuraAmbientKind.twinkle,
    color: AuraColors.starfield,
    opacity: 0.75,
    speed: 1.6,
  );

  /// Partly cloudy. Two washes crossing.
  static const AuraAmbient partlyCloudy = AuraAmbient(
    kind: AuraAmbientKind.drift,
    color: AuraColors.conditionCloudSun,
    count: 3,
    opacity: 0.18,
    length: 0.18,
    speed: 0.85,
  );

  /// Overcast. Four washes, wider and slower than partly cloudy.
  static const AuraAmbient overcast = AuraAmbient(
    kind: AuraAmbientKind.drift,
    color: AuraColors.conditionCloud,
    count: 4,
    opacity: 0.2,
    length: 0.24,
    speed: 0.6,
  );

  /// Fog. The softest of the set, and the slowest.
  static const AuraAmbient fog = AuraAmbient(
    kind: AuraAmbientKind.drift,
    color: AuraColors.conditionCloudFog,
    count: 3,
    opacity: 0.17,
    length: 0.32,
    speed: 0.45,
  );

  /// Rain. Slanted streaks, sparse enough to read through.
  static const AuraAmbient rain = AuraAmbient(
    kind: AuraAmbientKind.rain,
    color: AuraColors.conditionCloudRain,
    count: 60,
    opacity: 0.42,
    length: 0.085,
    thickness: 1.4,
    slant: 0.055,
    speed: 1.8,
  );

  /// Thunderstorm. Rain driven harder, plus the flash.
  static const AuraAmbient thunderstorm = AuraAmbient(
    kind: AuraAmbientKind.rain,
    color: AuraColors.conditionCloudRain,
    count: 84,
    opacity: 0.48,
    length: 0.11,
    thickness: 1.6,
    slant: 0.1,
    speed: 2.6,
    flash: 0.22,
  );

  /// Snow. Slow, with a sway that keeps it from falling in columns.
  static const AuraAmbient snow = AuraAmbient(
    kind: AuraAmbientKind.snow,
    color: AuraColors.conditionSnowflake,
    count: 68,
    opacity: 0.8,
    thickness: 4.4,
    speed: 0.45,
    sway: 0.06,
  );

  /// The colour a thunderstorm's flash washes the canvas with.
  static const Color flashColor = AuraColors.conditionZap;
}

/// Where one mark of an ambient layer sits at a given phase.
///
/// Positions come from the mark's index rather than from a random source, so
/// the same phase always produces the same frame. That is what lets a golden
/// hold this layer, and it also means the field allocates nothing per frame.
abstract final class AuraAmbientField {
  /// A stable value in 0 to 1 derived from [index] and [salt].
  ///
  /// A hash, not a random number, so a frame can be reproduced. It has to be a
  /// **mixing** one: multiply-and-mask alone advances by a fixed step, which
  /// puts every mark on one straight line across the screen. The shift-multiply
  /// rounds below are what break that up.
  static double scatter(int index, int salt) {
    var x = (index * 0x9E3779B1 + salt * 0x85EBCA77) & _mask;
    x ^= x >> 16;
    x = (x * 0x7FEB352D) & _mask;
    x ^= x >> 15;
    x = (x * 0x846CA68B) & _mask;
    x ^= x >> 16;
    return x / (_mask + 1);
  }

  /// Dart integers are 64 bit, so the hash is held to 32 by hand.
  static const int _mask = 0xFFFFFFFF;

  /// How far through its own cycle mark [index] is at [phase].
  ///
  /// Each mark carries a fixed offset, so they do not arrive in step.
  static double progress(int index, double phase, {int salt = 0}) {
    final value = phase + scatter(index, salt);
    return value - value.floorToDouble();
  }

  /// A sway or breath value in -1 to 1 for [index] at [phase].
  static double wave(int index, double phase, {int salt = 0}) =>
      sin(progress(index, phase, salt: salt) * 2 * pi);
}
