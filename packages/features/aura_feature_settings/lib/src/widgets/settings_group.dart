import 'package:aura_design/aura_design.dart';
import 'package:flutter/widgets.dart';

/// A tracked heading over a panel of rows, hairlined between them.
class SettingsGroup extends StatelessWidget {
  /// Creates a settings group.
  const SettingsGroup({required this.label, required this.rows, super.key});

  /// The heading, in sentence case. The view sets the caps.
  final String label;

  /// The rows inside the panel.
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AuraSpacing.sm,
      children: <Widget>[
        Text(
          label.toUpperCase(),
          style: AuraText.sectionLabel
              .forScript(context)
              .copyWith(color: AuraColors.textTertiary),
        ),
        AuraGlass.flat(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AuraRadii.row),
            child: Column(
              children: <Widget>[
                for (final (index, row) in rows.indexed) ...<Widget>[
                  if (index > 0) const _Divider(),
                  row,
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// The hairline between two rows.
class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: AuraSizes.divider,
      child: ColoredBox(color: AuraColors.glass),
    );
  }
}
