import 'package:aura_design/src/foundations/aura_glass.dart';
import 'package:aura_design/src/foundations/aura_script.dart';
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
      // The pen's 116 is the height every card is drawn at, and a floor rather
      // than a ceiling: the ultraviolet card carries a scale bar as well as a
      // sub-line, and a font whose metrics run a point tall would clip it.
      constraints: const BoxConstraints(
        minHeight: AuraSizes.metricCardHeight,
      ),
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
                  style: AuraText.label
                      .forScript(context)
                      .copyWith(color: AuraColors.textTertiary),
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

/// The four-point severity ramp under a UV reading.
///
/// The bar carries no marker. In the pen it is the whole ramp, drawn once, with
/// the reading itself shown as the card's value and its band as the sub-line.
class AuraScaleBar extends StatelessWidget {
  /// Creates a scale bar.
  const AuraScaleBar({required this.colors, required this.stops, super.key});

  /// Ramp colours.
  final List<Color> colors;

  /// Ramp stops.
  final List<double> stops;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AuraSizes.scaleBarHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AuraRadii.bar),
          gradient: LinearGradient(
            begin: AlignmentDirectional.centerStart,
            end: AlignmentDirectional.centerEnd,
            colors: colors,
            stops: stops,
          ),
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}
