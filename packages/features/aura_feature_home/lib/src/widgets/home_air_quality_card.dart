import 'package:aura_design/aura_design.dart';
import 'package:aura_domain/aura_domain.dart';
import 'package:aura_feature_home/src/widgets/home_sections.dart';
import 'package:aura_l10n/aura_l10n.dart';
import 'package:aura_ui/aura_ui.dart';
import 'package:flutter/widgets.dart';

/// The published air-quality category, and where it sits on the scale.
///
/// The category, the scale position and the description are all the US EPA's
/// own, applied to the `us-epa-index` the service returns. The pen's closing
/// clause about being a good day to go outside is nobody's published text, so
/// it is not here.
class HomeAirQualityCard extends StatelessWidget {
  /// Creates the air quality card.
  const HomeAirQualityCard({
    required this.airQuality,
    required this.format,
    required this.onOpen,
    super.key,
  });

  /// The reading on screen.
  final AirQuality airQuality;

  /// Turns the category into copy.
  final AuraFormat format;

  /// Opens the air quality detail.
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final category = airQuality.category;
    return HomeCard(
      onTap: onOpen,
      gap: AuraSpacing.smPlus,
      children: <Widget>[
        HomeSectionHeader(
          title: context.l10n.sectionAirQuality.toUpperCase(),
          onTap: onOpen,
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          spacing: AuraSpacing.sm,
          children: <Widget>[
            Flexible(
              child: Text(
                category == null ? '' : format.epaCategory(category),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AuraText.categoryValue.copyWith(
                  color: AuraColors.textPrimary,
                ),
              ),
            ),
            Text(
              context.l10n.airQualityIndexName,
              maxLines: 1,
              style: AuraText.rowLabel.copyWith(
                color: AuraColors.textSecondary,
              ),
            ),
          ],
        ),
        AuraIndexScaleBar(
          colors: AuraGradients.aqiScale.colors,
          stops: AuraGradients.aqiScale.stops,
          position: epaScalePosition(airQuality.usEpaIndex),
        ),
        if (category != null)
          Text(
            format.epaMeaning(category),
            style: AuraText.caption.copyWith(
              color: AuraColors.textSecondary,
            ),
          ),
      ],
    );
  }
}
