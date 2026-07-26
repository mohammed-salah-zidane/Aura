import 'package:aura_design/src/foundations/aura_sky.dart';
import 'package:aura_design/src/tokens/aura_colors.dart';
import 'package:aura_design/src/tokens/aura_icons.dart';
import 'package:aura_design/src/tokens/aura_metrics.dart';
import 'package:aura_design/src/tokens/aura_shadows.dart';
import 'package:aura_design/src/tokens/aura_typography.dart';
import 'package:flutter/widgets.dart';

/// A saved city, painted with that city's own sky.
///
/// The temperature uses Outfit rather than Fraunces. The design-system board's
/// sample of this component shows Fraunces, but all four cards on the saved
/// cities screen use Outfit, and the screens are what ship. Do not "correct"
/// this to Fraunces.
class AuraCityCard extends StatelessWidget {
  /// Creates a city card.
  const AuraCityCard({
    required this.city,
    required this.localTime,
    required this.condition,
    required this.temperature,
    required this.highLow,
    required this.sky,
    this.onTap,
    this.onRemove,
    this.removeSemanticLabel,
    super.key,
  });

  /// City name.
  final String city;

  /// Local time in that city, or a label marking it as the current location.
  final String localTime;

  /// Condition text, straight from the API.
  final String condition;

  /// Current temperature, already formatted for the active unit.
  final String temperature;

  /// High and low pair, already formatted.
  final String highLow;

  /// Which sky this city currently has.
  final AuraSkyKind sky;

  /// Tap handler.
  final VoidCallback? onTap;

  /// Forgets this place. Shown only while the list is being edited.
  ///
  /// The design draws no delete affordance, and a saved list with no way to
  /// unsave is not a list. The glyph is the pen's own dismiss cross.
  final VoidCallback? onRemove;

  /// What removing does, for assistive technology.
  final String? removeSemanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: '$city, $condition, $temperature',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: AuraSizes.cityCardHeight,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AuraRadii.card),
            boxShadow: AuraShadows.tileStrong,
            // The card is angled rather than vertical, which is what stops a
            // list of them reading as a stack of identical panels.
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: sky.gradient.colors,
              stops: sky.gradient.stops,
            ),
          ),
          padding: const EdgeInsets.symmetric(
            vertical: AuraSpacing.lg,
            horizontal: AuraSpacing.lgPlus,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: AuraSpacing.hairline,
                      children: <Widget>[
                        Text(
                          city,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AuraText.titleCard.copyWith(
                            color: AuraColors.textPrimary,
                          ),
                        ),
                        Text(
                          localTime,
                          maxLines: 1,
                          style: AuraText.cityCardHighLow.copyWith(
                            color: AuraColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      condition,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AuraText.cityCardCondition.copyWith(
                        color: AuraColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  if (onRemove == null)
                    Text(
                      temperature,
                      style: AuraText.cityCardTemperature.copyWith(
                        color: AuraColors.textPrimary,
                      ),
                    )
                  else
                    Semantics(
                      button: true,
                      label: removeSemanticLabel,
                      child: GestureDetector(
                        onTap: onRemove,
                        child: const Icon(
                          AuraIcons.close,
                          size: AuraSizes.iconMedium,
                          color: AuraColors.textPrimary,
                        ),
                      ),
                    ),
                  Text(
                    highLow,
                    style: AuraText.cityCardHighLow.copyWith(
                      color: AuraColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
