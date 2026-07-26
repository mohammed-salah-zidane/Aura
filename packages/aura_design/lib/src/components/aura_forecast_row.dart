import 'package:aura_design/src/foundations/aura_glass.dart';
import 'package:aura_design/src/tokens/aura_colors.dart';
import 'package:aura_design/src/tokens/aura_gradients.dart';
import 'package:aura_design/src/tokens/aura_metrics.dart';
import 'package:aura_design/src/tokens/aura_typography.dart';
import 'package:flutter/widgets.dart';

/// One day in the forecast list.
///
/// The range bar takes [rangeStart] and [rangeExtent] as fractions of the
/// forecast period, already worked out by the domain. Keeping the arithmetic
/// out of the widget lets the bar be tested as geometry and the span be tested
/// as a pure function, separately.
class AuraForecastRow extends StatelessWidget {
  /// Creates a forecast row.
  const AuraForecastRow({
    required this.day,
    required this.icon,
    required this.iconTint,
    required this.low,
    required this.high,
    required this.rangeStart,
    required this.rangeExtent,
    this.rainProbability,
    super.key,
  });

  /// Day name, or the word for today.
  final String day;

  /// Condition glyph.
  final IconData icon;

  /// Tint for the condition glyph.
  final Color iconTint;

  /// Daily low, already formatted for the active unit.
  final String low;

  /// Daily high, already formatted for the active unit.
  final String high;

  /// Where this day's range begins, from 0 to 1 of the period span.
  final double rangeStart;

  /// How much of the period span this day's range covers, from 0 to 1.
  final double rangeExtent;

  /// Rain chance, shown only when the API reports one above zero.
  final String? rainProbability;

  static const double _dayWidth = 46;
  static const double _rainWidth = 34;
  static const double _lowWidth = 34;
  static const double _highWidth = 30;

  @override
  Widget build(BuildContext context) {
    return AuraGlass.flat(
      height: AuraSizes.forecastRowHeight,
      padding: const EdgeInsets.symmetric(horizontal: AuraSpacing.lg),
      child: Row(
        spacing: AuraSpacing.sm,
        children: <Widget>[
          SizedBox(
            width: _dayWidth,
            child: Text(
              day,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AuraText.forecastDay.copyWith(
                color: AuraColors.textSecondary,
              ),
            ),
          ),
          Icon(icon, size: AuraSizes.iconConditionSmall, color: iconTint),
          SizedBox(
            width: _rainWidth,
            child: rainProbability == null
                ? null
                : Text(
                    rainProbability!,
                    maxLines: 1,
                    style: AuraText.numericLabel.copyWith(
                      color: AuraColors.rainProbability,
                    ),
                  ),
          ),
          SizedBox(
            width: _lowWidth,
            child: Text(
              low,
              maxLines: 1,
              textAlign: TextAlign.right,
              style: AuraText.forecastLow.copyWith(
                color: AuraColors.textTertiary,
              ),
            ),
          ),
          Expanded(
            child: AuraRangeBar(start: rangeStart, extent: rangeExtent),
          ),
          SizedBox(
            width: _highWidth,
            child: Text(
              high,
              maxLines: 1,
              textAlign: TextAlign.right,
              style: AuraText.forecastHigh.copyWith(
                color: AuraColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The cold-to-hot segment on a track, showing where a day's range sits inside
/// the whole forecast period.
class AuraRangeBar extends StatelessWidget {
  /// Creates a range bar.
  const AuraRangeBar({required this.start, required this.extent, super.key});

  /// Left edge of the segment, from 0 to 1.
  final double start;

  /// Segment width, from 0 to 1.
  final double extent;

  @override
  Widget build(BuildContext context) {
    final clampedStart = start.clamp(0.0, 1.0);
    // A day whose high equals its low would otherwise vanish, so the segment
    // keeps a visible minimum.
    final clampedExtent = extent.clamp(0.04, 1.0 - clampedStart);
    return SizedBox(
      height: AuraSizes.rangeBarHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AuraColors.rangeBarTrack,
          borderRadius: BorderRadius.circular(AuraRadii.bar),
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            alignment: Alignment(clampedStart * 2 - 1, 0),
            widthFactor: clampedExtent,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AuraRadii.bar),
                gradient: LinearGradient(
                  colors: AuraGradients.temperatureRange.colors,
                  stops: AuraGradients.temperatureRange.stops,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One hour in the hourly strip.
class AuraHourCell extends StatelessWidget {
  /// Creates an hour cell.
  const AuraHourCell({
    required this.time,
    required this.icon,
    required this.iconTint,
    required this.temperature,
    this.isNow = false,
    super.key,
  });

  /// Hour label, or the word for now.
  final String time;

  /// Condition glyph.
  final IconData icon;

  /// Tint for the condition glyph.
  final Color iconTint;

  /// Temperature, already formatted for the active unit.
  final String temperature;

  /// Whether this cell is the current hour, which the design draws heavier.
  final bool isNow;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AuraSpacing.xxs,
        horizontal: AuraSpacing.sm,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: AuraSpacing.smPlus,
        children: <Widget>[
          Text(
            time,
            style: (isNow ? AuraText.hourTimeNow : AuraText.hourTime).copyWith(
              color: isNow ? AuraColors.textPrimary : AuraColors.textSecondary,
            ),
          ),
          Icon(icon, size: AuraSizes.iconCondition, color: iconTint),
          Text(
            temperature,
            style: AuraText.temperature.copyWith(
              color: AuraColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
