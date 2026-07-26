import 'package:aura_design/src/tokens/aura_gradients.dart';
import 'package:aura_design/src/tokens/aura_metrics.dart';
import 'package:aura_design/src/tokens/aura_motion.dart';
import 'package:flutter/widgets.dart';

/// A shimmering placeholder shown while data loads.
///
/// Use a skeleton for content that is arriving, and a spinner only for an
/// action the user just triggered. A spinner where content belongs tells the
/// user nothing about what is coming.
class AuraSkeleton extends StatefulWidget {
  /// Creates a skeleton block.
  const AuraSkeleton({
    required this.width,
    required this.height,
    this.radius = AuraRadii.chip,
    super.key,
  });

  /// A skeleton shaped like a line of text.
  const AuraSkeleton.line({
    required double width,
    double height = 12,
    Key? key,
  }) : this(width: width, height: height, radius: 4, key: key);

  /// A circular skeleton, for an icon or avatar slot.
  const AuraSkeleton.circle({required double diameter, Key? key})
    : this(
        width: diameter,
        height: diameter,
        radius: AuraRadii.pill,
        key: key,
      );

  /// Block width.
  final double width;

  /// Block height.
  final double height;

  /// Corner radius.
  final double radius;

  @override
  State<AuraSkeleton> createState() => _AuraSkeletonState();
}

class _AuraSkeletonState extends State<AuraSkeleton>
    with SingleTickerProviderStateMixin {
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
    return RepaintBoundary(
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => _ShimmerBox(
            progress: _controller.value,
            radius: widget.radius,
          ),
        ),
      ),
    );
  }
}

/// Paints one frame of the shimmer sweep.
class _ShimmerBox extends StatelessWidget {
  const _ShimmerBox({required this.progress, required this.radius});

  final double progress;
  final double radius;

  @override
  Widget build(BuildContext context) {
    // The sweep travels from fully off one edge to fully off the other, so the
    // highlight never appears to pop into existence mid-block.
    final shift = progress * 2 - 1;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment(-1 + shift, -0.3),
          end: Alignment(1 + shift, 0.3),
          colors: AuraGradients.skeletonShimmer.colors,
          stops: AuraGradients.skeletonShimmer.stops,
        ),
      ),
    );
  }
}
