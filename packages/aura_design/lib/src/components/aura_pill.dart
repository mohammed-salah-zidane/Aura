import 'package:aura_design/src/foundations/aura_glass.dart';
import 'package:aura_design/src/foundations/aura_script.dart';
import 'package:aura_design/src/tokens/aura_colors.dart';
import 'package:aura_design/src/tokens/aura_metrics.dart';
import 'package:aura_design/src/tokens/aura_typography.dart';
import 'package:flutter/widgets.dart';

/// A capsule marking data as live.
///
/// Only shown when the data on screen came from the network on this run. Cached
/// data must not wear it, otherwise the one signal the user has about freshness
/// stops meaning anything.
class AuraPillLive extends StatelessWidget {
  /// Creates a live pill.
  const AuraPillLive({required this.label, super.key});

  /// Pill text, typically `LIVE`.
  final String label;

  @override
  Widget build(BuildContext context) {
    return AuraGlass.flat(
      radius: AuraRadii.pill,
      padding: const EdgeInsets.fromLTRB(9, 6, 10, 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: AuraSpacing.xs,
        children: <Widget>[
          Container(
            width: AuraSizes.liveDot,
            height: AuraSizes.liveDot,
            decoration: const BoxDecoration(
              color: AuraColors.accent,
              shape: BoxShape.circle,
            ),
          ),
          Text(
            label,
            style: AuraText.pillLabel
                .forScript(context)
                .copyWith(color: AuraColors.accent),
          ),
        ],
      ),
    );
  }
}

/// A glass capsule carrying a short piece of supporting text.
class AuraChip extends StatelessWidget {
  /// Creates a chip.
  const AuraChip({required this.label, this.icon, super.key});

  /// Chip text.
  final String label;

  /// Optional leading icon.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return AuraGlass.flat(
      radius: AuraRadii.pill,
      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: AuraSpacing.xs,
        children: <Widget>[
          if (icon != null)
            Icon(
              icon,
              size: AuraSizes.iconLabel,
              color: AuraColors.textTertiary,
            ),
          Text(
            label,
            style: AuraText.chip.copyWith(color: AuraColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
