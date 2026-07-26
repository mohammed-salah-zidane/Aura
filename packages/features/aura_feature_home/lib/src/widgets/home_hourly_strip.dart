import 'package:aura_design/aura_design.dart';
import 'package:aura_domain/aura_domain.dart';
import 'package:aura_l10n/aura_l10n.dart';
import 'package:aura_ui/aura_ui.dart';
import 'package:flutter/widgets.dart';

/// The next day of hours, starting at the one happening now.
///
/// The pen draws six cells across the panel because a frame cannot scroll.
/// WeatherAPI returns twenty-four hours a day and the strip is the only place
/// they are shown, so the cells run in a scrolling row at the pen's own
/// spacing rather than the day being cut to what fits.
class HomeHourlyStrip extends StatelessWidget {
  /// Creates the hourly strip.
  const HomeHourlyStrip({
    required this.hours,
    required this.sunset,
    required this.format,
    super.key,
  });

  /// The hours to draw, soonest first.
  final List<HourlyPoint> hours;

  /// Today's sunset, which one cell is drawn for.
  final DateTime? sunset;

  /// Turns each hour into copy.
  final AuraFormat format;

  /// The pen sets 29.6 points between the cells of the strip. Each cell
  /// carries 8 of its own on either side, so the list adds the rest.
  static const double _gap = AuraSpacing.mdPlus;

  @override
  Widget build(BuildContext context) {
    return AuraGlass(
      radius: AuraRadii.panel,
      shadow: AuraShadows.panelStrong,
      padding: const EdgeInsets.all(AuraSpacing.lg),
      // The row is built in one pass rather than lazily, and takes its height
      // from the cells rather than a number: the window is capped at a day, and
      // a hard-coded height is one font metric away from clipping a glyph.
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          spacing: _gap,
          children: <Widget>[
            for (final (index, hour) in hours.indexed)
              AuraHourCell(
                time: index == 0
                    ? context.l10n.hourNow
                    : format.hour(hour.time),
                icon: AuraConditionVisuals.hourIcon(
                  hour.condition,
                  isSunset: isSunsetHour(hour.time, sunset),
                ),
                iconTint: AuraConditionVisuals.hourTint(
                  hour.condition,
                  isSunset: isSunsetHour(hour.time, sunset),
                ),
                temperature: format.temperature(hour.temperature),
                isNow: index == 0,
              ),
          ],
        ),
      ),
    );
  }
}
