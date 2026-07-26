import 'package:aura_design/aura_design.dart';
import 'package:aura_l10n/aura_l10n.dart';
import 'package:flutter/widgets.dart';

/// Asks for location, and offers a way past it.
///
/// Built from the `State · Permission` frame. The pen's body copy names a
/// different product, left over from an earlier draft; the pen's own
/// `brand-name` variable says Aura, so that is what ships.
///
/// Neither action is a dead end. WeatherAPI resolves an approximate location
/// from the request itself, so declining still reaches real weather.
class PermissionScreen extends StatelessWidget {
  /// Creates the permission screen.
  const PermissionScreen({
    required this.onAllow,
    required this.onEnterManually,
    super.key,
  });

  /// Opens the system location prompt.
  final VoidCallback onAllow;

  /// Skips location and opens search instead.
  final VoidCallback onEnterManually;

  @override
  Widget build(BuildContext context) {
    return AuraSky(
      kind: AuraSkyKind.systemBrand,
      child: AuraStateScreen(
        icon: AuraIcons.mapPin,
        title: context.l10n.permissionTitle,
        body: context.l10n.permissionBody,
        actions: <Widget>[
          AuraButtonPrimary(
            label: context.l10n.permissionAllow,
            icon: AuraIcons.navigation,
            onPressed: onAllow,
          ),
          AuraButtonSecondary(
            label: context.l10n.permissionEnterManually,
            onPressed: onEnterManually,
          ),
        ],
      ),
    );
  }
}
