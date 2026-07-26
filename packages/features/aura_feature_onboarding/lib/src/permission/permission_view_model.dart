import 'package:aura_core/aura_core.dart';
import 'package:aura_domain/aura_domain.dart';
import 'package:aura_providers/aura_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Asks the system for location, and records what came back.
final permissionViewModelProvider = NotifierProvider<PermissionViewModel, bool>(
  PermissionViewModel.new,
  isAutoDispose: true,
);

/// The permission screen's one job: put the system prompt up.
///
/// The state is whether the request is in flight, which is only there to
/// swallow a second tap before the system prompt takes over the screen. The
/// answer itself is not held: a granted permission becomes the active
/// location, and a refused one leaves the approximate position the app already
/// starts on, so there is nothing left to remember.
final class PermissionViewModel extends Notifier<bool> {
  @override
  bool build() => false;

  /// Asks, and puts the device's own position on screen if the answer is yes.
  ///
  /// Returns whichever way it went, so the caller can move on either way.
  /// Refusing is not an error here: WeatherAPI resolves an approximate
  /// position from the request itself, so the weather still arrives.
  Future<void> request() async {
    if (state) return;
    state = true;
    final port = ref.read(locationPortProvider);
    if (await port.request() == LocationPermission.granted) {
      final position = await port.currentPosition();
      if (position case Ok<LocationRef, AppFailure>(:final value)) {
        ref.read(activeLocationProvider.notifier).location = value;
      }
    }
    state = false;
  }
}
