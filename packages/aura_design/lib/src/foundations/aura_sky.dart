import 'dart:async';
import 'dart:math' show cos, pi;

import 'package:aura_design/src/foundations/aura_celestial.dart';
import 'package:aura_design/src/foundations/aura_sky_ambient.dart';
import 'package:aura_design/src/tokens/aura_colors.dart';
import 'package:aura_design/src/tokens/aura_gradients.dart';
import 'package:aura_design/src/tokens/aura_metrics.dart';
import 'package:aura_design/src/tokens/aura_motion.dart';
import 'package:flutter/services.dart';
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
  clearDay(AuraSkies.clearDay, AuraBlooms.clearDay, AuraAmbients.clearDay),

  /// Partly cloudy.
  partlyCloudy(
    AuraSkies.partlyCloudy,
    AuraBlooms.partlyCloudy,
    AuraAmbients.partlyCloudy,
  ),

  /// Overcast.
  overcast(AuraSkies.overcast, AuraBlooms.overcast, AuraAmbients.overcast),

  /// Rain.
  rain(AuraSkies.rain, AuraBlooms.rain, AuraAmbients.rain),

  /// Thunderstorm.
  thunderstorm(
    AuraSkies.thunderstorm,
    AuraBlooms.thunderstorm,
    AuraAmbients.thunderstorm,
  ),

  /// Snow.
  snow(AuraSkies.snow, AuraBlooms.snow, AuraAmbients.snow),

  /// Clear night. The only sky that carries a starfield.
  clearNight(
    AuraSkies.clearNight,
    AuraBlooms.clearNight,
    AuraAmbients.clearNight,
    hasStars: true,
  ),

  /// Fog.
  fog(AuraSkies.fog, AuraBlooms.fog, AuraAmbients.fog),

  /// Brand sky, for screens no single condition owns.
  systemBrand(
    AuraSkies.systemBrand,
    AuraBlooms.systemBrand,
    AuraAmbient.still,
  ),

  /// Dark instrument dashboard.
  instrument(
    AuraSkies.instrument,
    AuraBlooms.instrument,
    AuraAmbient.still,
  ),

  /// Splash.
  splash(AuraSkies.splash, AuraBlooms.splash, AuraAmbient.still),

  /// Weather alert detail.
  weatherAlert(
    AuraSkies.weatherAlert,
    AuraBlooms.weatherAlert,
    AuraAmbient.still,
  ),

  /// Sun and moon detail.
  sunAndMoon(
    AuraSkies.sunAndMoon,
    AuraBlooms.sunAndMoon,
    AuraAmbient.still,
  );

  const AuraSkyKind(
    this.gradient,
    this.bloom,
    this.ambient, {
    this.hasStars = false,
  });

  /// The vertical gradient this sky paints. The frame's first fill.
  final AuraGradient gradient;

  /// The radial wash painted over [gradient]. The frame's second fill.
  final AuraBloom bloom;

  /// What moves over the two fills.
  ///
  /// The pen authors no motion, so this is the one part of a sky that is not
  /// read from a frame. It is constrained instead by colour: every ambient
  /// layer reuses a token the pen already declares.
  final AuraAmbient ambient;

  /// Whether the sky carries a starfield above its fills.
  final bool hasStars;
}

/// Paints a condition sky behind its child, crossfading when the sky changes.
///
/// Use this as the root of every screen. Both fills are drawn by one painter
/// driven by one animation, so the layers cannot drift out of step with each
/// other mid-transition.
///
/// The moving layer is a **second** painter above the first. That split is
/// deliberate: the fills are two full-screen shaders and only change during a
/// transition, while rain has to redraw every frame. One painter for both would
/// re-run the shaders sixty times a second to move a few streaks.
class AuraSky extends StatefulWidget {
  /// Creates a sky background.
  const AuraSky({required this.kind, this.celestial, this.child, super.key});

  /// Which sky to paint.
  final AuraSkyKind kind;

  /// The sun or the moon riding the sky, when one is up.
  ///
  /// Absent on every screen that is not showing a live reading, and absent at
  /// night before the moon has risen. Passed in rather than derived here,
  /// because where the sun is comes from the domain and this package may not
  /// know what a sunrise is.
  final AuraCelestial? celestial;

