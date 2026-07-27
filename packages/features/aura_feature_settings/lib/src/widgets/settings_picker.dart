import 'package:aura_design/aura_design.dart';
import 'package:flutter/material.dart' show showModalBottomSheet;
import 'package:flutter/widgets.dart';

/// One choice a picker offers.
@immutable
class SettingsOption<T> {
  /// Creates an option.
  const SettingsOption({required this.value, required this.label});

  /// What choosing it means.
  final T value;

  /// What it is called.
  final String label;
}

/// Asks which of [options] the user wants, and answers null if they dismiss.
///
/// The design draws a chevron on every unit row and no screen behind it. This
/// is that screen, built from the panel, the rows and the check glyph the
/// design system already has, because a chevron that opens nothing is worse
/// than a sheet the pen does not draw.
Future<T?> showSettingsPicker<T>({
  required BuildContext context,
  required String title,
  required List<SettingsOption<T>> options,
  required T selected,
}) => showModalBottomSheet<T>(
  context: context,
  backgroundColor: AuraColors.transparent,
  builder: (context) =>
      _Picker<T>(title: title, options: options, selected: selected),
);

class _Picker<T> extends StatelessWidget {
  const _Picker({
    required this.title,
    required this.options,
    required this.selected,
  });

  final String title;
  final List<SettingsOption<T>> options;
  final T selected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(AuraSpacing.lg),
        // The sky goes under the panel. Every other glass surface in the app
        // has a sky behind it, and glass at ten per cent white is meant to let
        // that through; over the settings screen it let the settings screen
        // through instead, and the rows underneath stayed legible. The glass
        // and its stroke are untouched, they finally have the background they
        // were drawn against.
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AuraRadii.detailPanel),
          child: AuraSky(
            kind: AuraSkyKind.systemBrand,
            child: AuraGlass(
              radius: AuraRadii.detailPanel,
              padding: const EdgeInsets.all(AuraSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: AuraSpacing.md,
                children: <Widget>[
                  Text(
                    title.toUpperCase(),
                    style: AuraText.sectionLabel
                        .forScript(context)
                        .copyWith(color: AuraColors.textTertiary),
                  ),
                  for (final option in options)
                    _Option<T>(
                      option: option,
                      isSelected: option.value == selected,
                      onTap: () => Navigator.of(context).pop(option.value),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Option<T> extends StatelessWidget {
  const _Option({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  final SettingsOption<T> option;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      child: GestureDetector(
        onTap: onTap,
        child: AuraGlass.flat(
          level: isSelected ? AuraGlassLevel.elevated : AuraGlassLevel.resting,
          padding: const EdgeInsets.symmetric(
            vertical: AuraSpacing.md,
            horizontal: AuraSpacing.lg,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Flexible(
                child: Text(
                  option.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AuraText.rowLabel.copyWith(
                    color: AuraColors.textPrimary,
                  ),
                ),
              ),
              if (isSelected)
                const Icon(
                  AuraIcons.success,
                  size: AuraSizes.iconUi,
                  color: AuraColors.accent,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
