import 'package:aura_design/aura_design.dart';
import 'package:aura_domain/aura_domain.dart';
import 'package:aura_feature_details/src/widgets/detail_host.dart';
import 'package:aura_feature_details/src/widgets/detail_scaffold.dart';
import 'package:aura_l10n/aura_l10n.dart';
import 'package:aura_ui/aura_ui.dart';
import 'package:flutter/widgets.dart';

/// The published air quality index, and every concentration behind it.
///
/// The overall category is the US EPA's, because the service returns that index
/// directly. Each pollutant is banded against the European Air Quality Index,
/// which is published in the µg/m³ the service reports; the EPA's own
/// breakpoints are in ppm and ppb and would need an assumed temperature and
/// pressure to apply.
class AirQualityScreen extends StatelessWidget {
  /// Creates the air quality screen.
  const AirQualityScreen({required this.onBack, super.key});

  /// Goes back.
  final VoidCallback onBack;

  /// The order the design lists the pollutants in.
  static const List<Pollutant> _order = <Pollutant>[
    Pollutant.pm25,
    Pollutant.pm10,
    Pollutant.o3,
    Pollutant.no2,
    Pollutant.so2,
    Pollutant.co,
  ];

  @override
  Widget build(BuildContext context) {
    return DetailHost(
      title: context.l10n.airQualityTitle,
      sky: (state) => AuraSkyKind.systemBrand,
      onBack: onBack,
      builder: (context, state) {
        final l10n = context.l10n;
        final format = AuraFormat(l10n: l10n, units: state.units);
        final air = state.snapshot.airQuality;
        if (air == null) return <Widget>[];

        return <Widget>[
          _Hero(air: air, format: format),
          DetailSectionLabel(l10n.pollutantsLabel),
          _PollutantGrid(air: air, format: format),
        ];
      },
    );
  }
}

/// The category, where it sits on the scale, and what it means.
class _Hero extends StatelessWidget {
  const _Hero({required this.air, required this.format});

  final AirQuality air;
  final AuraFormat format;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final category = air.category;
    return DetailCard(
      gap: AuraSpacing.mdPlus,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          spacing: AuraSpacing.md,
          children: <Widget>[
            Flexible(
              child: Text(
                category == null ? '' : format.epaCategory(category),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AuraText.categoryHero.copyWith(
                  color: AuraColors.textPrimary,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: AuraSpacing.xs),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AuraSpacing.hairline,
                children: <Widget>[
                  Text(
                    l10n.airQualityIndexName,
                    maxLines: 1,
                    style: AuraText.categorySource.copyWith(
                      color: AuraColors.textPrimary,
                    ),
                  ),
                  Text(
                    l10n.airQualityLevel('${air.usEpaIndex}'),
                    maxLines: 1,
                    style: AuraText.chip.copyWith(
                      color: AuraColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        AuraIndexScaleBar(
          colors: AuraGradients.aqiScale.colors,
          stops: AuraGradients.aqiScale.stops,
          position: epaScalePosition(air.usEpaIndex),
          height: AuraSizes.indexScaleHeightLarge,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            _ScaleEnd(label: l10n.epaGood),
            _ScaleEnd(label: l10n.epaHazardous),
          ],
        ),
        if (category != null)
          Text(
            format.epaMeaning(category),
            style: AuraText.bodySmall.copyWith(
              color: AuraColors.textSecondary,
            ),
          ),
      ],
    );
  }
}

/// One end of the scale bar.
class _ScaleEnd extends StatelessWidget {
  const _ScaleEnd({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: AuraText.scaleEndLabel
          .forScript(context)
          .copyWith(color: AuraColors.textTertiary),
    );
  }
}

/// Two pollutant cards a row.
class _PollutantGrid extends StatelessWidget {
  const _PollutantGrid({required this.air, required this.format});

  final AirQuality air;
  final AuraFormat format;

  @override
  Widget build(BuildContext context) {
    final present = AirQualityScreen._order
        .where(air.concentrations.containsKey)
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AuraSpacing.md,
      children: <Widget>[
        for (var start = 0; start < present.length; start += 2)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AuraSpacing.md,
              children: <Widget>[
                for (var column = 0; column < 2; column++)
                  Expanded(
                    child: start + column < present.length
                        ? _PollutantCard(
                            pollutant: present[start + column],
                            air: air,
                            format: format,
                          )
                        : const SizedBox.shrink(),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// One pollutant: its name, its concentration, and its band.
///
/// Carbon monoxide gets no band. The European index does not cover it, and
/// converting the EPA's ppm breakpoints would mean assuming conditions the
/// service never sent, so the row shows the reading and nothing else.
class _PollutantCard extends StatelessWidget {
  const _PollutantCard({
    required this.pollutant,
    required this.air,
    required this.format,
  });

  final Pollutant pollutant;
  final AirQuality air;
  final AuraFormat format;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final value = air.concentrations[pollutant] ?? 0;
    final band = air.bandFor(pollutant);

    return DetailCard(
      radius: AuraRadii.row,
      padding: const EdgeInsets.all(AuraSpacing.mdPlus),
      gap: AuraSpacing.xs,
      children: <Widget>[
        Text(
          _name(l10n, pollutant),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AuraText.pollutantLabel
              .forScript(context)
              .copyWith(color: AuraColors.textTertiary),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          spacing: AuraSpacing.xxs,
          children: <Widget>[
            Text(
              format.concentration(value),
              maxLines: 1,
              style: AuraText.readout.copyWith(
                color: AuraColors.textPrimary,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: AuraSpacing.xxs),
              child: Text(
                l10n.unitMicrogramsPerCubicMetre,
                maxLines: 1,
                style: AuraText.unitLabel.copyWith(
                  color: AuraColors.textTertiary,
                ),
              ),
            ),
          ],
        ),
        if (band != null)
          Row(
            spacing: AuraSpacing.xs,
            children: <Widget>[
              _BandDot(band: band),
              Flexible(
                child: Text(
                  _bandName(l10n, band),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AuraText.chip.copyWith(
                    color: AuraColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  static String _name(AppLocalizations l10n, Pollutant pollutant) =>
      switch (pollutant) {
        Pollutant.pm25 => l10n.pollutantPm25,
        Pollutant.pm10 => l10n.pollutantPm10,
        Pollutant.o3 => l10n.pollutantOzone,
        Pollutant.no2 => l10n.pollutantNo2,
        Pollutant.so2 => l10n.pollutantSo2,
        Pollutant.co => l10n.pollutantCo,
      };

  static String _bandName(AppLocalizations l10n, AirBand band) =>
      switch (band) {
        AirBand.good => l10n.airBandGood,
        AirBand.fair => l10n.airBandFair,
        AirBand.moderate => l10n.airBandModerate,
        AirBand.poor => l10n.airBandPoor,
        AirBand.veryPoor => l10n.airBandVeryPoor,
        AirBand.extremelyPoor => l10n.airBandExtremelyPoor,
      };
}

/// The band's colour, from the severity ramp the design system owns.
class _BandDot extends StatelessWidget {
  const _BandDot({required this.band});

  final AirBand band;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: AuraSizes.sunPathMarker,
      child: DecoratedBox(
        decoration: BoxDecoration(
          // Six bands over a five-step ramp: the worst two share the top step,
          // which is what the design's own scale does at its end.
          color:
              AuraColors.severityScale[band.index.clamp(
                0,
                AuraColors.severityScale.length - 1,
              )],
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