  /// Content drawn on top of the sky.
  final Widget? child;

  @override
  State<AuraSky> createState() => _AuraSkyState();
}

class _AuraSkyState extends State<AuraSky> with TickerProviderStateMixin {
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

  /// The sun or the moon travelling between readings.
  ///
  /// Its first arrival retraces the arc from the horizon to now, which is the
  /// one theatrical moment the app allows itself. Every later change is a
  /// short settle: a refreshed reading moves the body a few points, a swap at
  /// dusk crossfades the sun for the moon.
  late final AnimationController _bodyController = AnimationController(
    vsync: this,
    duration: AuraMotion.celestialArrival,
    value: 1,
  );

  late final Animation<double> _bodyProgress = CurvedAnimation(
    parent: _bodyController,
    curve: AuraMotion.skyCurve,
  );

  /// The body being left behind by the current transition, if any.
  AuraCelestial? _bodyFrom;

  /// The body the transition is heading to. Mirrors `widget.celestial`.
  AuraCelestial? _bodyTo;

  @override
  void initState() {
    super.initState();
    _bodyTo = widget.celestial;
    // Once a crossfade into a still sky finishes, the outgoing layer is gone
    // and there is nothing left to tick for.
    _controller.addStatusListener(_onTransitionStatus);
  }

  void _onTransitionStatus(AnimationStatus status) {
    if (status.isCompleted) _syncTicker();
  }

  /// The clock every ambient layer reads its phase off.
  ///
  /// One controller for all of them, with each layer scaling it by its own
  /// speed, so a sky cannot end up with two layers ticking against each other.
  late final AnimationController _ambient = AnimationController(
    vsync: this,
    duration: AuraMotion.breath,
  );

  bool _animate = true;

