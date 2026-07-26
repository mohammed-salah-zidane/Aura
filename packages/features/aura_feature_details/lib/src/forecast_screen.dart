import 'package:aura_design/aura_design.dart';
import 'package:aura_domain/aura_domain.dart';
import 'package:aura_feature_details/src/widgets/detail_host.dart';
import 'package:aura_l10n/aura_l10n.dart';
import 'package:aura_ui/aura_ui.dart';
import 'package:flutter/widgets.dart';

/// Every forecast day, with each day's range placed on a shared track.
///
/// The frame is named `Forecast · 10-Day` and holds three days, with its own
/// footnote saying why. Three is what the free tier returns, so three is what
/// ships and the title says so.
///
/// The frame's own sky is the clear-day gradient under a slightly different
/// bloom. The screen follows the live condition instead: this is the same
/// reading home is showing, and a forecast that is always sunny behind a
/// thunderstorm would be the one screen in the app whose sky lies. The
/// differing bloom is designer drift on a single frame.
class ForecastScreen extends StatelessWidget {
  /// Creates the forecast screen.
  const ForecastScreen({required this.onBack, super.key});

  /// Goes back.
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return DetailHost(
      title: context.l10n.forecastTitle,
      sky: (state) =>
          AuraConditionVisuals.sky(state.snapshot.current.condition),
      onBack: onBack,
      builder: (context, state) {
        final l10n = context.l10n;
        final format = AuraFormat(l10n: l10n, units: state.units);
        final days = state.snapshot.days;
        final period = _period(days);

        return <Widget>[
          AuraGlass(
            radius: AuraRadii.detailPanel,
            shadow: AuraShadows.panel,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AuraRadii.detailPanel),
              child: Column(
                children: <Widget>[
                  for (final (index, day) in days.indexed) ...<Widget>[
                    if (index > 0) const _Divider(),
                    _Row(
                      day: day,
                      format: format,
                      isToday: index == 0,
                      period: period,
                    ),
                  ],
                ],
              ),
            ),
          ),
          _TierNote(text: l10n.forecastTierNote),
        ];
      },
    );
  }

  /// The coldest and warmest readings across the period, which is what makes
  /// the rows comparable to each other.
  static ({double low, double high}) _period(List<ForecastDay> days) {
    var low = days.first.low.celsius;
    var high = days.first.high.celsius;
    for (final day in days) {
      low = day.low.celsius < low ? day.low.celsius : low;
      high = day.high.celsius > high ? day.high.celsius : high;
    }
    return (low: low, high: high);
  }
}

/// One day.
class _Row extends StatelessWidget {
  const _Row({
    required this.day,
    required this.format,
    required this.isToday,
    required this.period,
  });

  final ForecastDay day;
  final AuraFormat format;
  final bool isToday;
  final ({double low, double high}) period;

  @override
  Widget build(BuildContext context) {
    final bar = rangeBarGeometry(
      low: day.low.celsius,
      high: day.high.celsius,
      periodLow: period.low,
      periodHigh: period.high,
    );
    return AuraForecastRow(
      day: format.day(day.date, isToday: isToday),
      isToday: isToday,
      icon: AuraConditionVisuals.icon(day.condition),
      iconTint: AuraConditionVisuals.tint(day.condition),
      low: format.temperature(day.low),
      high: format.temperature(day.high),
      rangeStart: bar.start,
      rangeExtent: bar.extent,
      // The service reports a chance every day, including zero. A zero has
      // nothing to say, so the slot stays empty rather than reading "0%".
      rainProbability: day.chanceOfRainPercent > 0
          ? format.percent(day.chanceOfRainPercent)
          : null,
    );
  }
}

/// The hairline between two days.
class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: AuraSizes.divider,
      child: ColoredBox(color: AuraColors.glass),
    );
  }
}

/// What the free tier allows, which is why there are three days and not ten.
class _TierNote extends StatelessWidget {
  const _TierNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AuraSpacing.xxs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AuraSpacing.sm,
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.only(top: AuraSpacing.hairline),
            child: Icon(
              AuraIcons.info,
              size: AuraSizes.iconNote,
              color: AuraColors.textTertiary,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: AuraText.bodyTight.copyWith(
                color: AuraColors.textTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
