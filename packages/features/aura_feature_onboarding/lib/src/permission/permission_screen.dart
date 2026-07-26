import 'package:aura_design/aura_design.dart';
import 'package:aura_feature_onboarding/src/permission/permission_view_model.dart';
import 'package:aura_l10n/aura_l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Asks for location, and offers a way past it.
///
/// Built from the `State · Permission` frame. The pen's body copy names a
/// different product, left over from an earlier draft; the pen's own
/// `brand-name` variable says Aura, so that is what ships.
///
/// Neither action is a dead end. WeatherAPI resolves an approximate location
/// from the request itself, so declining still reaches real weather, and the
/// screen moves on whichever way the prompt is answered.
class PermissionScreen extends ConsumerWidget {
  /// Creates the permission screen.
  const PermissionScreen({
    required this.onDone,
    required this.onEnterManually,
    super.key,
  });

  /// Leaves for the weather, once the system prompt has been answered.
  final VoidCallback onDone;

  /// Skips location and opens search instead.
  final VoidCallback onEnterManually;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAsking = ref.watch(permissionViewModelProvider);
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
            // The system prompt is modal, so there is nothing to show while it
            // is up. Disabling is only here to swallow a second tap on the
            // frame between the tap and the prompt appearing.
            onPressed: isAsking
                ? null
                : () async {
                    await ref
                        .read(permissionViewModelProvider.notifier)
                        .request();
                    onDone();
                  },
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
