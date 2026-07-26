import 'package:aura_design/src/foundations/aura_glass.dart';
import 'package:aura_design/src/tokens/aura_colors.dart';
import 'package:aura_design/src/tokens/aura_metrics.dart';
import 'package:aura_design/src/tokens/aura_typography.dart';
import 'package:flutter/widgets.dart';

/// One reading from the current conditions.
///
/// [sub] is optional on purpose. Where WeatherAPI returns a second field for a
/// metric it is shown; where it does not, the slot is left empty rather than
/// filled with a phrase the API never sent.
class AuraMetricCard extends StatelessWidget {
  /// Creates a metric card.
  const AuraMetricCard({
    required this.icon,
    required this.label,
    required this.value,
    this.sub,
    this.scale,
    super.key,
  });

  /// Leading icon in the label row.
  final IconData icon;

  /// Metric name, drawn in caps.
  final String label;

  /// The reading itself.
  final String value;

  /// Second line, when the API provides one.
  final String? sub;

  /// Optional scale bar, used by the UV variant.
  final Widget? scale;

  @override
  Widget build(BuildContext context) {
    return AuraGlass(
      height: AuraSizes.metricCard.height,
      padding: const EdgeInsets.all(AuraSpacing.mdPlus),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Row(
            spacing: AuraSpacing.xs,
            children: <Widget>[
              Icon(
                icon,
                size: AuraSizes.iconLabel,
                color: AuraColors.textTertiary,
              ),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AuraText.label.copyWith(
                    color: AuraColors.textTertiary,
                  ),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AuraSpacing.xxs,
            children: <Widget>[
              Text(
                value,
                maxLines: 1,
                style: AuraText.metricValue.copyWith(
                  color: AuraColors.textPrimary,
                ),
              ),
              ?scale,
              if (sub != null)
                Text(
                  sub!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AuraText.metricSub.copyWith(
                    color: AuraColors.textSecondary,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The four-point severity bar under a UV reading.
///
/// [position] is a fraction of the bar, already resolved by the domain from the
/// UV value. The bar itself knows nothing about UV bands.
class AuraScaleBar extends StatelessWidget {
  /// Creates a scale bar.
  const AuraScaleBar({
    required this.position,
    required this.colors,
    required this.stops,
    super.key,
  });

  /// Where the marker sits, from 0 to 1.
  final double position;

  /// Ramp colours.
  final List<Color> colors;

  /// Ramp stops.
  final List<double> stops;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AuraRadii.bar),
      child: SizedBox(
        height: AuraSizes.scaleBarHeight,
        child: Stack(
          children: <Widget>[
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: colors, stops: stops),
              ),
              child: const SizedBox.expand(),
            ),
            // Everything past the reading is dimmed, so the filled portion
            // reads as the current level rather than the whole scale.
            Align(
              alignment: Alignment.centerRight,
              child: FractionallySizedBox(
                widthFactor: (1 - position).clamp(0.0, 1.0),
                child: const ColoredBox(color: Color(0x8A000000)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
