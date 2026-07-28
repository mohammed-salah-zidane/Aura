import 'package:aura_core/aura_core.dart';
import 'package:aura_domain/aura_domain.dart';
import 'package:aura_providers/src/app_state.dart';
import 'package:aura_providers/src/ports.dart';
import 'package:meta/meta.dart';
import 'package:riverpod/riverpod.dart';

/// One `forecast.json` call, plus whether it actually reached the network.
@immutable
final class WeatherFeed {
  /// Creates a feed.
  const WeatherFeed({
    required this.location,
    required this.snapshot,
    required this.fetchedAt,
    required this.isLive,
  });

  /// The place the call was made for.
  ///
  /// Carried so a screen paging between places can tell a reading for the
  /// place it is showing from one that belongs to the page just left.
  final LocationRef location;

  /// Everything the call returned.
  final WeatherSnapshot snapshot;

  /// When the reading was taken from the network.
  final DateTime fetchedAt;

  /// Whether this run reached the service, rather than reading the cache.
  ///
  /// Decided by comparing [fetchedAt] against the moment the request started,
  /// which is exact. A staleness threshold would only ever be a guess.
  final bool isLive;

  /// How long ago the reading was taken, according to [clock].
  Duration age(Clock clock) => clock.now().difference(fetchedAt);
}

/// One place's feed, held per place.
///
/// A family rather than one provider, so a place that has already answered
/// keeps its reading: swiping back to it is instant, and swiping to a place
/// the screen warmed up ahead of time never shows a spinner at all. The home
/// pager reads the instances directly to do that warming.
///
/// Failure is returned rather than thrown. `AppFailure` is a sealed domain
/// type and not an `Exception`, and a screen that has to render a recovery
/// action wants to switch over it rather than inspect an `AsyncError`.
// The family's own type is not exported by Riverpod 3, so the annotation the
// lint asks for here cannot be written.
// ignore: specify_nonobvious_property_types
final placeFeedProvider =
    FutureProvider.family<Result<WeatherFeed, AppFailure>, LocationRef>((
      ref,
      location,
    ) async {
      final startedAt = ref.watch(clockProvider).now();
      // The current-location page asks with the device's precise fix once one
      // is known, and with the approximate address until then. The feed's
      // identity stays the symbolic reference either way, so every screen
      // naming "current location" is talking about the same page.
      final query = location.isCurrentLocation
          ? (ref.watch(devicePositionProvider) ?? location)
          : location;
      final result = await ref
          .watch(weatherRepositoryProvider)
          .snapshot(query, lang: ref.watch(languageProvider));

      return result.map(
        (stale) => WeatherFeed(
          location: location,
          snapshot: stale.value,
          fetchedAt: stale.fetchedAt,
          isLive: !stale.fetchedAt.isBefore(startedAt),
        ),
      );
    });

/// The active place's feed, shared by every screen showing it.
///
/// Home and all four detail screens read the same place in the same language,
/// so they read one provider and the app makes one request rather than five.
final weatherFeedProvider = FutureProvider<Result<WeatherFeed, AppFailure>>(
  (ref) =>
      ref.watch(placeFeedProvider(ref.watch(activeLocationProvider)).future),
);
