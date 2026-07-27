import 'package:aura_design/src/tokens/aura_motion.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Press feedback and a tap target, without pulling in Material.
///
/// Everything tappable in the app goes through this, so a card and a button
/// answer a finger the same way. [builder] is given the pressed state for the
/// controls that also change their fill, and the scale is applied here so no
/// call site can pick its own amplitude.
class AuraPressable extends StatefulWidget {
  /// Creates a pressable that rebuilds with the pressed state.
  const AuraPressable({
    required this.onPressed,
    required this.builder,
    this.semanticLabel,
    this.haptic = false,
    super.key,
  }) : child = null;

  /// Creates a pressable around a child that does not change when pressed.
  const AuraPressable.child({
    required this.onPressed,
    required Widget this.child,
    this.semanticLabel,
    this.haptic = false,
    super.key,
  }) : builder = null;

  /// Tap handler. `null` renders the control inert and unfocusable.
  final VoidCallback? onPressed;

  /// Builds the content, given whether a finger is currently down.
  final Widget Function({required bool pressed})? builder;

  /// Content that does not vary with the pressed state.
  final Widget? child;

  /// Announced in place of the content, for a control that is only a glyph.
  final String? semanticLabel;

  /// Whether a tap also fires a selection tick.
  ///
  /// On for a control that moves you somewhere, off for one whose result is
  /// already visible on screen, so the app does not buzz at every touch.
  final bool haptic;

  @override
  State<AuraPressable> createState() => _AuraPressableState();
}

class _AuraPressableState extends State<AuraPressable> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) {
      setState(() => _pressed = value);
    }
  }

  void _handleTap() {
    // The tick is fire and forget: waiting on the platform channel would delay
    // the navigation the tap is actually for.
    if (widget.haptic) HapticFeedback.selectionClick().ignore();
    widget.onPressed!.call();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final content = widget.child ?? widget.builder!.call(pressed: _pressed);

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticLabel,
      child: GestureDetector(
        // The whole box answers, not just the parts of the child that happen
        // to paint. Without this a card's padding is dead to a finger, which
        // is a target the design drew and the code then refused.
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? _handleTap : null,
        onTapDown: enabled ? (_) => _setPressed(true) : null,
        onTapUp: enabled ? (_) => _setPressed(false) : null,
        onTapCancel: enabled ? () => _setPressed(false) : null,
        child: AnimatedScale(
          scale: _pressed ? AuraMotion.pressScale : 1,
          duration: AuraMotion.control,
          curve: AuraMotion.controlCurve,
          child: content,
        ),
      ),
    );
  }
}
