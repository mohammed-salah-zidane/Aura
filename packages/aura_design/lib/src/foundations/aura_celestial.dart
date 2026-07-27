import 'dart:math' show cos, pi, sin;

import 'package:aura_design/src/tokens/aura_colors.dart';
import 'package:flutter/widgets.dart';

/// Which body is riding the sky.
enum AuraCelestialBody {
  /// The sun.
  sun,

  /// The moon.
  moon,
}

/// A sun or a moon placed on the sky by how far through its crossing it is.
///
/// [position] runs 0 to 1 from rise to set and is worked out by the domain from
/// the times WeatherAPI returns. There is no elevation or azimuth in the
/// service to read, so the arc is geometry over the rise, the set and the local
/// clock rather than a reported angle, which is the same footing the sun path
/// chart on the detail screen already stands on.
@immutable
class AuraCelestial {
  /// Places [body] at [position] along its arc.
  const AuraCelestial({
    required this.body,
    required this.position,
    this.illumination = 1,
    this.isWaxing = true,
  });

  /// Which body to draw.
  final AuraCelestialBody body;

  /// How far through its crossing it is, from 0 at rise to 1 at set.
  final double position;

  /// How much of the moon's disc is lit, 0 to 1. Ignored for the sun.
  final double illumination;

  /// Whether the moon's lit fraction is growing, which decides its limb.
  final bool isWaxing;

  @override
  bool operator ==(Object other) =>
      other is AuraCelestial &&
      other.body == body &&
      other.position == position &&
      other.illumination == illumination &&
      other.isWaxing == isWaxing;

  @override
  int get hashCode => Object.hash(body, position, illumination, isWaxing);
}

/// Draws the sun or the moon onto a sky.
///
/// Nothing here is extracted: `aura.pen` draws no sun. What it is held to
/// instead is the same rule as the ambient weather, that every colour is a
/// token the pen already declares, plus one of its own: the sun is built out of
/// layered light rather than a soft disc, because a blurred circle on a
/// gradient reads as a smudge and not as a star.
///
/// The light layers composite additively. Real light accumulates, so a ray
/// crossing the corona brightens where they meet. `srcOver` would flatten that
/// into whichever layer landed last and lose the effect entirely.
///
/// The arc is **not** mirrored in a right-to-left script. Which way the sun
/// crosses the sky is a fact about the sky rather than a reading direction.
abstract final class AuraCelestialPainter {
  /// Paints [celestial] over [size], faded by [blend] and shimmering on
  /// [phase].
  static void paint(
    Canvas canvas,
    Size size,
    AuraCelestial celestial, {
    required double blend,
    required double phase,
  }) {
    final centre = _centreOf(size, celestial.position);
    // Low in the sky is dimmer, the way a rising sun is.
    final height = sin(celestial.position.clamp(0.0, 1.0) * pi);
    final lit = blend * (_horizonDim + (1 - _horizonDim) * height);
    if (lit <= 0) return;

    switch (celestial.body) {
      case AuraCelestialBody.sun:
        _paintSun(canvas, size, centre, lit, phase);
      case AuraCelestialBody.moon:
        _paintMoon(canvas, size, centre, lit, celestial);
    }
  }

  /// Where the body sits, as fractions of the frame.
  ///
  /// Public because the sky's bloom is painted from it too: the haze around
  /// the sun has to be centred on the sun, not on the point the pen fixed it
  /// at for a still.
  static Offset centreFraction(double position) {
    final t = position.clamp(0.0, 1.0);
    return Offset(
      _inset + t * (1 - 2 * _inset),
      _topFraction + (1 - sin(t * pi)) * _arcHeight,
    );
  }

  /// Where the body sits, on an arc that peaks at the middle of its crossing.
  static Offset _centreOf(Size size, double position) {
    final fraction = centreFraction(position);
    return Offset(fraction.dx * size.width, fraction.dy * size.height);
  }

  // ---- the sun -----------------------------------------------------------

