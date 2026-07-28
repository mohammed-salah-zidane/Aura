import 'package:aura_core/aura_core.dart';
import 'package:aura_domain/aura_domain.dart';
import 'package:aura_providers/src/app_state.dart';
import 'package:aura_providers/src/ports.dart';
import 'package:riverpod/riverpod.dart';

/// Refines the active place to the device's own position.
final locationRefinerProvider = NotifierProvider<LocationRefiner, void>(
  LocationRefiner.new,
);

/// Sharpens what "current location" resolves to, in the background.
///
/// Lives for the whole app rather than for a screen, because the screens that
/// start a fix leave before it lands: the splash hands over while the fix is
/// still out, the permission screen leaves the moment the prompt is answered,
/// and search closes on a tap.
///
/// It never moves the active place. Recording the fix is enough: the
/// current-location feed watches it and refetches for the precise spot, so
/// every page and row naming "current location" sharpens together while the
/// reading already on screen stays up until the better one arrives.
final class LocationRefiner extends Notifier<void> {
  @override
  void build() {}

  /// Resolves the device's position and records it.
  ///
  /// Quietly goes nowhere when the fix fails: the app is always standing on
  /// `auto:ip` by then, which is a working answer rather than an error to
  /// report.
  Future<void> refine() async {
    final position = await ref.read(locationPortProvider).currentPosition();
    if (position case Ok<LocationRef, AppFailure>(:final value)) {
      ref.read(devicePositionProvider.notifier).position = value;
    }
  }
}