  /// Whether either side of the current transition has anything that moves.
  ///
  /// Most skies in the app do not: the splash, the brand sky and all three
  /// detail skies are still. Running a ticker for them would burn a frame
  /// callback to draw nothing, and it would also mean `pumpAndSettle` never
  /// returned on any screen in the app.
  bool get _hasMotion =>
      (_controller.isAnimating && _from.ambient.kind != AuraAmbientKind.none) ||
      _to.ambient.kind != AuraAmbientKind.none;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _animate = !context.prefersReducedMotion;
    _syncTicker();
    // A screen that opens straight onto a reading still gets the arrival: the
    // check lives here rather than in initState because only now is the
    // reduced-motion preference known.
    if (_animate && _bodyTo != null && !_arrivalPlayed) {
      _arrivalPlayed = true;
      unawaited(_bodyController.forward(from: 0));
    }
    if (!_animate) _bodyController.value = 1;
  }

  /// Whether the first arrival has already been swept.
  bool _arrivalPlayed = false;

  void _syncTicker() {
    final shouldRun = _animate && _hasMotion;
    if (shouldRun == _ambient.isAnimating) return;
    if (shouldRun) {
      unawaited(_ambient.repeat());
    } else {
      // Held at zero rather than stopped wherever it happened to be, so the
      // resting frame is the same one every time.
      _ambient
        ..stop()
        ..value = 0;
    }
  }

  @override
  void didUpdateWidget(AuraSky oldWidget) {
    super.didUpdateWidget(oldWidget);
    _retargetBody();
    if (widget.kind == _to) return;
    _from = _to;
    _to = widget.kind;
    // The sky is the whole screen, so its crossfade is the largest single
    // movement in the app. Reduced motion cuts to the new sky instead.
    if (!_animate) {
      _controller.value = 1;
      _syncTicker();
      return;
    }
    _syncTicker();
    unawaited(_controller.forward(from: 0));
  }

  /// Points the body transition at the widget's current celestial.
  void _retargetBody() {
    final target = widget.celestial;
    if (target == _bodyTo) return;

    final arriving = _bodyTo == null && _bodyFrom == null && target != null;
    // A change mid-flight leaves from wherever the body is drawn now, so a
    // fast pair of readings cannot make it jump back and start over.
    _bodyFrom = _drawnBody(_bodyProgress.value);
    _bodyTo = target;
    _arrivalPlayed = true;
    _bodyController.duration = arriving
        ? AuraMotion.celestialArrival
        : AuraMotion.celestialShift;

    if (!_animate) {
      _bodyController.value = 1;
      return;
    }
    unawaited(_bodyController.forward(from: 0));
  }

  /// The body as it should be painted at [t] through the current transition.
  ///
  /// On its first arrival the body sweeps the arc from the horizon to now; a
  /// later change travels from wherever it was. A swap between the sun and the
  /// moon does not travel at all, because the two never share a path: the
  /// leaving body fades where it is and the arriving one fades in at its own
  /// place, which [_drawnOutgoing] carries.
  AuraCelestial? _drawnBody(double t) {
    final to = _bodyTo;
    final from = _bodyFrom;
    if (to == null) return null;
    if (from == null) {
      return AuraCelestial(
        body: to.body,
        position: to.position * t,
        illumination: to.illumination,
        isWaxing: to.isWaxing,
      );
    }
    if (from.body != to.body) return to;
    return AuraCelestial(
      body: to.body,
      position: from.position + (to.position - from.position) * t,
      illumination:
          from.illumination + (to.illumination - from.illumination) * t,
      isWaxing: to.isWaxing,
    );
  }

  /// How strongly the arriving body is lit at [t].
  ///
  /// An arrival fades in over the first stretch of its sweep so the sun does
  /// not pop onto the horizon; a swap crossfades over the whole transition.
  double _drawnBlend(double t) {
    final to = _bodyTo;
    if (to == null) return 0;
    final from = _bodyFrom;
    if (from == null) {
      return (t / _arrivalFadeIn).clamp(0.0, 1.0);
    }
    if (from.body != to.body) return t;
    return 1;
  }

  /// The body on its way out, painted only while a swap or a clearing sky is
  /// mid-transition.
  AuraCelestial? _drawnOutgoing(double t) {
    final from = _bodyFrom;
    final to = _bodyTo;
    if (from == null || t >= 1) return null;
    if (to != null && to.body == from.body) return null;
    return from;
  }

  /// Fraction of the arrival over which the body fades in.
  static const double _arrivalFadeIn = 0.3;

  @override
  void dispose() {
    _ambient.dispose();
    _bodyController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Every sky in the design is dark and the app runs edge to edge, so the
      // clock and the battery sit directly on the gradient. Declaring it here
      // rather than once in main is what makes it stick: a single
      // setSystemUIOverlayStyle before runApp is overridden by the window on
      // both platforms, and the bars come back dark on a dark sky.
      value: _lightSystemBars,
      child: AnimatedBuilder(
        animation: Listenable.merge(<Listenable>[_progress, _bodyProgress]),
        builder: (context, child) => CustomPaint(
          painter: _SkyPainter(
            from: _from,
            to: _to,
            progress: _progress.value,
            // The bloom is the atmosphere around the body, so it follows the
            // drawn position rather than the target and travels with the
            // arrival sweep.
            celestial: _drawnBody(_bodyProgress.value),
          ),
          child: child,
        ),
        child: AnimatedBuilder(
          animation: Listenable.merge(
            <Listenable>[_progress, _ambient, _bodyProgress],
          ),
          builder: (context, child) => CustomPaint(
            painter: _AmbientPainter(
              from: _from,
              to: _to,
              progress: _progress.value,
              phase: _ambient.value,
              animate: _animate,
              celestial: _drawnBody(_bodyProgress.value),
              celestialBlend: _drawnBlend(_bodyProgress.value),
              celestialOut: _drawnOutgoing(_bodyProgress.value),
              celestialOutBlend: 1 - _bodyProgress.value,
            ),
            child: child,
          ),
          child: widget.child,
        ),
      ),
    );
  }

  static const SystemUiOverlayStyle _lightSystemBars = SystemUiOverlayStyle(
    statusBarColor: AuraColors.transparent,
    statusBarBrightness: Brightness.dark,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AuraColors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
  );
}

/// Paints both of a sky's fills.
class _SkyPainter extends CustomPainter {
  const _SkyPainter({
    required this.from,
    required this.to,
    required this.progress,
    required this.celestial,
  });

  final AuraSkyKind from;
  final AuraSkyKind to;
  final double progress;