  static void _paintSun(
    Canvas canvas,
    Size size,
    Offset centre,
    double lit,
    double phase,
  ) {
    final disc = size.width * _sunDisc;

    _paintRays(canvas, centre, disc, lit, phase);

    _paintGlow(
      canvas,
      centre,
      size.width * _sunCorona,
      <Color>[
        AuraColors.auraRing.withValues(alpha: 0.55 * lit),
        AuraColors.conditionSun.withValues(alpha: 0.3 * lit),
        AuraColors.conditionSun.withValues(alpha: 0),
      ],
      const <double>[0, 0.32, 1],
    );

    // The disc: white hot at the centre, cooling to the sun's own colour at
    // the limb. A single flat fill is the thing that reads as a sticker.
    canvas.drawCircle(
      centre,
      disc,
      Paint()
        ..blendMode = BlendMode.plus
        ..shader = RadialGradient(
          colors: <Color>[
            AuraColors.textPrimary.withValues(alpha: lit),
            AuraColors.auraRing.withValues(alpha: lit),
            AuraColors.conditionSun.withValues(alpha: 0.92 * lit),
            AuraColors.conditionSun.withValues(alpha: 0.55 * lit),
          ],
          stops: const <double>[0, 0.42, 0.82, 1],
        ).createShader(Rect.fromCircle(center: centre, radius: disc)),
    );
  }

  /// The spokes, as one path under one shader.
  ///
  /// Alternating lengths, and each breathing against its neighbours, so the
  /// corona has structure instead of being a uniform ring. One path and one
  /// draw: a shader per spoke would be sixteen shaders every frame.
  static void _paintRays(
    Canvas canvas,
    Offset centre,
    double disc,
    double lit,
    double phase,
  ) {
    final spin = phase * 2 * pi * _raySpin;
    final path = Path();

    for (var i = 0; i < _rayCount; i++) {
      final angle = spin + i * 2 * pi / _rayCount;
      final long = i.isEven;
      final breath = sin(phase * 2 * pi + i) * _rayBreath;
      final reach = disc * ((long ? _rayLong : _rayShort) + breath);
      final half = _rayHalfWidth * (long ? 1 : 0.7);

      path
        ..moveTo(
          centre.dx + cos(angle - half) * disc,
          centre.dy + sin(angle - half) * disc,
        )
        ..lineTo(centre.dx + cos(angle) * reach, centre.dy + sin(angle) * reach)
        ..lineTo(
          centre.dx + cos(angle + half) * disc,
          centre.dy + sin(angle + half) * disc,
        )
        ..close();
    }

    final reach = disc * (_rayLong + _rayBreath);
    canvas.drawPath(
      path,
      Paint()
        ..blendMode = BlendMode.plus
        ..shader = RadialGradient(
          colors: <Color>[
            AuraColors.auraRing.withValues(alpha: 0.5 * lit),
            AuraColors.conditionSun.withValues(alpha: 0.22 * lit),
            AuraColors.conditionSun.withValues(alpha: 0),
          ],
          stops: const <double>[0, 0.4, 1],
        ).createShader(Rect.fromCircle(center: centre, radius: reach)),
    );
  }

  // ---- the moon ----------------------------------------------------------

  static void _paintMoon(
    Canvas canvas,
    Size size,
    Offset centre,
    double lit,
    AuraCelestial celestial,
  ) {
    final disc = size.width * _moonDisc;

    _paintGlow(
      canvas,
      centre,
      size.width * _moonHalo,
      <Color>[
        AuraColors.conditionMoon.withValues(alpha: 0.3 * lit),
        AuraColors.conditionMoon.withValues(alpha: 0),
      ],
      const <double>[0, 1],
    );

    // The lit disc and its shadow go on one layer, so clearing the terminator
    // takes back only the moon and not the sky behind it.
    canvas
      ..saveLayer(
        Rect.fromCircle(center: centre, radius: disc * 1.05),
        Paint(),
      )
      ..drawCircle(
        centre,
        disc,
        Paint()
          ..shader = RadialGradient(
            center: _moonFocal,
            colors: <Color>[
              AuraColors.conditionMoon.withValues(alpha: 0.95 * lit),
              AuraColors.conditionMoonPhase.withValues(alpha: 0.78 * lit),
            ],
            stops: const <double>[0, 1],
          ).createShader(Rect.fromCircle(center: centre, radius: disc)),
      );
    _paintTerminator(canvas, centre, disc, lit, celestial);
    canvas.restore();
  }

