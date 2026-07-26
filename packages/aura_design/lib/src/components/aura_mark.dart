import 'package:aura_design/src/tokens/aura_colors.dart';
import 'package:aura_design/src/tokens/aura_gradients.dart';
import 'package:flutter/widgets.dart';

/// The Aura mark: a glowing orb inside two concentric rings.
///
/// Geometry is expressed as fractions of the 64-point design size, so the mark
/// stays true at every scale the design uses, from a 24-point brand bar to the
/// 132-point splash.
class AuraMark extends StatelessWidget {
  /// Creates the mark at [size] points square.
  const AuraMark({this.size = referenceSize, super.key});

  /// The size the mark is specified at in the design.
  static const double referenceSize = 64;

  /// Rendered width and height.
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: const CustomPaint(painter: _AuraMarkPainter()),
    );
  }
}

class _AuraMarkPainter extends CustomPainter {
  const _AuraMarkPainter();

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
  static const double _ringStroke = 1.8 / 64;

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
    final stroke = _ringStroke * unit;
    // An inner-aligned stroke sits wholly inside the ellipse, so the drawn
    // circle is pulled in by half the stroke width.
    final radius = (diameter * unit - stroke) / 2;
    canvas.drawCircle(
      Offset(
        inset * unit + diameter * unit / 2,
        inset * unit + diameter * unit / 2,
      ),
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
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
  bool shouldRepaint(_AuraMarkPainter oldDelegate) => false;
}