  /// Where the light on this sky is coming from, when anything is up.
  ///
  /// The pen fixes the bloom at one point on every frame, which is right for a
  /// still. On a screen that also draws the sun it is wrong: two bright places
  /// on one sky read as a smear beside a star. The bloom follows the body
  /// instead, so there is one light source and it moves with the day.
  final AuraCelestial? celestial;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    _paintGradient(canvas, rect);
    _paintBloom(canvas, rect);
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

    final centre = _bloomCentre(a, b, t, rect);
    canvas
      ..save()
      ..translate(rect.left + centre.dx, rect.top + centre.dy)
      ..scale(radiusX, radiusY)
      ..drawCircle(Offset.zero, 1, Paint()..shader = shader)
      ..restore();
  }

  /// Where the bloom sits, in points: under the body when there is one, and
  /// where the pen puts it when the sky is empty.
  Offset _bloomCentre(AuraBloom a, AuraBloom b, double t, Rect rect) {
    final body = celestial;
    if (body == null) {
      return Offset(
        _lerp(a.centerX, b.centerX, t) * rect.width,
        _lerp(a.centerY, b.centerY, t) * rect.height,
      );
    }
    return AuraCelestialPainter.centreOf(rect.size, body.position);
  }

  /// One bloom stop, with the fill layer's own opacity folded into its alpha.
  ///
  /// The layer is a single draw, so multiplying alpha is what a layer opacity
  /// would do and costs no save-layer.
  static Color _blendStop(Color a, Color b, double t, double opacity) {
    final blended = Color.lerp(a, b, t)!;
    return blended.withValues(alpha: blended.a * opacity);
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  @override
  bool shouldRepaint(_SkyPainter oldDelegate) =>
      oldDelegate.from != from ||
      oldDelegate.to != to ||
      oldDelegate.progress != progress ||
      oldDelegate.celestial != celestial;
}

/// Paints the moving layer over a sky, and the starfield that twinkles in it.
///
/// Both sides of a transition are drawn, each at its own share of the
/// crossfade, so rain thins out as clear sky arrives rather than being cut.
///
/// Under reduced motion this paints **exactly what the pen draws** and nothing
/// else, which is what lets the goldens stand as the regression test for the
/// whole layer: if a golden moves, an animation has changed a frame rather than
/// how that frame is reached.
class _AmbientPainter extends CustomPainter {
  const _AmbientPainter({
    required this.from,
    required this.to,
    required this.progress,
    required this.phase,
    required this.animate,
    required this.celestial,
    required this.celestialBlend,
    required this.celestialOut,
    required this.celestialOutBlend,
  });

  final AuraSkyKind from;
  final AuraSkyKind to;
  final double progress;
  final double phase;

  /// False when the platform has asked for reduced motion.
  final bool animate;

  /// The sun or the moon riding this sky, when one is up.
  final AuraCelestial? celestial;

  /// How strongly [celestial] is lit, below 1 only mid-transition.
  final double celestialBlend;

  /// The body a swap is fading out, painted at [celestialOutBlend].
  final AuraCelestial? celestialOut;

  /// How much of [celestialOut] is left.
  final double celestialOutBlend;

  @override
  void paint(Canvas canvas, Size size) {
    // The bodies go under the weather: rain falls in front of the sun.
    final leaving = celestialOut;
    if (leaving != null && celestialOutBlend > 0) {
      AuraCelestialPainter.paint(
        canvas,
        size,
        leaving,
        blend: celestialOutBlend,
        phase: animate ? phase : 0,
      );
    }
    final body = celestial;
    if (body != null && celestialBlend > 0) {
      AuraCelestialPainter.paint(
        canvas,
        size,
        body,
        blend: celestialBlend,
        phase: animate ? phase : 0,
      );
    }
    if (from == to) {
      _paintLayer(canvas, size, to, 1);
      return;
    }
    _paintLayer(canvas, size, from, 1 - progress);
    _paintLayer(canvas, size, to, progress);
  }

