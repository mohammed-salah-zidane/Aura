import 'package:aura_design/src/foundations/aura_glass.dart';
import 'package:aura_design/src/tokens/aura_colors.dart';
import 'package:aura_design/src/tokens/aura_icons.dart';
import 'package:aura_design/src/tokens/aura_metrics.dart';
import 'package:aura_design/src/tokens/aura_typography.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// The two treatments the design draws a search field in.
///
/// The saved cities screen shows the resting one, which is a way into search
/// rather than a place to type. The search screen shows the active one, set a
/// point larger on a wider radius, with the ringed clear glyph.
enum AuraSearchFieldVariant {
  /// The way into search, on a screen that is not search.
  resting(
    radius: AuraRadii.chip,
    padding: EdgeInsets.symmetric(vertical: 13, horizontal: AuraSpacing.lg),
    style: AuraText.placeholder,
    clearIcon: AuraIcons.close,
    clearIconSize: AuraSizes.iconUi,
  ),

  /// The field on the search screen itself.
  active(
    radius: AuraRadii.button,
    padding: EdgeInsets.symmetric(
      vertical: AuraSpacing.mdPlus,
      horizontal: AuraSpacing.lg,
    ),
    style: AuraText.searchQuery,
    clearIcon: AuraIcons.clear,
    clearIconSize: AuraSizes.iconClear,
  );

  const AuraSearchFieldVariant({
    required this.radius,
    required this.padding,
    required this.style,
    required this.clearIcon,
    required this.clearIconSize,
  });

  /// Corner radius.
  final double radius;

  /// Inner padding.
  final EdgeInsets padding;

  /// Type for the query and the placeholder alike.
  final TextStyle style;

  /// Glyph that empties the field.
  final IconData clearIcon;

  /// Size of that glyph.
  final double clearIconSize;
}

/// The glass search field.
///
/// Built on `EditableText` rather than `TextField` so the field carries no
/// Material decoration, underline or floating label to override.
///
/// Passing [onTap] makes the field a way into search rather than a place to
/// type: it takes no focus and reports the tap instead, which is how the saved
/// cities screen uses it.
class AuraSearchField extends StatefulWidget {
  /// Creates a search field.
  const AuraSearchField({
    required this.placeholder,
    this.variant = AuraSearchFieldVariant.resting,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.autofocus = false,
    this.clearSemanticLabel,
    super.key,
  });

  /// Text shown while the field is empty.
  final String placeholder;

  /// Which of the design's two treatments to draw.
  final AuraSearchFieldVariant variant;

  /// External controller, when the caller owns the text.
  final TextEditingController? controller;

  /// Called on every keystroke.
  final ValueChanged<String>? onChanged;

  /// Called when the user submits from the keyboard.
  final ValueChanged<String>? onSubmitted;

  /// Called instead of taking focus, for a field that opens search.
  final VoidCallback? onTap;

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
    final variant = widget.variant;
    final hasText = _controller.text.isNotEmpty;
    final field = AuraGlass.flat(
      radius: variant.radius,
      padding: variant.padding,
      child: Row(
        spacing: AuraSpacing.smPlus,
        children: <Widget>[
          const Icon(
            AuraIcons.search,
            size: AuraSizes.iconUi,
            color: AuraColors.textTertiary,
          ),
          Expanded(
            child: widget.onTap != null
                ? Text(
                    widget.placeholder,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: variant.style.copyWith(
                      color: AuraColors.textTertiary,
                    ),
                  )
                : Stack(
                    alignment: AlignmentDirectional.centerStart,
                    children: <Widget>[
                      if (!hasText)
                        Text(
                          widget.placeholder,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: variant.style.copyWith(
                            color: AuraColors.textTertiary,
                          ),
                        ),
                      EditableText(
                        controller: _controller,
                        focusNode: _focusNode,
                        autofocus: widget.autofocus,
                        style: variant.style.copyWith(
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
                        selectionColor: AuraColors.accent.withValues(
                          alpha: 0.3,
                        ),
                      ),
                    ],
                  ),
          ),
          if (hasText && widget.onTap == null)
            Semantics(
              button: true,
              label: widget.clearSemanticLabel,
              child: GestureDetector(
                onTap: _clear,
                child: Icon(
                  variant.clearIcon,
                  size: variant.clearIconSize,
                  color: AuraColors.textTertiary,
                ),
              ),
            ),
        ],
      ),
    );

    if (widget.onTap == null) return field;
    return Semantics(
      button: true,
      child: GestureDetector(onTap: widget.onTap, child: field),
    );
  }
}
