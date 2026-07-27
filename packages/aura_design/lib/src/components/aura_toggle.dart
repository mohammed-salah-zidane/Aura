import 'package:aura_design/src/tokens/aura_colors.dart';
import 'package:aura_design/src/tokens/aura_metrics.dart';
import 'package:aura_design/src/tokens/aura_motion.dart';
import 'package:flutter/widgets.dart';

/// A 46 by 28 capsule switch with a 22-point knob.
///
/// Built directly rather than wrapping `Switch`, because the Material switch
/// carries its own track geometry, ripple and platform variance, none of which
/// match the design.
class AuraToggle extends StatelessWidget {
  /// Creates a toggle.
  const AuraToggle({
    required this.value,
    required this.onChanged,
    this.semanticLabel,
    super.key,
  });

  /// Whether the toggle is on.
  final bool value;

  /// Called with the requested new value. `null` disables the toggle.
  final ValueChanged<bool>? onChanged;

  /// Accessibility label describing what this toggle controls.
  final String? semanticLabel;

  static const double _padding = 3;

  @override
  Widget build(BuildContext context) {
    final enabled = onChanged != null;
    return Semantics(
      label: semanticLabel,
      toggled: value,
      enabled: enabled,
      child: GestureDetector(
        onTap: enabled ? () => onChanged!(!value) : null,
        child: Opacity(
          opacity: enabled ? 1 : 0.5,
          child: AnimatedContainer(
            duration: AuraMotion.control,
            curve: AuraMotion.controlCurve,
            width: AuraSizes.toggle.width,
            height: AuraSizes.toggle.height,
            padding: const EdgeInsets.all(_padding),
            decoration: BoxDecoration(
              color: value ? AuraColors.accent : AuraColors.toggleTrackOff,
              borderRadius: BorderRadius.circular(AuraRadii.pill),
              border: value ? null : Border.all(color: AuraColors.border),
            ),
            child: AnimatedAlign(
              duration: AuraMotion.control,
              curve: AuraMotion.controlCurve,
              // Directional, not left and right. The pen draws the knob at the
              // end of the track when the switch is on, and in Arabic that end
              // is the left one. Absolute alignment put an off switch where a
              // reader of that script expects an on one.
              alignment: value
                  ? AlignmentDirectional.centerEnd
                  : AlignmentDirectional.centerStart,
              child: Container(
                width: AuraSizes.toggleKnob,
                height: AuraSizes.toggleKnob,
                decoration: const BoxDecoration(
                  color: AuraColors.textPrimary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
