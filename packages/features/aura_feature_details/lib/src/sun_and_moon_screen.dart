import 'package:aura_design/aura_design.dart';
import 'package:aura_domain/aura_domain.dart';
import 'package:aura_feature_details/src/widgets/detail_host.dart';
import 'package:aura_feature_details/src/widgets/detail_scaffold.dart';
import 'package:aura_l10n/aura_l10n.dart';
import 'package:aura_ui/aura_ui.dart';
import 'package:flutter/widgets.dart';

/// Where the sun is on its arc, and what the moon looks like tonight.
///
/// A place with no sunrise or no sunset that day is a real reading at high
/// latitude, so the arc draws empty and the times say so rather than the screen
/// pretending the sun rose.
class SunAndMoonScreen extends StatelessWidget {
  /// Creates the sun and moon screen.
  const SunAndMoonScreen({required this.onBack, super.key});

  /// Goes back.
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return DetailHost(
      title: context.l10n.sunAndMoonTitle,
      sky: (state) => AuraSkyKind.sunAndMoon,
      onBack: onBack,
      builder: (context, state) {
        final format = AuraFormat(l10n: context.l10n, units: state.units);
        final astro = state.snapshot.today.astro;
        return <Widget>[
          _SunCard(astro: astro, format: format, now: state.now),
          _MoonCard(astro: astro, format: format),
        ];
      },
    );
  }
}

/// The arc, its two ends, and how long the sun is up.
class _SunCard extends StatelessWidget {
  const _SunCard({
    required this.astro,
    required this.format,
    required this.now,
  });

  final AstroInfo astro;
  final AuraFormat format;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sunrise = astro.sunrise;
    final sunset = astro.sunset;
    final daylight = daylightSpan(sunrise: sunrise, sunset: sunset);

    return DetailCard(
      gap: AuraSpacing.xs,
      padding: const EdgeInsets.fromLTRB(
        AuraSpacing.lg,
        AuraSpacing.lg,
        AuraSpacing.lg,
        AuraSpacing.mdPlus,
      ),
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            DetailSectionLabel(l10n.astroSunSection),
            if (daylight != null)
              Text(
                l10n.astroDaylight(
                  '${daylight.inHours}',
                  '${daylight.inMinutes.remainder(60)}',
                ),
                style: AuraText.chip.copyWith(
                  color: AuraColors.textSecondary,
                ),
              ),
          ],
        ),
        AuraSunPath(
          position: sunArcPosition(
            now: now,
            sunrise: sunrise,
            sunset: sunset,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            _AstroTime(
              icon: AuraIcons.sunrise,
              tint: AuraColors.conditionSunrise,
              value: sunrise == null
                  ? l10n.astroNoSunrise
                  : format.clock(sunrise),
              label: l10n.astroSunrise,
              alignment: CrossAxisAlignment.start,
            ),
            _AstroTime(
              icon: AuraIcons.sunset,
              tint: AuraColors.conditionSunset,
              value: sunset == null ? l10n.astroNoSunset : format.clock(sunset),
              label: l10n.astroSunset,
              alignment: CrossAxisAlignment.end,
            ),
          ],
        ),
      ],
    );
  }
}

/// A time with its glyph, under the word for what it is.
class _AstroTime extends StatelessWidget {
  const _AstroTime({
    required this.icon,
    required this.tint,
    required this.value,
    required this.label,
    required this.alignment,
  });

  final IconData icon;
  final Color tint;
  final String value;
  final String label;
  final CrossAxisAlignment alignment;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignment,
      spacing: AuraSpacing.hairline,
      children: <Widget>[
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: AuraSpacing.xxsPlus,
          children: <Widget>[
            Icon(icon, size: AuraSizes.iconLabel, color: tint),
            Text(
              value,
              style: AuraText.metaValue.copyWith(
                color: AuraColors.textPrimary,
              ),
            ),
          ],
        ),
        Text(
          label.toUpperCase(),
          style: AuraText.scaleEndLabel
              .forScript(context)
              .copyWith(color: AuraColors.textTertiary),
        ),
      ],
    );
  }
}

/// The phase disc, what it is called, and when the moon is up.
class _MoonCard extends StatelessWidget {
  const _MoonCard({required this.astro, required this.format});

  final AstroInfo astro;
  final AuraFormat format;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final moonrise = astro.moonrise;
    final moonset = astro.moonset;

    return DetailCard(
      gap: AuraSpacing.mdPlus,
      padding: const EdgeInsets.all(AuraSpacing.lg),
      children: <Widget>[
        DetailSectionLabel(l10n.astroMoonSection),
        Row(
          spacing: AuraSpacing.lgPlus,
          children: <Widget>[
            AuraMoonPhase(
              illumination: astro.moonIlluminationPercent / 100,
              isWaxing: astro.moonPhase.isWaxing,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AuraSpacing.sm,
                children: <Widget>[
                  Text(
                    format.moonPhase(astro.moonPhase),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AuraText.titleCardSmall.copyWith(
                      color: AuraColors.textPrimary,
                    ),
                  ),
                  Text(
                    l10n.astroIlluminated(
                      format.percent(astro.moonIlluminationPercent),
                    ),
                    style: AuraText.cityCardCondition.copyWith(
                      color: AuraColors.textTertiary,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: AuraSpacing.xs),
                    child: Row(
                      spacing: AuraSpacing.xl,
                      children: <Widget>[
                        if (moonrise != null)
                          _MoonTime(
                            label: l10n.astroMoonrise,
                            value: format.clock(moonrise),
                          ),
                        if (moonset != null)
                          _MoonTime(
                            label: l10n.astroMoonset,
                            value: format.clock(moonset),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// A moonrise or a moonset.
class _MoonTime extends StatelessWidget {
  const _MoonTime({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AuraSpacing.hairline,
      children: <Widget>[
        Text(
          label.toUpperCase(),
          style: AuraText.scaleEndLabel
              .forScript(context)
              .copyWith(color: AuraColors.textTertiary),
        ),
        Text(
          value,
          style: AuraText.astroValue.copyWith(
            color: AuraColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
