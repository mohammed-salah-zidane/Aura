import 'package:aura_design/aura_design.dart';
import 'package:aura_domain/aura_domain.dart';
import 'package:aura_l10n/aura_l10n.dart';
import 'package:aura_ui/aura_ui.dart';
import 'package:flutter/widgets.dart';

/// The wordmark and the way into settings, above the hero.
class HomeBrandBar extends StatelessWidget {
  /// Creates the brand bar.
  const HomeBrandBar({required this.onOpenSettings, super.key});

  /// Opens the settings screen.
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Row(
          spacing: AuraSpacing.sm,
          children: <Widget>[
            const AuraMark(size: AuraMarkSize.brandBar),
            Text(
              AuraBrand.name,
              style: AuraText.wordmarkSmall.copyWith(
                color: AuraColors.textPrimary,
              ),
            ),
          ],
        ),
        AuraCircleButton(
          icon: AuraIcons.settings,
          semanticLabel: context.l10n.homeSettings,
          onPressed: onOpenSettings,
        ),
      ],
    );
  }
}

/// The place, the temperature and the condition, centred.
///
/// The pen's narrative line under the condition has no field behind it, so the
/// slot is left out rather than filled with a sentence the service never sent.
class HomeHero extends StatelessWidget {
  /// Creates the hero.
  const HomeHero({
    required this.snapshot,
    required this.isCurrentLocation,
    required this.format,
    super.key,
  });

  /// The reading on screen.
  final WeatherSnapshot snapshot;

  /// Whether this place is wherever the device is.
  final bool isCurrentLocation;

  /// Turns the reading into copy.
  final AuraFormat format;

  /// The pen's `Hero` frame padding.
  static const EdgeInsets _padding = EdgeInsets.only(
    top: AuraSpacing.sm,
    bottom: AuraSpacing.xxs,
  );

  @override
  Widget build(BuildContext context) {
    final current = snapshot.current;
    final today = snapshot.today;
    return Padding(
      padding: _padding,
      child: Column(
        spacing: AuraSpacing.hairline,
        children: <Widget>[
          _Kicker(
            label: isCurrentLocation
                ? context.l10n.homeCurrentLocation
                : snapshot.country,
          ),
          Text(
            snapshot.placeName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AuraText.titleCity.copyWith(color: AuraColors.textPrimary),
          ),
          Text(
            format.temperature(current.temperature),
            maxLines: 1,
            style: AuraText.display.copyWith(color: AuraColors.textPrimary),
          ),
          Text(
            current.conditionText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AuraText.condition.copyWith(
              color: AuraColors.textSecondary,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: AuraSpacing.xs),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: AuraSpacing.mdPlus,
              children: <Widget>[
                Text(
                  format.high(today.high),
                  style: AuraText.valueCompact.copyWith(
                    color: AuraColors.textPrimary,
                  ),
                ),
                Text(
                  format.low(today.low),
                  style: AuraText.valueCompact.copyWith(
                    color: AuraColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The pin and the tracked label above the city name.
class _Kicker extends StatelessWidget {
  const _Kicker({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: AuraSpacing.xxs,
      children: <Widget>[
        const Icon(
          AuraIcons.mapPin,
          size: AuraSizes.iconCaption,
          color: AuraColors.textTertiary,
        ),
        Flexible(
          child: Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AuraText.kicker
                .forScript(context)
                .copyWith(color: AuraColors.textTertiary),
          ),
        ),
      ],
    );
  }
}
