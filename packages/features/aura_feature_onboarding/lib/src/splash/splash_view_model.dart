import 'package:aura_core/aura_core.dart';
import 'package:aura_design/aura_design.dart';
import 'package:aura_domain/aura_domain.dart';
import 'package:aura_providers/aura_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Where the app opens.
enum SplashDestination {
  /// Straight to the weather, because there is a place to show.
  weather,

  /// The permission screen, because there is not.
  permission,
}

/// The splash screen's decision.
final splashViewModelProvider =
    NotifierProvider<SplashViewModel, SplashDestination?>(
      SplashViewModel.new,
      isAutoDispose: true,
    );

/// Works out where the app should open, while the splash is on screen.
///
/// Three answers, in order: a granted location permission means the device's
/// own position, a kept city means the last thing the user chose to look at,
/// and neither means the permission screen. Nothing is asked for here; the
/// permission screen is where the app asks.
final class SplashViewModel extends Notifier<SplashDestination?> {
  /// How long the splash stays up at the least.
  ///
  ///
  /// The decision can resolve in a few milliseconds, and a splash that appears
  /// and vanishes inside one frame reads as a glitch. One turn of the loader
  /// is the cadence the design system already defines for waiting.
  static const Duration minimumOnScreen = AuraMotion.shimmer;

  @override
  SplashDestination? build() => null;

  /// Decides, and publishes the answer once the splash has had its moment.
  Future<void> decide() async {
    final decided = await Future.wait(<Future<Object?>>[
      _destination(),
      Future<void>.delayed(minimumOnScreen),
    ]);
    state = decided.first! as SplashDestination;
  }

  Future<SplashDestination> _destination() async {
    final port = ref.read(locationPortProvider);
    if (await port.permission() == LocationPermission.granted) {
      final position = await port.currentPosition();
      if (position case Ok<LocationRef, AppFailure>(:final value)) {
        ref.read(activeLocationProvider.notifier).location = value;
      }
      return SplashDestination.weather;
    }

    final saved = await ref.read(savedCitiesProvider.future);
    if (saved.isNotEmpty) {
      ref.read(activeLocationProvider.notifier).location = saved.first.location;
      return SplashDestination.weather;
    }
    return SplashDestination.permission;
  }
}
