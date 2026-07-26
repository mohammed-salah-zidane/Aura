import 'package:aura_design/src/foundations/aura_glass.dart';
import 'package:aura_design/src/tokens/aura_colors.dart';
import 'package:aura_design/src/tokens/aura_icons.dart';
import 'package:aura_design/src/tokens/aura_metrics.dart';
import 'package:aura_design/src/tokens/aura_typography.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// The glass search field.
///
/// Built on `EditableText` rather than `TextField` so the field carries no
/// Material decoration, underline or floating label to override.
class AuraSearchField extends StatefulWidget {
  /// Creates a search field.
  const AuraSearchField({
    required this.placeholder,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
    this.clearSemanticLabel,
    super.key,
  });

  /// Text shown while the field is empty.
  final String placeholder;

  /// External controller, when the caller owns the text.
  final TextEditingController? controller;

  /// Called on every keystroke.
  final ValueChanged<String>? onChanged;

  /// Called when the user submits from the keyboard.
  final ValueChanged<String>? onSubmitted;

  /// Whether the field takes focus on first build.
  final bool autofocus;

  /// Accessibility label for the clear button.
  final String? clearSemanticLabel;

  @override
  State<AuraSearchField> createState() => _AuraSearchFieldState();
}

class _AuraSearchFieldState extends State<AuraSearchField> {
  TextEditingController? _internalController;
  late final FocusNode _focusNode = FocusNode();

  TextEditingController get _controller =>
      widget.controller ?? (_internalController ??= TextEditingController());

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _internalController?.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() => setState(() {});

  void _clear() {
    _controller.clear();
    widget.onChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    final hasText = _controller.text.isNotEmpty;
    return AuraGlass.flat(
      radius: AuraRadii.chip,
      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
      child: Row(
        spacing: AuraSpacing.smPlus,
        children: <Widget>[
          const Icon(
            AuraIcons.search,
            size: AuraSizes.iconUi,
            color: AuraColors.textTertiary,
          ),
          Expanded(
            child: Stack(
              alignment: Alignment.centerLeft,
              children: <Widget>[
                if (!hasText)
                  Text(
                    widget.placeholder,
                    style: AuraText.placeholder.copyWith(
                      color: AuraColors.textTertiary,
                    ),
                  ),
                EditableText(
                  controller: _controller,
                  focusNode: _focusNode,
                  autofocus: widget.autofocus,
                  style: AuraText.placeholder.copyWith(
                    color: AuraColors.textPrimary,
                  ),
                  cursorColor: AuraColors.accent,
                  backgroundCursorColor: AuraColors.textTertiary,
                  onChanged: widget.onChanged,
                  onSubmitted: widget.onSubmitted,
                  textInputAction: TextInputAction.search,
                  keyboardType: TextInputType.text,
                  textCapitalization: TextCapitalization.words,
                  cursorOpacityAnimates: true,
                  selectionColor: AuraColors.accent.withValues(alpha: 0.3),
                ),
              ],
            ),
          ),
          if (hasText)
            Semantics(
              button: true,
              label: widget.clearSemanticLabel,
              child: GestureDetector(
                onTap: _clear,
                child: const Icon(
                  AuraIcons.close,
                  size: AuraSizes.iconUi,
                  color: AuraColors.textTertiary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