  void _paintLayer(Canvas canvas, Size size, AuraSkyKind sky, double blend) {
    if (blend <= 0) return;
    final ambient = sky.ambient;
    final beat = animate ? phase * ambient.speed : 0.0;

    // Reduced motion drops the layer rather than freezing it. Every mark here
    // is decorative and says nothing the gradient, the glyph and the condition
    // text do not already say, so a still rain field would be an artefact
    // nobody designed rather than information anybody would miss. The starfield
    // is the exception, because the pen draws it: it stays, unmodulated.
    if (!animate && ambient.kind != AuraAmbientKind.twinkle) return;

    switch (ambient.kind) {
      case AuraAmbientKind.none:
        return;
      case AuraAmbientKind.breath:
        _paintBreath(canvas, size, ambient, blend, beat);
      case AuraAmbientKind.twinkle:
        _paintStars(canvas, size, ambient, blend, beat);
      case AuraAmbientKind.drift:
        _paintDrift(canvas, size, ambient, blend, beat);
      case AuraAmbientKind.rain:
        _paintRain(canvas, size, ambient, blend, beat);
      case AuraAmbientKind.snow:
        _paintSnow(canvas, size, ambient, blend, beat);
    }
    if (ambient.flash > 0) _paintFlash(canvas, size, ambient, blend, beat);
  }

