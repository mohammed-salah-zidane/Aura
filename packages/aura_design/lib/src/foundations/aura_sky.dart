import 'dart:async';

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
///
/// Each sky carries both fills its frame declares in `aura.pen` — a vertical
/// [gradient] and the [bloom] above it.
enum AuraSkyKind {
  /// Clear day. Warms towards the horizon.
  clearDay(AuraSkies.clearDay, AuraBlooms.clearDay),

  /// Partly cloudy.
  partlyCloudy(AuraSkies.partlyCloudy, AuraBlooms.partlyCloudy),

  /// Overcast.
  overcast(AuraSkies.overcast, AuraBlooms.overcast),

  /// Rain.
  rain(AuraSkies.rain, AuraBlooms.rain),

  /// Thunderstorm.
  thunderstorm(AuraSkies.thunderstorm, AuraBlooms.thunderstorm),

  /// Snow.
  snow(AuraSkies.snow, AuraBlooms.snow),

  /// Clear night. The only sky that carries a starfield.
  clearNight(AuraSkies.clearNight, AuraBlooms.clearNight, hasStars: true),

  /// Fog.
  fog(AuraSkies.fog, AuraBlooms.fog),

  /// Brand sky, for screens no single condition owns.
  systemBrand(AuraSkies.systemBrand, AuraBlooms.systemBrand),

  /// Dark instrument dashboard.
  instrument(AuraSkies.instrument, AuraBlooms.instrument),

  /// Splash.
  splash(AuraSkies.splash, AuraBlooms.splash),

  /// Weather alert detail.
  weatherAlert(AuraSkies.weatherAlert, AuraBlooms.weatherAlert),

  /// Sun and moon detail.
  sunAndMoon(AuraSkies.sunAndMoon, AuraBlooms.sunAndMoon);

  const AuraSkyKind(this.gradient, this.bloom, {this.hasStars = false});

  /// The vertical gradient this sky paints. The frame's first fill.
  final AuraGradient gradient;

  /// The radial wash painted over [gradient]. The frame's second fill.
  final AuraBloom bloom;

  /// Whether the sky carries a starfield above its fills.
  final bool hasStars;
}

/// Paints a condition sky behind its child, crossfading when the sky changes.
///
/// Use this as the root of every screen. Both fills and the starfield are drawn
/// by one painter driven by one animation, so the layers cannot drift out of
/// step with each other mid-transition.
class AuraSky extends StatefulWidget {
  /// Creates a sky background.
  const AuraSky({required this.kind, this.child, super.key});

  /// Which sky to paint.
  final AuraSkyKind kind;

  /// Content drawn on top of the sky.
  final Widget? child;

  @override
  State<AuraSky> createState() => _AuraSkyState();
}

class _AuraSkyState extends State<AuraSky> with SingleTickerProviderStateMixin {
  late AuraSkyKind _from = widget.kind;
  late AuraSkyKind _to = widget.kind;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AuraMotion.sky,
    value: 1,
  );

  late final Animation<double> _progress = CurvedAnimation(
    parent: _controller,
    curve: AuraMotion.skyCurve,
  );

  @override
  void didUpdateWidget(AuraSky oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.kind == _to) return;
    _from = _to;
    _to = widget.kind;
    unawaited(_controller.forward(from: 0));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _progress,
      builder: (context, child) => CustomPaint(
        painter: _SkyPainter(from: _from, to: _to, progress: _progress.value),
        child: child,
      ),
      child: widget.child,
    );
  }
}

/// Paints both of a sky's fills, and the starfield when one side has it.
class _SkyPainter extends CustomPainter {
  const _SkyPainter({
    required this.from,
    required this.to,
    required this.progress,
  });

