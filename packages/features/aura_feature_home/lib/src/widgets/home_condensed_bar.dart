import 'package:aura_design/aura_design.dart';
import 'package:aura_domain/aura_domain.dart';
import 'package:aura_l10n/aura_l10n.dart';
import 'package:aura_ui/aura_ui.dart';
import 'package:flutter/widgets.dart';

/// The line the hero condenses into: the city over its reading.
///
/// Drawn twice by the screen: once invisibly, to give the collapsing header
/// its pinned height, and once floating above the scroll view, where the
/// cards dissolving into the sky cannot touch it.
class HomeCondensedBar extends StatelessWidget {
  /// Creates the condensed bar.
  const HomeCondensedBar({
    required this.snapshot,
    required this.format,
    super.key,
  });

  /// The reading on screen.
  final WeatherSnapshot snapshot;

  /// Turns the reading into copy.
  final AuraFormat format;

  /// How far the bar's type may grow with the system text size before it
  /// outgrows the band the collapse reserves for it.
  static const double _maxScale = 1.3;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AuraSpacing.xl,
        vertical: AuraSpacing.xxs,
      ),
      // Scaled down rather than clipped if the band runs out of room: a
      // slightly smaller line is invisible, a striped overflow is not.
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: MediaQuery.withClampedTextScaling(
          maxScaleFactor: _maxScale,
          child: MergeSemantics(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: AuraSpacing.hairline,
              children: <Widget>[
                Text(
                  snapshot.placeName,
                  maxLines: 1,
                  style: AuraText.titleScreen.copyWith(
                    color: AuraColors.textPrimary,
                  ),
                ),
                Text(
                  context.l10n.homeCondensedSummary(
                    format.temperature(snapshot.current.temperature),
                    snapshot.current.conditionText,
                  ),
                  maxLines: 1,
                  style: AuraText.rowLabel.copyWith(
                    color: AuraColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
