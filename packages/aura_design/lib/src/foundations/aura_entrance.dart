import 'dart:async';

import 'package:aura_design/src/tokens/aura_motion.dart';
import 'package:flutter/widgets.dart';

/// Fades and lifts its child into place, [index] places behind the first.
///
/// The screen a reading lands on has seven sections, and showing all seven at
/// once reads as a jump cut. Staggering them lets the eye follow the content
/// down the page in the order it is meant to be read.
///
/// It runs **once**, on first build. The home screen deliberately keeps the
/// previous reading through a refresh, so replaying the entrance on every fetch
/// would contradict the thing that behaviour exists to protect.
class AuraEntrance extends StatefulWidget {
  /// Creates a staggered entrance.
  const AuraEntrance({
    required this.index,
    required this.child,
    super.key,
  });

  /// Position in the stagger, from zero. Each step adds
  /// [AuraMotion.entranceStagger] to the delay.
  final int index;

  /// The section arriving.
  final Widget child;

  @override
  State<AuraEntrance> createState() => _AuraEntranceState();
}

class _AuraEntranceState extends State<AuraEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AuraMotion.entrance,
  );

  late final Animation<double> _progress = CurvedAnimation(
    parent: _controller,
    curve: AuraMotion.entranceCurve,
  );

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    if (context.prefersReducedMotion) {
      _controller.value = 1;
      return;
    }
    unawaited(_play());
  }

  Future<void> _play() async {
    if (widget.index > 0) {
      await Future<void>.delayed(AuraMotion.entranceStagger * widget.index);
      if (!mounted) return;
    }
    await _controller.forward();
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
      builder: (context, child) {
        final t = _progress.value;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * AuraMotion.entranceRise),
            // The scale is what makes the arrival read as a card settling onto
            // the page rather than as text fading up.
            child: Transform.scale(
              scale:
                  AuraMotion.entranceScale + (1 - AuraMotion.entranceScale) * t,
              child: child,
            ),
          ),
        );
      },
      child: widget.child,
    );
  }
}
