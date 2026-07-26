import 'package:aura_design/src/foundations/aura_glass.dart';
import 'package:aura_design/src/tokens/aura_colors.dart';
import 'package:aura_design/src/tokens/aura_icons.dart';
import 'package:aura_design/src/tokens/aura_metrics.dart';
import 'package:aura_design/src/tokens/aura_typography.dart';
import 'package:flutter/widgets.dart';

/// A tinted banner for an active weather alert.
///
/// Only shown when `alerts.alert[]` came back non-empty. There is no decorative
/// or example variant.
class AuraAlertBanner extends StatelessWidget {
  /// Creates an alert banner.
  const AuraAlertBanner({
    required this.title,
    required this.subtitle,
    this.onTap,
    super.key,
  });

  /// Alert event name, from the API.
  final String title;

  /// Supporting line, such as when the alert expires.
  final String subtitle;

  /// Tap handler, opening the alert detail.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      child: GestureDetector(
        onTap: onTap,
        child: AuraGlass(
          radius: AuraRadii.button,
          borderColor: AuraColors.alertBorder,
          shadow: const <BoxShadow>[],
          padding: const EdgeInsets.symmetric(
            vertical: AuraSpacing.md,
            horizontal: AuraSpacing.mdPlus,
          ),
          child: Row(
            spacing: AuraSpacing.smPlus,
            children: <Widget>[
              const Icon(
                AuraIcons.alert,
                size: 20,
                color: AuraColors.alertIcon,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 1,
                  children: <Widget>[
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AuraText.alertTitle.copyWith(
                        color: AuraColors.textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AuraText.caption.copyWith(
                        color: AuraColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                const Icon(
                  AuraIcons.chevronRight,
                  size: AuraSizes.iconUi,
                  color: AuraColors.textSecondary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A row in a settings group.
///
/// Exactly one of [value] or [trailing] is used. A row that shows a value opens
/// a picker; a row that carries a control acts in place.
class AuraSettingsRow extends StatelessWidget {
  /// Creates a settings row.
  const AuraSettingsRow({
    required this.icon,
    required this.label,
    this.value,
    this.trailing,
    this.onTap,
    super.key,
  });

  /// Icon shown in the leading tile.
  final IconData icon;

  /// Row label.
  final String label;

  /// Current value, shown before a chevron.
  final String? value;

  /// A control such as a toggle, shown instead of a value.
  final Widget? trailing;

  /// Tap handler.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    assert(
      value == null || trailing == null,
      'A settings row shows either a value or a control, not both.',
    );
    return Semantics(
      button: onTap != null,
      child: GestureDetector(
        onTap: onTap,
        child: AuraGlass.flat(
          padding: const EdgeInsets.symmetric(
            vertical: 13,
            horizontal: AuraSpacing.lg,
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Row(
                  spacing: AuraSpacing.md,
                  children: <Widget>[
                    _IconTile(icon: icon),
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AuraText.rowLabel.copyWith(
                          color: AuraColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null)
                trailing!
              else
                Row(
                  spacing: AuraSpacing.xs,
                  children: <Widget>[
                    if (value != null)
                      Text(
                        value!,
                        style: AuraText.bodyValue.copyWith(
                          color: AuraColors.textSecondary,
                        ),
                      ),
                    if (onTap != null)
                      const Icon(
                        AuraIcons.chevronRight,
                        size: 16,
                        color: AuraColors.textTertiary,
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

/// The rounded tile behind a settings row icon.
class _IconTile extends StatelessWidget {
  const _IconTile({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: AuraColors.glass,
        borderRadius: BorderRadius.circular(AuraRadii.iconTile),
      ),
      child: Center(
        child: Icon(icon, size: 16, color: AuraColors.textSecondary),
      ),
    );
  }
}
