import 'dart:async';

import 'package:aura_design/aura_design.dart';
import 'package:flutter/material.dart'
    show RefreshIndicator, RefreshIndicatorStatus;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Pull to refresh, wearing the Aura mark instead of a Material spinner.
///
/// The gesture is still Flutter's, so the pull behaves the way it does in every
/// other app on each platform. Only what it draws is ours:
/// `RefreshIndicator.noSpinner` suppresses the stock disc and reports the
/// status, and the mark below is what the user actually sees.
///
/// A tick fires the moment the pull arms, which is the point the gesture
/// commits. That is the only haptic on this screen that is not tied to a tap.
class HomeRefresh extends StatefulWidget {
  /// Wraps [child] in the refresh gesture.
  const HomeRefresh({
    required this.onRefresh,
    required this.child,
    super.key,
  });

  /// Runs the fetch. The gesture ends when this completes.
  final Future<void> Function() onRefresh;

  /// The scrollable being pulled.
  final Widget child;

  @override
  State<HomeRefresh> createState() => _HomeRefreshState();
}

class _HomeRefreshState extends State<HomeRefresh>
    with SingleTickerProviderStateMixin {
  /// The mark's breath while the request is out.
  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: AuraMotion.breath,
  );

  RefreshIndicatorStatus? _status;

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  void _onStatusChange(RefreshIndicatorStatus? status) {
    if (status == RefreshIndicatorStatus.armed) {
      HapticFeedback.mediumImpact().ignore();
    }
    final showing =
        status == RefreshIndicatorStatus.snap ||
        status == RefreshIndicatorStatus.refresh;
    if (showing && !_breath.isAnimating && !context.prefersReducedMotion) {
      unawaited(_breath.repeat());
    } else if (!showing && _breath.isAnimating) {
      _breath.stop();
    }
    setState(() => _status = status);
  }

  /// How far into the pull the indicator is worth drawing.
  ///
  /// It appears once the gesture has committed rather than tracking the finger
  /// from the first pixel, so a scroll that overshoots the top by a few points
  /// does not flash the mark.
  bool get _visible => switch (_status) {
    RefreshIndicatorStatus.armed ||
    RefreshIndicatorStatus.snap ||
    RefreshIndicatorStatus.refresh => true,
    _ => false,
  };

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        RefreshIndicator.noSpinner(
          onRefresh: widget.onRefresh,
          onStatusChange: _onStatusChange,
          child: widget.child,
        ),
        Positioned(
          top: MediaQuery.paddingOf(context).top + AuraSpacing.md,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: AnimatedOpacity(
              opacity: _visible ? 1 : 0,
              duration: AuraMotion.control,
              curve: AuraMotion.controlCurve,
              child: Center(
                child: AnimatedBuilder(
                  animation: _breath,
                  builder: (context, _) => AuraMark(
                    size: AuraMarkSize.hero,
                    glow: 1 + _glowBreath * _swell(_breath.value),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// How far the mark's glow swells while the request is out.
  static const double _glowBreath = 0.22;

  /// Zero at rest, one at the midpoint, zero again at the end.
  static double _swell(double t) =>
      AuraMotion.breathCurve.transform(1 - (2 * t - 1).abs());
}
