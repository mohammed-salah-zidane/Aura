import 'dart:math' show pi;

import 'package:aura_design/src/tokens/aura_colors.dart';
import 'package:aura_design/src/tokens/aura_gradients.dart';
import 'package:flutter/widgets.dart';

/// The sizes the design draws the Aura mark at.
///
/// Every other piece of the mark's geometry scales with its box, but the ring
/// stroke does not: `aura.pen` authors it at 1 for both small marks, 1.8 on the
/// 64-point component and 2.64 on the splash. No single fraction reproduces all
/// four, so the size is a closed set rather than a free number, and a call site
/// cannot invent one.
enum AuraMarkSize {
  /// 24. Beside the hero condition on a weather screen.
  hero(24, 1),

  /// 26. In the brand bar above the hero.
  brandBar(26, 1),

  /// 64. The size the design system sheet specifies the component at.
  reference(64, 1.8),

  /// 132. The splash screen.
  splash(132, 2.64);

  const AuraMarkSize(this.diameter, this.ringStroke);

  /// Width and height of the mark's box.
  final double diameter;

  /// Width of the two concentric ring strokes at this size.
  final double ringStroke;
}

/// The Aura mark: a glowing orb inside two concentric rings.
///
/// Geometry is expressed as fractions of the 64-point design size, so the mark
/// holds its proportions at every size the design uses.
class AuraMark extends StatelessWidget {
  /// Creates the mark at one of the sizes the design specifies.
  const AuraMark({
    this.size = AuraMarkSize.reference,
    this.reveal = 1,
    this.glow = 1,
    super.key,
  });

  /// Which of the design's sizes to draw.
  final AuraMarkSize size;

  /// How much of the mark has arrived, from 0 to 1.
  ///
  /// At 1 this is the mark exactly as the pen draws it, which is the only
  /// state any screen rests in. Below 1 the rings are part-swept and the core
  /// is part-faded, which the splash uses to bring the mark out of the dark.
  final double reveal;

  /// Multiplier on the glow's radius, for the breath the splash runs.
  ///
  /// The glow is the one part of the mark that can move without the mark
  /// looking like it changed size, because it has no edge.
  final double glow;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size.diameter,
      child: CustomPaint(
        painter: _AuraMarkPainter(
          ringStroke: size.ringStroke,
          reveal: reveal,
          glow: glow,
        ),
      ),
    );
  }
}

class _AuraMarkPainter extends CustomPainter {
  const _AuraMarkPainter({
    required this.ringStroke,
    required this.reveal,
    required this.glow,
  });

  /// Ring stroke in points, authored per size rather than scaled.
  final double ringStroke;

  /// How much of the mark has arrived.
  final double reveal;

  /// Multiplier on the glow radius.
  final double glow;

  /// The outer ring finishes sweeping before the inner one starts.
  static const double _outerRingEnd = 0.7;
  static const double _midRingStart = 0.45;

  /// The core fades in over the back half, behind both rings.
  static const double _coreStart = 0.5;

  // Fractions of the 64-point reference, read from the Mark component.
  static const double _outerInset = 5.3 / 64;
  static const double _outerDiameter = 53.3 / 64;
  static const double _midInset = 12 / 64;
  static const double _midDiameter = 40 / 64;
  static const double _coreInset = 19.5 / 64;
  static const double _coreDiameter = 25 / 64;
  static const double _specX = 25.6 / 64;
  static const double _specY = 21.8 / 64;
  static const double _specDiameter = 6.4 / 64;

  /// The core's highlight sits up and to the left of centre, which is what
  /// makes the orb read as lit rather than flat.
  static const Alignment _coreFocal = Alignment(-0.24, -0.36);

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.shortestSide;
    final core = _phase(_coreStart, 1);

    _paintGlow(canvas, unit);
    _paintRing(
      canvas,
      unit,
      inset: _outerInset,
      diameter: _outerDiameter,
      opacity: 0.6,
      sweep: _phase(0, _outerRingEnd),
    );
    _paintRing(
      canvas,
      unit,
      inset: _midInset,
      diameter: _midDiameter,
      opacity: 0.85,
      sweep: _phase(_midRingStart, 1),
    );
    if (core <= 0) return;
    _paintCore(canvas, unit, core);
    _paintSpecular(canvas, unit, core);
  }

  /// Where [reveal] sits inside one leg of the sequence, clamped to 0 to 1.
  double _phase(double start, double end) =>
      ((reveal - start) / (end - start)).clamp(0.0, 1.0);

  void _paintGlow(Canvas canvas, double unit) {
    final radius = unit / 2 * glow;
    final centre = Offset(unit / 2, unit / 2);
    final rect = Rect.fromCircle(center: centre, radius: radius);
    canvas.drawCircle(
      centre,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            for (final color in AuraGradients.markGlow.colors)
              color.withValues(alpha: color.a * reveal),
          ],
          stops: AuraGradients.markGlow.stops,
        ).createShader(rect),
    );
  }

  /// One ring, drawn as an arc so it can sweep on from the top.
  ///
  /// A full circle and a full-turn arc rasterise identically, so the resting
  /// mark is unchanged by this being an arc rather than a circle.
  void _paintRing(
    Canvas canvas,
    double unit, {
    required double inset,
    required double diameter,
    required double opacity,
    required double sweep,
  }) {
    if (sweep <= 0) return;
    // An inner-aligned stroke sits wholly inside the ellipse, so the drawn
    // circle is pulled in by half the stroke width.
    final radius = (diameter * unit - ringStroke) / 2;
    final centre = Offset(
      inset * unit + diameter * unit / 2,
      inset * unit + diameter * unit / 2,
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = ringStroke
      ..color = AuraColors.auraRing.withValues(alpha: opacity);

    if (sweep >= 1) {
      canvas.drawCircle(centre, radius, paint);
      return;
    }
    canvas.drawArc(
      Rect.fromCircle(center: centre, radius: radius),
      -_quarterTurn,
      _fullTurn * sweep,
      false,
      paint,
    );
  }

  void _paintCore(Canvas canvas, double unit, double opacity) {
    final rect = Rect.fromLTWH(
      _coreInset * unit,
      _coreInset * unit,
      _coreDiameter * unit,
      _coreDiameter * unit,
    );
    canvas.drawCircle(
      rect.center,
      rect.width / 2,
      Paint()
        ..shader = RadialGradient(
          center: _coreFocal,
          colors: <Color>[
            for (final color in AuraGradients.markCore.colors)
              color.withValues(alpha: color.a * opacity),
          ],
          stops: AuraGradients.markCore.stops,
        ).createShader(rect),
    );
  }

  void _paintSpecular(Canvas canvas, double unit, double opacity) {
    final diameter = _specDiameter * unit;
    canvas.drawCircle(
      Offset(_specX * unit + diameter / 2, _specY * unit + diameter / 2),
      diameter / 2,
      Paint()
        ..color = AuraColors.auraSpecular.withValues(
          alpha: AuraColors.auraSpecular.a * opacity,
        ),
    );
  }

  static const double _fullTurn = 2 * pi;
  static const double _quarterTurn = pi / 2;

  @override
  bool shouldRepaint(_AuraMarkPainter oldDelegate) =>
      oldDelegate.ringStroke != ringStroke ||
      oldDelegate.reveal != reveal ||
      oldDelegate.glow != glow;
}
