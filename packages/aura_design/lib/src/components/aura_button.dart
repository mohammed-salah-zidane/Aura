import 'package:aura_design/src/foundations/aura_glass.dart';
import 'package:aura_design/src/foundations/aura_pressable.dart';
import 'package:aura_design/src/tokens/aura_colors.dart';
import 'package:aura_design/src/tokens/aura_metrics.dart';
import 'package:aura_design/src/tokens/aura_typography.dart';
import 'package:flutter/widgets.dart';

/// Padding read from the button components in `aura.pen`.
const EdgeInsets _buttonPadding = EdgeInsets.symmetric(
  vertical: AuraSpacing.lg,
  horizontal: AuraSpacing.xl,
);

/// The gold call to action.
///
/// One primary button per screen. Passing `null` for [onPressed] renders the
/// disabled state rather than a visually identical but inert button.
class AuraButtonPrimary extends StatelessWidget {
  /// Creates a primary button.
  const AuraButtonPrimary({
    required this.label,
    required this.onPressed,
    this.icon,
    super.key,
  });

  /// Button text.
  final String label;

  /// Tap handler. `null` disables the button.
  final VoidCallback? onPressed;

  /// Optional leading icon.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return AuraPressable(
      onPressed: onPressed,
      builder: ({required pressed}) => DecoratedBox(
        decoration: BoxDecoration(
          color: AuraColors.accent.withValues(
            alpha: onPressed == null
                ? 0.4
                : pressed
                ? 0.85
                : 1,
          ),
          borderRadius: BorderRadius.circular(AuraRadii.button),
        ),
        child: Padding(
          padding: _buttonPadding,
          child: _ButtonContent(
            label: label,
            icon: icon,
            style: AuraText.buttonPrimary,
            color: AuraColors.onAccent,
          ),
        ),
      ),
    );
  }
}

/// The glass alternative to a primary action.
class AuraButtonSecondary extends StatelessWidget {
  /// Creates a secondary button.
  const AuraButtonSecondary({
    required this.label,
    required this.onPressed,
    this.icon,
    super.key,
  });

  /// Button text.
  final String label;

  /// Tap handler. `null` disables the button.
  final VoidCallback? onPressed;

  /// Optional leading icon.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return AuraPressable(
      onPressed: onPressed,
      builder: ({required pressed}) => Opacity(
        opacity: onPressed == null ? 0.5 : 1,
        child: AuraGlass(
          radius: AuraRadii.button,
          level: pressed ? AuraGlassLevel.elevated : AuraGlassLevel.resting,
          shadow: const <BoxShadow>[],
          padding: _buttonPadding,
          child: _ButtonContent(
            label: label,
            icon: icon,
            style: AuraText.buttonSecondary,
            color: AuraColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

/// Icon and label, centred, as both buttons lay them out.
class _ButtonContent extends StatelessWidget {
  const _ButtonContent({
    required this.label,
    required this.icon,
    required this.style,
    required this.color,
  });

  final String label;
  final IconData? icon;
  final TextStyle style;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: AuraSpacing.sm,
      children: <Widget>[
        if (icon != null) Icon(icon, size: AuraSizes.iconUi, color: color),
        Text(label, style: style.copyWith(color: color)),
      ],
    );
  }
}
