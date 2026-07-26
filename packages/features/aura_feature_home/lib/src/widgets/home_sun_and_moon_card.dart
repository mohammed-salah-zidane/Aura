import 'package:aura_design/aura_design.dart';
import 'package:aura_domain/aura_domain.dart';
import 'package:aura_feature_home/src/widgets/home_sections.dart';
import 'package:aura_l10n/aura_l10n.dart';
import 'package:aura_ui/aura_ui.dart';
import 'package:flutter/widgets.dart';

/// Sunrise, sunset and the moon, in three columns.
///
/// A place that has no sunrise or no sunset on the day is a real reading at
/// high latitude rather than a parse failure, so that column shows no time.
class HomeSunAndMoonCard extends StatelessWidget {
  /// Creates the sun and moon card.
  const HomeSunAndMoonCard({
    required this.astro,
    required this.format,
    required this.onOpen,
    super.key,
  });

  /// Today's sun and moon times.
  final AstroInfo astro;

  /// Turns each time into copy.
  final AuraFormat format;

  /// Opens the sun and moon detail.
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sunrise = astro.sunrise;
    final sunset = astro.sunset;
    return HomeCard(
      onTap: onOpen,
      children: <Widget>[
        HomeSectionHeader(title: l10n.sectionSunAndMoon.toUpperCase()),
        Row(
          children: <Widget>[
            Expanded(
              child: _AstroColumn(
                icon: AuraIcons.sunrise,
                tint: AuraColors.conditionSunrise,
                value: sunrise == null ? '' : format.clock(sunrise),
                label: l10n.astroSunrise,
              ),
            ),
            const _Divider(),
            Expanded(
              child: _AstroColumn(
                icon: AuraIcons.sunset,
                tint: AuraColors.conditionSunset,
                value: sunset == null ? '' : format.clock(sunset),
                label: l10n.astroSunset,
              ),
            ),
            const _Divider(),
            Expanded(
              child: _AstroColumn(
                icon: AuraIcons.moon,
                tint: AuraColors.conditionMoonPhase,
                value: format.percent(astro.moonIlluminationPercent),
                label: format.moonPhase(astro.moonPhase),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// One reading and the word for what it is.
class _AstroColumn extends StatelessWidget {
  const _AstroColumn({
    required this.icon,
    required this.tint,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color tint;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: AuraSpacing.xxsPlus,
      children: <Widget>[
        Icon(icon, size: AuraSizes.iconConditionSmall, color: tint),
        Text(
          value,
          maxLines: 1,
          style: AuraText.valueCompact.copyWith(
            color: AuraColors.textPrimary,
          ),
        ),
        Text(
          label.toUpperCase(),
          // A moon phase is two words. Wrapping reads; clipping "Waxing
          // Crescent" to "WAXING CRESC…" does not.
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: AuraText.astroLabel
              .forScript(context)
              .copyWith(color: AuraColors.textTertiary),
        ),
      ],
    );
  }
}

/// The hairline between two columns.
class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: AuraSizes.divider,
      height: AuraSizes.astroDividerHeight,
      child: ColoredBox(color: AuraColors.grid),
    );
  }
}
