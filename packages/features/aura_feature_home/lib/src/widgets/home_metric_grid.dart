import 'package:aura_design/aura_design.dart';
import 'package:aura_domain/aura_domain.dart';
import 'package:aura_l10n/aura_l10n.dart';
import 'package:aura_ui/aura_ui.dart';
import 'package:flutter/widgets.dart';

/// The six readings the design puts under the hourly strip.
///
/// Two of the pen's sub-lines are descriptions rather than readings, and
/// WeatherAPI has no field behind either: an apparent temperature has nothing
/// second to say, and neither does a visibility. Those two slots are left
/// empty. The other four carry the field the design was standing in for.
class HomeMetricGrid extends StatelessWidget {
  /// Creates the metric grid.
  const HomeMetricGrid({
    required this.current,
    required this.format,
    super.key,
  });

  /// The reading on screen.
  final CurrentConditions current;

  /// Turns each reading into copy.
  final AuraFormat format;

  /// Where the grid gains a column. The design canvas is 393 points wide and
  /// draws two; a tablet has room for more.
  static const double _threeColumnWidth = 600;

  /// Where it gains its fourth.
  static const double _fourColumnWidth = 900;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cards = <Widget>[
      AuraMetricCard(
        icon: AuraIcons.thermometer,
        label: l10n.metricFeelsLike.toUpperCase(),
        value: format.temperature(current.feelsLike),
      ),
      AuraMetricCard(
        icon: AuraIcons.wind,
        label: l10n.metricWind.toUpperCase(),
        value: format.speed(current.windSpeed),
        sub: l10n.metricWindSub(
          current.windDirection,
          format.speedValue(current.gustSpeed),
        ),
      ),
      AuraMetricCard(
        icon: AuraIcons.droplets,
        label: l10n.metricHumidity.toUpperCase(),
        value: format.percent(current.humidityPercent),
        sub: l10n.metricDewPoint(format.temperature(current.dewPoint)),
      ),
      AuraMetricCard(
        icon: AuraIcons.sun,
        label: l10n.metricUvIndex.toUpperCase(),
        value: format.uvIndex(current.uvIndex),
        scale: AuraScaleBar(
          colors: AuraGradients.uvScale.colors,
          stops: AuraGradients.uvScale.stops,
        ),
        sub: format.uvBand(current.uvSeverity),
      ),
      AuraMetricCard(
        icon: AuraIcons.eye,
        label: l10n.metricVisibility.toUpperCase(),
        value: format.distance(current.visibility),
      ),
      AuraMetricCard(
        icon: AuraIcons.gauge,
        label: l10n.metricPressure.toUpperCase(),
        value: format.pressure(current.pressure),
        sub: format.pressureInches(current.pressureInchesOfMercury),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = switch (constraints.maxWidth) {
          >= _fourColumnWidth => 4,
          >= _threeColumnWidth => 3,
          _ => 2,
        };
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AuraSpacing.md,
          children: <Widget>[
            for (var start = 0; start < cards.length; start += columns)
              // The row sits in a scroll view, so its height is unbounded.
              // IntrinsicHeight bounds it to the tallest card, which is what
              // lets the shorter ones stretch to match rather than float.
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: AuraSpacing.md,
                  children: <Widget>[
                    for (var column = 0; column < columns; column++)
                      Expanded(
                        child: start + column < cards.length
                            ? cards[start + column]
                            : const SizedBox.shrink(),
                      ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