  /// The unlit part of the disc.
  ///
  /// The terminator is an ellipse whose width follows the illumination, which
  /// is what makes a gibbous moon bulge the opposite way to a crescent. Which
  /// limb it sits on follows whether the moon is waxing.
  static void _paintTerminator(
    Canvas canvas,
    Offset centre,
    double disc,
    double lit,
    AuraCelestial celestial,
  ) {
    final illumination = celestial.illumination.clamp(0.0, 1.0);
    if (illumination >= 1) return;

    final shadow = Paint()
      ..color = AuraColors.moonShadow.withValues(alpha: 0.92 * lit);

    canvas
      ..save()
      ..clipPath(Path()..addOval(Rect.fromCircle(center: centre, radius: disc)))
      // The limb that is certainly dark: the leading one while waxing.
      ..drawRect(
        Rect.fromLTWH(
          celestial.isWaxing ? centre.dx - disc : centre.dx,
          centre.dy - disc,
          disc,
          disc * 2,
        ),
        shadow,
      );

    // Then the terminator, which either eats into the lit half below a half
    // moon or gives some of the dark half back above one.
    final width = disc * (1 - 2 * illumination).abs();
    final oval = Rect.fromCenter(
      center: centre,
      width: width * 2,
      height: disc * 2,
    );
    if (illumination > 0.5) {
      canvas.drawOval(
        oval,
        Paint()
          ..blendMode = BlendMode.clear
          ..color = AuraColors.transparent,
      );
    } else {
      canvas.drawOval(oval, shadow);
    }
    canvas.restore();
  }

  // ---- shared ------------------------------------------------------------

  static void _paintGlow(
    Canvas canvas,
    Offset centre,
    double radius,
    List<Color> colors,
    List<double> stops,
  ) {
    canvas.drawCircle(
      centre,
      radius,
      Paint()
        ..blendMode = BlendMode.plus
        ..shader = RadialGradient(colors: colors, stops: stops).createShader(
          Rect.fromCircle(center: centre, radius: radius),
        ),
    );
  }

  /// Where the arc begins and ends, and how high it reaches.
  ///
  /// The body stays in the top third and well inside the edges, so it reads as
  /// sky behind the content rather than as an element of it.
  /// The arc is deliberately shallow. A tall one drops the body onto the alert
  /// banner and the city name near sunrise and sunset, and a bright disc
  /// behind text is worse than a flatter path. The horizontal travel is what
  /// says the time of day; the height only has to keep it out of the content.
  static const double _inset = 0.17;
  static const double _topFraction = 0.045;
  static const double _arcHeight = 0.03;

  /// How dim the body is at the horizon, against its height at noon.
  static const double _horizonDim = 0.4;

  /// Sun geometry, as fractions of the frame width.
  ///
  /// There is no wide haze here on purpose. Every clear-day frame in the pen
  /// already carries a broad warm bloom as its second fill, and that bloom is
  /// the atmosphere around the sun. Adding another put two light sources on
  /// one sky, which read as a smear below a star rather than as daylight.
  static const double _sunDisc = 0.043;
  static const double _sunCorona = 0.11;

  /// Ray geometry, as multiples of the disc radius.
  static const int _rayCount = 16;
  static const double _rayLong = 3.1;
  static const double _rayShort = 2.1;
  static const double _rayBreath = 0.35;
  static const double _rayHalfWidth = 0.09;

  /// A full turn of the spokes takes many cycles, so it never reads as spin.
  static const double _raySpin = 0.06;

  /// Moon geometry, as fractions of the frame width.
  static const double _moonDisc = 0.052;
  static const double _moonHalo = 0.14;

  /// The moon's light sits up and to the left, as the mark's core does.
  static const Alignment _moonFocal = Alignment(-0.3, -0.35);
}
