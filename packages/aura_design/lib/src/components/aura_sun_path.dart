import 'package:aura_design/src/tokens/aura_colors.dart';
import 'package:aura_design/src/tokens/aura_gradients.dart';
import 'package:aura_design/src/tokens/aura_metrics.dart';
import 'package:flutter/widgets.dart';

/// The arc the sun travels between sunrise and sunset.
///
/// [position] is a fraction of the day worked out by the domain, so the chart
/// carries no arithmetic of its own. Passing null draws the empty arc, which is
/// what a polar day or a polar night looks like: the path exists, and nothing
/// is on it.
class AuraSunPath extends StatelessWidget {
  /// Creates a sun path.
  const AuraSunPath({required this.position, super.key});

  /// Where the sun is, from 0 at sunrise to 1 at sunset, or null.
  final double? position;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AuraSizes.sunChartHeight,
      child: CustomPaint(
        painter: _SunPathPainter(position: position),
        size: Size.infinite,
      ),
    );
  }
}

/// Paints the horizon, the arc, its end dots and the sun.
///
/// The pen authors the chart on a 321 by 118 box, and every coordinate below is
/// read from it and scaled onto whatever width the card actually has.
class _SunPathPainter extends CustomPainter {
  const _SunPathPainter({required this.position});

  final double? position;

  // The pen's own coordinates.
  static const double _designWidth = AuraSizes.sunChartWidth;
  static const double _riseX = 20;
  static const double _setX = 300;
  static const double _horizonY = 100;
  static const double _controlX = 160;
  static const double _controlY = -20;
  static const double _horizonInset = 16;
  static const double _arcStroke = 2.5;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / _designWidth;
    double x(double value) => value * scale;

    canvas.drawRect(
      Rect.fromLTWH(
        x(_horizonInset),
        _horizonY,
        size.width - x(_horizonInset) * 2,
        AuraSizes.divider,
      ),
      Paint()..color = AuraColors.border,
    );

    final arc = Path()
      ..moveTo(x(_riseX), _horizonY)
      ..quadraticBezierTo(x(_controlX), _controlY, x(_setX), _horizonY);
    canvas.drawPath(
      arc,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _arcStroke
        ..strokeCap = StrokeCap.round
        ..color = AuraColors.sunPath,
    );

    final marker = Paint()..color = AuraColors.sunPathMarker;
    const markerRadius = AuraSizes.sunPathMarker / 2;
    canvas
      ..drawCircle(Offset(x(_riseX), _horizonY), markerRadius, marker)
      ..drawCircle(Offset(x(_setX), _horizonY), markerRadius, marker);

    final travelled = position;
    if (travelled == null) return;
    _paintSun(canvas, _pointOn(travelled, scale));
  }

  /// The quadratic the pen authors, evaluated at [t].
  Offset _pointOn(double t, double scale) {
    final clamped = t.clamp(0.0, 1.0);
    final inverse = 1 - clamped;
    final x =
        inverse * inverse * _riseX +
        2 * inverse * clamped * _controlX +
        clamped * clamped * _setX;
    final y =
        inverse * inverse * _horizonY +
        2 * inverse * clamped * _controlY +
        clamped * clamped * _horizonY;
    return Offset(x * scale, y);
  }

  void _paintSun(Canvas canvas, Offset center) {
    final glow = Rect.fromCenter(
      center: center,
      width: AuraSizes.sunGlow,
      height: AuraSizes.sunGlow,
    );
    canvas.drawCircle(
      center,
      AuraSizes.sunGlow / 2,
      Paint()
        ..shader = RadialGradient(
          colors: AuraGradients.sunGlow.colors,
          stops: AuraGradients.sunGlow.stops,
        ).createShader(glow),
    );

    final disc = Rect.fromCenter(
      center: center,
      width: AuraSizes.sunDisc,
      height: AuraSizes.sunDisc,
    );
    canvas.drawCircle(
      center,
      AuraSizes.sunDisc / 2,
      Paint()
        ..shader = RadialGradient(
          center: _coreFocal,
          colors: AuraGradients.sunCore.colors,
          stops: AuraGradients.sunCore.stops,
        ).createShader(disc),
    );
  }

  /// The same off-centre highlight the Aura mark's core carries.
  static const Alignment _coreFocal = Alignment(-0.24, -0.36);

  @override
  bool shouldRepaint(_SunPathPainter oldDelegate) =>
      oldDelegate.position != position;
}
