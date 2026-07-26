import 'package:aura_design/aura_design.dart';
import 'package:aura_domain/aura_domain.dart';
import 'package:aura_feature_home/src/widgets/home_sections.dart';
import 'package:aura_l10n/aura_l10n.dart';
import 'package:aura_ui/aura_ui.dart';
import 'package:flutter/widgets.dart';

/// The forecast at a glance, one column a day.
///
/// Three days, because that is what the free tier returns. The card opens the
/// full forecast.
class HomeForecastPreview extends StatelessWidget {
  /// Creates the forecast preview.
  const HomeForecastPreview({
    required this.days,
    required this.format,
    required this.onOpen,
    super.key,
  });

  /// The forecast days, soonest first.
  final List<ForecastDay> days;

  /// Turns each day into copy.
  final AuraFormat format;

  /// Opens the full forecast.
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return HomeCard(
      onTap: onOpen,
      children: <Widget>[
        HomeSectionHeader(
          title: context.l10n.sectionForecast.toUpperCase(),
          onTap: onOpen,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            for (final (index, day) in days.indexed)
              _DayColumn(
                day: day,
                format: format,
                isToday: index == 0,
              ),
          ],
        ),
      ],
    );
  }
}

/// One day: its name, its glyph, and its high over its low.
class _DayColumn extends StatelessWidget {
  const _DayColumn({
    required this.day,
    required this.format,
    required this.isToday,
  });

  final ForecastDay day;
  final AuraFormat format;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: AuraSpacing.xsPlus,
      children: <Widget>[
        Text(
          format.day(day.date, isToday: isToday),
          maxLines: 1,
          style: AuraText.chip.copyWith(color: AuraColors.textSecondary),
        ),
        Icon(
          AuraConditionVisuals.icon(day.condition),
          size: AuraSizes.iconConditionSmall,
          color: AuraConditionVisuals.tint(day.condition),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          spacing: AuraSpacing.micro,
          children: <Widget>[
            Text(
              format.temperature(day.high),
              maxLines: 1,
              style: AuraText.forecastTemperatureSmall.copyWith(
                color: AuraColors.textPrimary,
              ),
            ),
            Text(
              format.temperature(day.low),
              maxLines: 1,
              style: AuraText.caption.copyWith(
                color: AuraColors.textTertiary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
