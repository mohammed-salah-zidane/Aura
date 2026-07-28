import 'dart:async';

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

  /// Asks, and returns the moment the prompt is answered.
  ///
  /// The precise fix is not waited for: it can take many seconds indoors, and
  /// the app is already standing on the approximate position the service
  /// resolves without any permission. The refiner carries the fix in the
  /// background and moves the app onto it once its reading is in hand, so
  /// the caller leaves for the weather immediately either way. Refusing is
  /// not an error here, for the same reason.
  Future<void> request() async {
    if (state) return;
    state = true;
    final port = ref.read(locationPortProvider);
    if (await port.request() == LocationPermission.granted) {
      unawaited(ref.read(locationRefinerProvider.notifier).refine());
    }
    state = false;
  }
}
