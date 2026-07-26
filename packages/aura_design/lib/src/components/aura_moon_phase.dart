import 'package:aura_design/src/tokens/aura_colors.dart';
import 'package:aura_design/src/tokens/aura_gradients.dart';
import 'package:aura_design/src/tokens/aura_metrics.dart';
import 'package:flutter/widgets.dart';

/// The moon, drawn at the phase the service reports.
///
/// The pen composes the crescent from three overlapping ellipses at one fixed
/// phase. Here the terminator is worked out from the illumination the service
/// returns, so every phase in the month draws correctly rather than one.
class AuraMoonPhase extends StatelessWidget {
  /// Creates a moon phase disc.
  const AuraMoonPhase({
    required this.illumination,
    required this.isWaxing,
    super.key,
  });

  /// How much of the disc is lit, from 0 at the new moon to 1 at the full.
  final double illumination;

  /// Whether the lit fraction is growing, which decides the limb it sits on.
  final bool isWaxing;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: AuraSizes.moonPhase,
      child: CustomPaint(
        painter: _MoonPhasePainter(
          illumination: illumination.clamp(0.0, 1.0),
          isWaxing: isWaxing,
        ),
      ),
    );
  }
}

class _MoonPhasePainter extends CustomPainter {
  const _MoonPhasePainter({
    required this.illumination,
    required this.isWaxing,
  });

  final double illumination;
  final bool isWaxing;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    const radius = AuraSizes.moonDisc / 2;

    canvas
      ..drawCircle(
        center,
        size.shortestSide / 2,
        Paint()
          ..shader = RadialGradient(
            colors: AuraGradients.moonGlow.colors,
            stops: AuraGradients.moonGlow.stops,
          ).createShader(Offset.zero & size),
      )
      ..drawCircle(center, radius, Paint()..color = AuraColors.moonShadow);

    final lit = _litFace(center, radius);
    if (lit == null) return;

    final disc = Rect.fromCircle(center: center, radius: radius);
    canvas.drawPath(
      lit,
      Paint()
        ..shader = RadialGradient(
          center: _litFocal,
          colors: AuraGradients.moonLit.colors,
          stops: AuraGradients.moonLit.stops,
        ).createShader(disc),
    );
  }

  /// The lit part of the disc.
  ///
  /// Half the disc is always either lit or dark; the terminator is the ellipse
  /// whose semi-axis is how far the boundary has swung from the limb. Below
  /// half illumination that ellipse is taken away from the half, and above it
  /// the ellipse is added, which is exactly a crescent and a gibbous.
  Path? _litFace(Offset center, double radius) {
    if (illumination <= 0) return null;

    final disc = Rect.fromCircle(center: center, radius: radius);
    if (illumination >= 1) return Path()..addOval(disc);

    final half = Path()
      ..addArc(
        disc,
        isWaxing ? -_quarterTurn : _quarterTurn,
        _halfTurn,
      )
      ..close();

    final terminator = Path()
      ..addOval(
        Rect.fromCenter(
          center: center,
          width: radius * 2 * (1 - 2 * illumination).abs(),
          height: radius * 2,
        ),
      );

    return Path.combine(
      illumination < 0.5 ? PathOperation.difference : PathOperation.union,
      half,
      terminator,
    );
  }

  /// A quarter turn in radians. `addArc` measures from the positive x axis.
  static const double _quarterTurn = 1.5707963267948966;

  /// A half turn in radians.
  static const double _halfTurn = 3.141592653589793;

  /// The lit face reads as a sphere rather than a disc when its highlight sits
  /// off centre, the same way the Aura mark's core does.
  static const Alignment _litFocal = Alignment(0.4, -0.2);

  @override
  bool shouldRepaint(_MoonPhasePainter oldDelegate) =>
      oldDelegate.illumination != illumination ||
      oldDelegate.isWaxing != isWaxing;
}
