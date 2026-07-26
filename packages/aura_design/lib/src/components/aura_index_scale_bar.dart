import 'package:aura_design/src/tokens/aura_colors.dart';
import 'package:aura_design/src/tokens/aura_metrics.dart';
import 'package:flutter/widgets.dart';

/// A severity ramp with a marker showing where a reading falls on it.
///
/// Deliberately not the same component as `AuraScaleBar`. The pen draws the
/// ultraviolet ramp with no marker at all, because the reading is the card's
/// own value, and the air-quality ramp with one, because the category alone
/// does not say how far along the scale it sits. Merging them would mean a
/// marker that is sometimes absent, which is two components wearing one name.
///
/// [position] is a fraction of the track, worked out by the domain from a
/// published index. The marker is inset by its own width, so a reading at
/// either end of the scale stays fully on the bar.
class AuraIndexScaleBar extends StatelessWidget {
  /// Creates an index scale bar.
  const AuraIndexScaleBar({
    required this.colors,
    required this.stops,
    required this.position,
    this.height = AuraSizes.indexScaleHeight,
    super.key,
  });

  /// Ramp colours, from the lowest severity up.
  final List<Color> colors;

  /// Ramp stops, matching [colors] by index.
  final List<double> stops;

  /// Where the reading falls, from 0 to 1.
  final double position;

  /// Track thickness.
  final double height;

  /// Marker diameter, including its stroke.
  static const double _markerExtent =
      AuraSizes.scaleIndicator + AuraSizes.scaleIndicatorStroke * 2;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Stack(
        // The marker is taller than the track and overhangs it on both edges,
        // exactly as the pen draws it.
        clipBehavior: Clip.none,
        alignment: AlignmentDirectional.center,
        children: <Widget>[
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(height / 2),
              gradient: LinearGradient(
                begin: AlignmentDirectional.centerStart,
                end: AlignmentDirectional.centerEnd,
                colors: colors,
                stops: stops,
              ),
            ),
            child: const SizedBox.expand(),
          ),
          Align(
            alignment: AlignmentDirectional(
              position.clamp(0.0, 1.0) * 2 - 1,
              0,
            ),
            child: const _Marker(),
          ),
        ],
      ),
    );
  }
}

/// The white dot, ringed so it reads over any band beneath it.
class _Marker extends StatelessWidget {
  const _Marker();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AuraIndexScaleBar._markerExtent,
      height: AuraIndexScaleBar._markerExtent,
      decoration: const BoxDecoration(
        color: AuraColors.scaleIndicatorStroke,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Container(
          width: AuraSizes.scaleIndicator,
          height: AuraSizes.scaleIndicator,
          decoration: const BoxDecoration(
            color: AuraColors.scaleIndicator,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
