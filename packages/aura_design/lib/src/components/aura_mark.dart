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
  const AuraMark({this.size = AuraMarkSize.reference, super.key});

  /// Which of the design's sizes to draw.
  final AuraMarkSize size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size.diameter,
      child: CustomPaint(painter: _AuraMarkPainter(size.ringStroke)),
    );
  }
}

class _AuraMarkPainter extends CustomPainter {
  const _AuraMarkPainter(this.ringStroke);

  /// Ring stroke in points, authored per size rather than scaled.
  final double ringStroke;

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

    _paintGlow(canvas, unit);
    _paintRing(
      canvas,
      unit,
      inset: _outerInset,
      diameter: _outerDiameter,
      opacity: 0.6,
    );
    _paintRing(
      canvas,
      unit,
      inset: _midInset,
      diameter: _midDiameter,
      opacity: 0.85,
    );
    _paintCore(canvas, unit);
    _paintSpecular(canvas, unit);
  }

  void _paintGlow(Canvas canvas, double unit) {
    final rect = Rect.fromLTWH(0, 0, unit, unit);
    canvas.drawCircle(
      rect.center,
      unit / 2,
      Paint()
        ..shader = RadialGradient(
          colors: AuraGradients.markGlow.colors,
          stops: AuraGradients.markGlow.stops,
        ).createShader(rect),
    );
  }

  void _paintRing(
    Canvas canvas,
    double unit, {
    required double inset,
    required double diameter,
    required double opacity,
  }) {
    // An inner-aligned stroke sits wholly inside the ellipse, so the drawn
    // circle is pulled in by half the stroke width.
    final radius = (diameter * unit - ringStroke) / 2;
    canvas.drawCircle(
      Offset(
        inset * unit + diameter * unit / 2,
        inset * unit + diameter * unit / 2,
      ),
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = ringStroke
        ..color = AuraColors.auraRing.withValues(alpha: opacity),
    );
  }

  void _paintCore(Canvas canvas, double unit) {
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
          colors: AuraGradients.markCore.colors,
          stops: AuraGradients.markCore.stops,
        ).createShader(rect),
    );
  }

  void _paintSpecular(Canvas canvas, double unit) {
    final diameter = _specDiameter * unit;
    canvas.drawCircle(
      Offset(_specX * unit + diameter / 2, _specY * unit + diameter / 2),
      diameter / 2,
      Paint()..color = AuraColors.auraSpecular,
    );
  }

  @override
  bool shouldRepaint(_AuraMarkPainter oldDelegate) =>
      oldDelegate.ringStroke != ringStroke;
}
