import 'dart:async';

import 'package:aura_design/aura_design.dart';
import 'package:aura_feature_onboarding/src/splash/splash_view_model.dart';
import 'package:aura_l10n/aura_l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The first frame the app shows, while it works out where to send the user.
///
/// Built from the `Aura · Splash` frame. Every frame in the pen draws a
/// simulated iOS status bar; the real app uses the system's, so the 62 point
/// band it occupies is the top safe-area inset here rather than a widget. The
/// lockup centres below it, exactly as the pen's `Center` frame does.
///
/// The loader and the attribution are absolutely placed in the pen, and their
/// offsets are measured from the bottom edge of the canvas, which runs under
/// the home indicator. They are therefore laid out against the screen edge and
/// not against the safe area.
///
/// The frame is a still, so it says what the screen looks like and not how it
/// arrives. It arrives as a reveal: the mark blooms out of the dark, the rings
/// sweep on, and the wordmark and tagline resolve behind them. Every one of
/// those animations ends on the frame the pen draws, which is the only state
/// the screen rests in.
class SplashScreen extends ConsumerStatefulWidget {
  /// Creates the splash screen.
  const SplashScreen({required this.onReady, super.key});

  /// Called with where the app should open, once that is known.
  final ValueChanged<SplashDestination> onReady;

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    unawaited(ref.read(splashViewModelProvider.notifier).decide());
  }

  @override
  Widget build(BuildContext context) {
    return AuraSky(
      kind: AuraSkyKind.splash,
      child: _Stage(
        destination: ref.watch(splashViewModelProvider),
        onReady: widget.onReady,
      ),
    );
  }
}

/// The animated lockup, deliberately kept off the consumer element.
///
/// The tickers cannot live on `_SplashScreenState`. A route transition flips
/// `TickerMode`, and a `ConsumerStatefulElement` answers that by resuming its
/// provider subscriptions, which lands a `setState` in the middle of the
/// build that caused it. Holding the controllers one widget lower keeps the
/// consumer free of any ticker dependency.
class _Stage extends StatefulWidget {
  const _Stage({required this.destination, required this.onReady});

  /// Where the app should open, once the view model knows.
  final SplashDestination? destination;

  /// Called after the lockup has left.
  final ValueChanged<SplashDestination> onReady;

  @override
  State<_Stage> createState() => _StageState();
}

class _StageState extends State<_Stage> with TickerProviderStateMixin {
  /// Drives the whole reveal. One controller, so the pieces cannot fall out of
  /// order however long any single leg takes.
  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: AuraMotion.splashReveal + AuraMotion.splashSettle,
  );

  /// The glow's breath, once the mark has arrived.
  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: AuraMotion.breath,
  );

  /// Runs backwards as the screen hands over, so the lockup leaves rather than
  /// being cut away under the route transition.
  late final AnimationController _exit = AnimationController(
    vsync: this,
    duration: AuraMotion.splashExit,
    value: 1,
  );

  bool _started = false;
  bool _leaving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      if (context.prefersReducedMotion) {
        _reveal.value = 1;
      } else {
        unawaited(_reveal.forward());
        unawaited(_breath.repeat());
      }
    }
    if (widget.destination != null) unawaited(_handOver(widget.destination!));
  }

  @override
  void didUpdateWidget(_Stage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.destination != null) unawaited(_handOver(widget.destination!));
  }

  @override
  void dispose() {
    _exit.dispose();
    _breath.dispose();
    _reveal.dispose();
    super.dispose();
  }

  /// Plays the lockup out, then hands over.
  ///
  /// The destination is reported either way. A handoff that depended on an
  /// animation finishing would strand the app on the splash if the ticker were
  /// ever muted, so reduced motion reports immediately and the exit is the
  /// only thing skipped.
  Future<void> _handOver(SplashDestination destination) async {
    if (_leaving) return;
    _leaving = true;

    if (!context.prefersReducedMotion) {
      await _exit.reverse();
      if (!mounted) return;
    }
    widget.onReady(destination);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _exit,
      builder: (context, child) => Opacity(
        opacity: _exit.value,
        child: Transform.translate(
          offset: Offset(0, (1 - _exit.value) * -AuraMotion.entranceRise),
          child: child,
        ),
      ),
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: SafeArea(
              bottom: false,
              child: _Lockup(reveal: _reveal, breath: _breath),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: AuraSizes.splashLoaderInset,
            child: _Reveal(
              reveal: _reveal,
              start: loaderStart,
              child: const _Loader(),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: AuraSizes.splashAttributionInset,
            child: _Reveal(
              reveal: _reveal,
              start: loaderStart,
              child: const _Attribution(),
            ),
          ),
        ],
      ),
    );
  }

  /// Where each piece of the lockup begins, as a fraction of the whole reveal.
  static const double wordmarkStart = 0.35;
  static const double taglineStart = 0.5;
  static const double loaderStart = 0.7;
}

/// The mark, the wordmark and the tagline, centred as one block.
class _Lockup extends StatelessWidget {
  const _Lockup({required this.reveal, required this.breath});

  final Animation<double> reveal;
  final Animation<double> breath;

  /// The mark has finished arriving well before the text has.
  static const double _markEnd = 0.55;

  /// How far the mark is scaled down when it starts.
  static const double _markFrom = 0.86;

