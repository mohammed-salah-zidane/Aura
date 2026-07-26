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
    ref.listen(splashViewModelProvider, (previous, next) {
      if (next != null) widget.onReady(next);
    });

    return const AuraSky(
      kind: AuraSkyKind.splash,
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: SafeArea(bottom: false, child: _Lockup()),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: AuraSizes.splashLoaderInset,
            child: _Loader(),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: AuraSizes.splashAttributionInset,
            child: _Attribution(),
          ),
        ],
      ),
    );
  }
}

/// The mark, the wordmark and the tagline, centred as one block.
class _Lockup extends StatelessWidget {
  const _Lockup();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        const AuraMark(size: AuraMarkSize.splash),
        const SizedBox(height: AuraSpacing.xxlPlus),
        Text(
          AuraBrand.name,
          style: AuraText.wordmark.copyWith(color: AuraColors.textPrimary),
        ),
        const SizedBox(height: AuraSpacing.xxlPlus),
        Text(
          context.l10n.splashTagline.toUpperCase(),
          style: AuraText.tagline
              .forScript(context)
              .copyWith(color: AuraColors.textSecondary),
        ),
      ],
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
  )..repeat();

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