  /// A pulse of extra light low on the sky, rising from nothing and returning.
  ///
  /// Zero at [phase] zero, so a clear-day screen at rest is the pen's frame
  /// exactly and its golden does not move.
  void _paintBreath(
    Canvas canvas,
    Size size,
    AuraAmbient ambient,
    double blend,
    double beat,
  ) {
    final swell = (1 - cos(beat * 2 * pi)) / 2;
    final alpha = ambient.opacity * swell * blend;
    if (alpha <= 0) return;

    final centre = Offset(size.width / 2, size.height * _breathCentreY);
    final radius = size.width * _breathRadius;
    final rect = Rect.fromCircle(center: centre, radius: radius);
    canvas.drawCircle(
      centre,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            ambient.color.withValues(alpha: alpha),
            ambient.color.withValues(alpha: 0),
          ],
          stops: const <double>[0, 1],
        ).createShader(rect),
    );
  }

  /// The eleven stars the pen draws, each breathing on its own offset.
  ///
  /// The modulation is a dimming, never a brightening, and it is zero at
  /// [phase] zero. A star therefore rests at exactly the opacity the frame
  /// authors and only ever goes darker than it.
  void _paintStars(
    Canvas canvas,
    Size size,
    AuraAmbient ambient,
    double blend,
    double beat,
  ) {
    final scaleX = size.width / AuraSizes.referenceWidth;
    final scaleY = size.height / AuraSizes.referenceHeight;
    final paint = Paint();

    for (var i = 0; i < _Star.field.length; i++) {
      final star = _Star.field[i];
      final swell = animate
          ? (1 - cos(AuraAmbientField.progress(i, beat, salt: 11) * 2 * pi)) / 2
          : 0.0;
      final dimmed = star.opacity * (1 - ambient.opacity * swell);
      paint.color = ambient.color.withValues(alpha: dimmed * blend);
      final radius = star.diameter / 2;
      canvas.drawCircle(
        Offset((star.x + radius) * scaleX, (star.y + radius) * scaleY),
        radius,
        paint,
      );
    }
  }

  /// Wide soft bands crossing the sky.
  void _paintDrift(
    Canvas canvas,
    Size size,
    AuraAmbient ambient,
    double blend,
    double beat,
  ) {
    final bandHeight = size.height * ambient.length;
    final bandWidth = size.width * _driftWidth;

    for (var i = 0; i < ambient.count; i++) {
      final travel = AuraAmbientField.progress(i, beat, salt: 23);
      final centreX = travel * (size.width + bandWidth * 2) - bandWidth;
      final centreY =
          (_driftTop + AuraAmbientField.scatter(i, 31) * _driftSpread) *
          size.height;
      final alpha = ambient.opacity * blend;

      final shader = RadialGradient(
        colors: <Color>[
          ambient.color.withValues(alpha: alpha),
          ambient.color.withValues(alpha: 0),
        ],
        stops: const <double>[0, 1],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: 1));

      canvas
        ..save()
        ..translate(centreX, centreY)
        ..scale(bandWidth, bandHeight)
        ..drawCircle(Offset.zero, 1, Paint()..shader = shader)
        ..restore();
    }
  }

  /// Slanted streaks falling past the screen.
  void _paintRain(
    Canvas canvas,
    Size size,
    AuraAmbient ambient,
    double blend,
    double beat,
  ) {
    final length = size.height * ambient.length;
    final slant = size.width * ambient.slant;
    final paint = Paint()
      ..strokeWidth = ambient.thickness
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < ambient.count; i++) {
      final fall = AuraAmbientField.progress(i, beat, salt: 7);
      final x = AuraAmbientField.scatter(i, 13) * (size.width + slant) - slant;
      final y = fall * (size.height + length) - length;
      // Depth: a nearer streak is darker, so the field does not read as a
      // single flat plane of identical marks.
      final depth = _depthFloor + AuraAmbientField.scatter(i, 29) * _depthRange;
      paint.color = ambient.color.withValues(
        alpha: ambient.opacity * depth * blend,
      );
      canvas.drawLine(Offset(x, y), Offset(x + slant, y + length), paint);
    }
  }

  /// Flakes descending, swaying so they do not fall in columns.
  void _paintSnow(
    Canvas canvas,
    Size size,
    AuraAmbient ambient,
    double blend,
    double beat,
  ) {
    final radius = ambient.thickness / 2;
    final sway = size.width * ambient.sway;
    final paint = Paint();

    for (var i = 0; i < ambient.count; i++) {
      final fall = AuraAmbientField.progress(i, beat, salt: 3);
      final drift = AuraAmbientField.wave(i, beat * _swayRate, salt: 5);
      final x = AuraAmbientField.scatter(i, 17) * size.width + drift * sway;
      final y = fall * (size.height + ambient.thickness) - ambient.thickness;
      final depth = _depthFloor + AuraAmbientField.scatter(i, 19) * _depthRange;
      paint.color = ambient.color.withValues(
        alpha: ambient.opacity * depth * blend,
      );
      canvas.drawCircle(Offset(x, y), radius * depth, paint);
    }
  }

  /// The storm's flash: two short strikes at irregular points in the cycle.
  ///
  /// Irregular on purpose. Lightning on a fixed beat reads as a blinking light
  /// rather than as weather.
  void _paintFlash(
    Canvas canvas,
    Size size,
    AuraAmbient ambient,
    double blend,
    double beat,
  ) {
    final strike = _strikeAt(beat);
    if (strike <= 0) return;
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..color = AuraAmbients.flashColor.withValues(
          alpha: ambient.flash * strike * blend,
        ),
    );
  }

  /// A short spike at each of two points, and zero everywhere else.
  static double _strikeAt(double beat) {
    final cycle = beat - beat.floorToDouble();
    final first = _spike(cycle, _firstStrike, _strikeWidth);
    final second = _spike(cycle, _secondStrike, _strikeWidth / 2) * _afterglow;
    return first > second ? first : second;
  }

  static double _spike(double cycle, double at, double width) {
    final distance = (cycle - at).abs();
    return distance < width ? 1 - distance / width : 0;
  }

  /// Where the breath's extra light sits, and how far it reaches.
  static const double _breathCentreY = 0.2;
  static const double _breathRadius = 0.85;

  /// Band geometry for a drifting sky.
  static const double _driftWidth = 0.55;
  static const double _driftTop = 0.12;
  static const double _driftSpread = 0.45;

  /// How much a mark's alpha and size vary with its depth in the field.
  static const double _depthFloor = 0.55;
  static const double _depthRange = 0.45;

  /// Snow sways faster than it falls, or it reads as sliding rather than
  /// drifting.
  static const double _swayRate = 2.4;

  /// Where in a cycle the two strikes land, and how long each lasts.
  static const double _firstStrike = 0.23;
  static const double _secondStrike = 0.29;
  static const double _strikeWidth = 0.018;
  static const double _afterglow = 0.65;

  @override
  bool shouldRepaint(_AmbientPainter oldDelegate) =>
      oldDelegate.from != from ||
      oldDelegate.to != to ||
      oldDelegate.progress != progress ||
      oldDelegate.phase != phase ||
      oldDelegate.animate != animate ||
      oldDelegate.celestial != celestial ||
      oldDelegate.celestialBlend != celestialBlend ||
      oldDelegate.celestialOut != celestialOut ||
      oldDelegate.celestialOutBlend != celestialOutBlend;
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