  /// How far past its resting radius the glow swells on the way in, and how
  /// far it breathes once it is there.
  static const double _glowOvershoot = 0.35;
  static const double _glowBreath = 0.04;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        AnimatedBuilder(
          animation: Listenable.merge(<Listenable>[reveal, breath]),
          builder: (context, _) {
            final arrival = AuraMotion.entranceCurve.transform(
              (reveal.value / _markEnd).clamp(0.0, 1.0),
            );
            final settled = arrival >= 1;
            // The glow overshoots on the way in and settles back, then keeps
            // a much smaller breath. It is the one part of the mark with no
            // edge, so it can move without the mark looking resized.
            final swell = settled
                ? 1 + _glowBreath * _swell(breath.value)
                : 1 + _glowOvershoot * _arc(arrival);
            return Transform.scale(
              scale: _markFrom + (1 - _markFrom) * arrival,
              child: AuraMark(
                size: AuraMarkSize.splash,
                reveal: arrival,
                glow: swell,
              ),
            );
          },
        ),
        const SizedBox(height: AuraSpacing.xxlPlus),
        _Reveal(
          reveal: reveal,
          start: _StageState.wordmarkStart,
          child: Text(
            AuraBrand.name,
            style: AuraText.wordmark.copyWith(color: AuraColors.textPrimary),
          ),
        ),
        const SizedBox(height: AuraSpacing.xxlPlus),
        _Tagline(reveal: reveal),
      ],
    );
  }

  /// Rises to one at the midpoint and returns, for an overshoot that settles.
  static double _arc(double t) => 1 - (2 * t - 1).abs();

  /// A breath from zero, so the resting frame is the pen's.
  static double _swell(double t) => AuraMotion.breathCurve.transform(_arc(t));
}

/// The tagline, its tracking resolving from wide to the value the pen sets.
///
/// The animation is self-handling across scripts: `forScript` already zeroes
/// tracking in Arabic, because Arabic is cursive and letter-spacing prises the
/// joins apart. Interpolating towards zero from a multiple of zero is a plain
/// fade, which is exactly what Arabic should get.
class _Tagline extends StatelessWidget {
  const _Tagline({required this.reveal});

  final Animation<double> reveal;

  /// How much wider the tracking starts than it ends.
  static const double _from = 2.4;

  @override
  Widget build(BuildContext context) {
    final style = AuraText.tagline
        .forScript(context)
        .copyWith(color: AuraColors.textSecondary);

    return _Reveal(
      reveal: reveal,
      start: _StageState.taglineStart,
      child: AnimatedBuilder(
        animation: reveal,
        builder: (context, _) {
          final settle = _Reveal.progressOf(
            reveal.value,
            _StageState.taglineStart,
          );
          final tracking = style.letterSpacing ?? 0;
          return Text(
            context.l10n.splashTagline.toUpperCase(),
            style: style.copyWith(
              letterSpacing: tracking * (_from - (_from - 1) * settle),
            ),
          );
        },
      ),
    );
  }
}

/// Fades and lifts one piece of the lockup in, from [start] onwards.
class _Reveal extends StatelessWidget {
  const _Reveal({
    required this.reveal,
    required this.start,
    required this.child,
  });

  final Animation<double> reveal;
  final double start;
  final Widget child;

  /// How far through the reveal [value] sits, past [start].
  static double progressOf(double value, double start) =>
      AuraMotion.entranceCurve.transform(
        ((value - start) / (1 - start)).clamp(0.0, 1.0),
      );

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: reveal,
      builder: (context, child) {
        final progress = progressOf(reveal.value, start);
        return Opacity(
          opacity: progress,
          child: Transform.translate(
            offset: Offset(0, (1 - progress) * AuraMotion.splashRise),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

/// Three dots, one lit and the others dimmed, with the lit one travelling.
///
/// The pen draws the state rather than the motion: the first dot is at full
/// strength and the other two sit at 40 per cent. A loading indicator that
/// never moves reads as a broken screen, so the lit dot cycles on the cadence
/// the design system already defines for loading.
class _Loader extends StatefulWidget {
  const _Loader();

  @override
  State<_Loader> createState() => _LoaderState();
}

class _LoaderState extends State<_Loader> with SingleTickerProviderStateMixin {
  static const int _dotCount = 3;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AuraMotion.shimmer,
  );

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    // Reduced motion rests on the pen's own frame, which lights the first dot.
    if (!context.prefersReducedMotion) unawaited(_controller.repeat());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: context.l10n.splashLoading,
      liveRegion: true,
      excludeSemantics: true,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final lit = (_controller.value * _dotCount).floor() % _dotCount;
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              for (var i = 0; i < _dotCount; i++) ...<Widget>[
                if (i > 0) const SizedBox(width: AuraSpacing.xsPlus),
                _Dot(lit: i == lit),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.lit});

  /// Whether this is the dot currently at full strength.
  final bool lit;

  /// The pen dims every dot but one to 40 per cent.
  static const double _dimmed = 0.4;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: lit ? 1 : _dimmed,
      duration: AuraMotion.control,
      curve: AuraMotion.controlCurve,
      child: const SizedBox.square(
        dimension: AuraSizes.splashDot,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AuraColors.accent,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

/// Credit for the weather service, which the free tier requires to be visible.
class _Attribution extends StatelessWidget {
  const _Attribution();

  @override
  Widget build(BuildContext context) {
    return Text(
      context.l10n.splashAttribution.toUpperCase(),
      textAlign: TextAlign.center,
      style: AuraText.attribution
          .forScript(context)
          .copyWith(color: AuraColors.textTertiary),
    );
  }
}
