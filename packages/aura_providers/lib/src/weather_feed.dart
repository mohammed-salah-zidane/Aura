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
    required this.snapshot,
    required this.fetchedAt,
    required this.isLive,
  });

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

/// The whole home screen for the active place, shared by every screen showing
/// it.
///
/// Home and all four detail screens read the same place in the same language,
/// so they read one provider and the app makes one request rather than five.
///
/// Failure is returned rather than thrown. `AppFailure` is a sealed domain
/// type and not an `Exception`, and a screen that has to render a recovery
/// action wants to switch over it rather than inspect an `AsyncError`.
final weatherFeedProvider = FutureProvider<Result<WeatherFeed, AppFailure>>((
  ref,
) async {
  final startedAt = ref.watch(clockProvider).now();
  final result = await ref
      .watch(weatherRepositoryProvider)
      .snapshot(
        ref.watch(activeLocationProvider),
        lang: ref.watch(languageProvider),
      );

  return result.map(
    (stale) => WeatherFeed(
      snapshot: stale.value,
      fetchedAt: stale.fetchedAt,
      isLive: !stale.fetchedAt.isBefore(startedAt),
    ),
  );
});