  final AuraSkyKind from;
  final AuraSkyKind to;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    _paintGradient(canvas, rect);
    _paintBloom(canvas, rect);
    _paintStars(canvas, size);
  }

  /// The vertical fill. Stop counts differ between skies — clear day has five,
  /// overcast three — so this leans on `LinearGradient.lerp`, which resamples
  /// both sides onto a shared set of stops rather than pairing them by index.
  void _paintGradient(Canvas canvas, Rect rect) {
    final blended = LinearGradient.lerp(
      _linear(from.gradient),
      _linear(to.gradient),
      progress,
    )!;
    canvas.drawRect(rect, Paint()..shader = blended.createShader(rect));
  }

  static LinearGradient _linear(AuraGradient gradient) => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: gradient.colors,
    stops: gradient.stops,
  );

  /// The radial fill, drawn as an ellipse by scaling a unit circle.
  ///
  /// The pen's ellipse is wider than the frame on nearly every sky, so a
  /// circular `RadialGradient` cannot express it. Every bloom has two stops and
  /// is transparent at the outer one, so the two sides interpolate pairwise and
  /// clipping the draw to the ellipse loses nothing.
  void _paintBloom(Canvas canvas, Rect rect) {
    final a = from.bloom;
    final b = to.bloom;
    final t = progress;

    final radiusX = _lerp(a.widthFactor, b.widthFactor, t) * rect.width / 2;
    final radiusY = _lerp(a.heightFactor, b.heightFactor, t) * rect.height / 2;
    if (radiusX <= 0 || radiusY <= 0) return;

    final opacity = _lerp(a.opacity, b.opacity, t);
    final colors = <Color>[
      for (var i = 0; i < a.colors.length; i++)
        _blendStop(a.colors[i], b.colors[i], t, opacity),
    ];
    final stops = <double>[
      for (var i = 0; i < a.stops.length; i++) _lerp(a.stops[i], b.stops[i], t),
    ];

    final shader = RadialGradient(colors: colors, stops: stops).createShader(
      Rect.fromCircle(center: Offset.zero, radius: 1),
    );

    canvas
      ..save()
      ..translate(
        rect.left + _lerp(a.centerX, b.centerX, t) * rect.width,
        rect.top + _lerp(a.centerY, b.centerY, t) * rect.height,
      )
      ..scale(radiusX, radiusY)
      ..drawCircle(Offset.zero, 1, Paint()..shader = shader)
      ..restore();
  }

  /// One bloom stop, with the fill layer's own opacity folded into its alpha.
  ///
  /// The layer is a single draw, so multiplying alpha is what a layer opacity
  /// would do and costs no save-layer.
  static Color _blendStop(Color a, Color b, double t, double opacity) {
    final blended = Color.lerp(a, b, t)!;
    return blended.withValues(alpha: blended.a * opacity);
  }

  /// Stars belong to the clear-night sky alone, so their alpha follows the side
  /// of the transition that carries them.
  void _paintStars(Canvas canvas, Size size) {
    final alpha =
        (from.hasStars ? 1 - progress : 0.0) + (to.hasStars ? progress : 0.0);
    if (alpha <= 0) return;

    final scaleX = size.width / AuraSizes.referenceWidth;
    final scaleY = size.height / AuraSizes.referenceHeight;
    final paint = Paint();
    for (final star in _Star.field) {
      paint.color = AuraColors.starfield.withValues(
        alpha: star.opacity * alpha,
      );
      final radius = star.diameter / 2;
      canvas.drawCircle(
        Offset((star.x + radius) * scaleX, (star.y + radius) * scaleY),
        radius,
        paint,
      );
    }
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  @override
  bool shouldRepaint(_SkyPainter oldDelegate) =>
      oldDelegate.from != from ||
      oldDelegate.to != to ||
      oldDelegate.progress != progress;
}

/// One star of the clear-night field.
///
/// [x] and [y] are the pen's top-left corner on the 393 by 852 design canvas,
/// held against it as a fraction so the field keeps its composition on any
/// screen size.
class _Star {
  const _Star(this.x, this.y, this.diameter, this.opacity);

  /// Left edge on the design canvas.
  final double x;

  /// Top edge on the design canvas.
  final double y;

  /// Star diameter.
  final double diameter;

  /// Star opacity.
  final double opacity;

  /// Read from the eleven `Star` nodes of the clear-night frame.
  static const List<_Star> field = <_Star>[
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
}
