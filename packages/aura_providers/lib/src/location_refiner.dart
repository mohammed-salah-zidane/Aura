import 'package:aura_core/aura_core.dart';
import 'package:aura_domain/aura_domain.dart';
import 'package:aura_providers/src/app_state.dart';
import 'package:aura_providers/src/ports.dart';
import 'package:aura_providers/src/weather_feed.dart';
import 'package:riverpod/riverpod.dart';

/// Refines the active place to the device's own position.
final locationRefinerProvider = NotifierProvider<LocationRefiner, void>(
  LocationRefiner.new,
);

/// Moves the app onto the device's precise position in the background.
///
/// Lives for the whole app rather than for a screen, because the screens that
/// start a fix leave before it lands: the permission screen hands over to the
/// weather the moment the prompt is answered, and search closes on a tap.
/// The reading for the resolved place is fetched before the app moves to it,
/// so the switch lands dressed rather than on a loading face.
final class LocationRefiner extends Notifier<void> {
  @override
  void build() {}

  /// Resolves the position, warms its reading, then moves to it.
  ///
  /// Quietly goes nowhere when the fix fails or answers the place already on
  /// screen: the app is always standing on `auto:ip` by then, which is a
  /// working answer rather than an error to report.
  Future<void> refine() async {
    final position = await ref.read(locationPortProvider).currentPosition();
    if (position case Ok<LocationRef, AppFailure>(:final value)) {
      if (value == ref.read(activeLocationProvider)) return;
      await ref.read(placeFeedProvider(value).future);
      ref.read(activeLocationProvider.notifier).location = value;
    }
  }
}
