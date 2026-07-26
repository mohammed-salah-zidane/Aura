import 'package:aura_design/src/tokens/aura_colors.dart';
import 'package:aura_design/src/tokens/aura_gradients.dart';
import 'package:aura_design/src/tokens/aura_metrics.dart';
import 'package:aura_design/src/tokens/aura_motion.dart';
import 'package:flutter/widgets.dart';

/// Which sky a screen paints.
///
/// In Aura the background *is* the weather, so the sky is a first-class piece
/// of state rather than decoration. This enum stays purely visual: mapping a
/// weather condition onto a sky belongs to the feature layer, which keeps the
/// design system free of any domain knowledge.
enum AuraSkyKind {
  /// Clear day. Warms towards the horizon.
  clearDay(AuraSkies.clearDay),

  /// Partly cloudy.
  partlyCloudy(AuraSkies.partlyCloudy),

  /// Overcast.
  overcast(AuraSkies.overcast),

  /// Rain.
  rain(AuraSkies.rain),

  /// Thunderstorm.
  thunderstorm(AuraSkies.thunderstorm),

  /// Snow.
  snow(AuraSkies.snow),

  /// Clear night. The only sky that carries a starfield.
  clearNight(AuraSkies.clearNight, hasStars: true),

  /// Fog.
  fog(AuraSkies.fog),

  /// Brand sky, for screens no single condition owns.
  systemBrand(AuraSkies.systemBrand),

  /// Dark instrument dashboard.
  instrument(AuraSkies.instrument),

  /// Splash.
  splash(AuraSkies.splash),

  /// Weather alert detail.
  weatherAlert(AuraSkies.weatherAlert),

  /// Sun and moon detail.
  sunAndMoon(AuraSkies.sunAndMoon);

  const AuraSkyKind(this.gradient, {this.hasStars = false});

  /// The gradient this sky paints.
  final AuraGradient gradient;

  /// Whether the sky carries a starfield above the gradient.
  final bool hasStars;
}

/// Paints a condition sky behind its child, crossfading when the sky changes.
///
/// Use this as the root of every screen. The gradient is painted directly
/// rather than through a `DecoratedBox` so the crossfade animates the stops
/// themselves instead of cross-dissolving two opaque layers.
class AuraSky extends StatelessWidget {
  /// Creates a sky background.
  const AuraSky({required this.kind, this.child, super.key});

  /// Which sky to paint.
  final AuraSkyKind kind;

  /// Content drawn on top of the sky.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AuraMotion.sky,
      curve: AuraMotion.skyCurve,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: kind.gradient.colors,
          stops: kind.gradient.stops,
        ),
      ),
      child: kind.hasStars ? _Starfield(child: child) : child,
    );
  }
}

/// The eleven stars the design places on the clear-night sky.
class _Starfield extends StatelessWidget {
  const _Starfield({this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: const _StarfieldPainter(),
      child: child,
    );
  }
}

/// One star, positioned as a fraction of the design canvas so the field holds
/// its composition on any screen size.
class _Star {
  const _Star(this.dx, this.dy, this.diameter, this.opacity);

  /// Horizontal position on the 393-point design canvas.
  final double dx;

  /// Vertical position on the 852-point design canvas.
  final double dy;

  /// Star diameter.
  final double diameter;

  /// Star opacity.
  final double opacity;
}

class _StarfieldPainter extends CustomPainter {
  const _StarfieldPainter();

  /// Read from the clear-night frame in `aura.pen`.
  static const List<_Star> _stars = <_Star>[
    _Star(30, 120, 3, 0.9),
    _Star(52, 150, 2, 0.55),
    _Star(64, 175, 2, 0.6),
    _Star(95, 222, 2, 0.5),
    _Star(110, 100, 2, 0.7),
    _Star(286, 150, 2, 0.5),
    _Star(300, 112, 3, 0.85),
    _Star(334, 214, 3, 0.8),
    _Star(342, 168, 2, 0.6),
    _Star(356, 224, 2, 0.6),
    _Star(360, 116, 2, 0.7),
  ];

  static const double _canvasHeight = 852;

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / AuraSizes.referenceWidth;
    final scaleY = size.height / _canvasHeight;
    final paint = Paint();
    for (final star in _stars) {
      paint.color = AuraColors.starfield.withValues(alpha: star.opacity);
      canvas.drawCircle(
        Offset(star.dx * scaleX, star.dy * scaleY),
        star.diameter / 2,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_StarfieldPainter oldDelegate) => false;
}
