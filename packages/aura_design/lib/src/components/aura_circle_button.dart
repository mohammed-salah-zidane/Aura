import 'package:aura_design/src/foundations/aura_glass.dart';
import 'package:aura_design/src/foundations/aura_pressable.dart';
import 'package:aura_design/src/tokens/aura_colors.dart';
import 'package:aura_design/src/tokens/aura_metrics.dart';
import 'package:flutter/widgets.dart';

/// The two sizes the design draws the round glass button at.
enum AuraCircleButtonSize {
  /// 34. Beside a screen title.
  standard(AuraSizes.brandButton, AuraSizes.iconUi),

  /// 36. The back button on a detail screen.
  back(AuraSizes.backButton, AuraSizes.iconBack);

  const AuraCircleButtonSize(this.diameter, this.iconSize);

  /// Width and height of the disc.
  final double diameter;

  /// Size of the glyph inside it.
  final double iconSize;
}

/// The round glass button the design puts beside a screen title.
///
/// The same 34 point disc carries settings above the hero, close on search,
/// the overflow on saved cities and back on every detail screen. It has no
/// text of its own, so [semanticLabel] is what a screen reader announces.
class AuraCircleButton extends StatelessWidget {
  /// Creates a circular icon button.
  const AuraCircleButton({
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
    this.size = AuraCircleButtonSize.standard,
    super.key,
  });

  /// Glyph inside the disc.
  final IconData icon;

  /// What the button does, for assistive technology.
  final String semanticLabel;

  /// Tap handler.
  final VoidCallback onPressed;

  /// Which of the design's two sizes to draw.
  final AuraCircleButtonSize size;

  @override
  Widget build(BuildContext context) {
    return AuraPressable.child(
      onPressed: onPressed,
      semanticLabel: semanticLabel,
      // Every one of these goes somewhere else in the app, so the tick lands
      // on a screen change rather than on a value the user can already see.
      haptic: true,
      child: AuraGlass(
        width: size.diameter,
        height: size.diameter,
        radius: AuraRadii.pill,
        shadow: const <BoxShadow>[],
        child: Center(
          child: Icon(
            icon,
            size: size.iconSize,
            color: AuraColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
