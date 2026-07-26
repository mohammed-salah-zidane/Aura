import 'package:aura_core/aura_core.dart';
import 'package:aura_domain/aura_domain.dart';
import 'package:aura_providers/aura_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';

/// Everything the four detail screens draw from.
///
/// They all read the same `forecast.json` call home already made, so opening
/// one costs no request: the feed is shared and home is still mounted under it.
@immutable
final class DetailsUiState {
  /// Creates a detail state.
  const DetailsUiState({
    required this.snapshot,
    required this.units,
    required this.now,
  });

  /// The reading the screens draw.
  final WeatherSnapshot snapshot;

  /// The units to draw it in.
  final UnitPreferences units;

  /// The moment the screen was built, for the sun's place on its arc.
  final DateTime now;

  /// The place, as the kicker names it.
  String get place => '${snapshot.placeName}, ${snapshot.country}';
}

/// The state every detail screen reads.
///
/// Failure is carried rather than thrown, the same way the feed carries it, so
/// a screen switches over a sealed type instead of unpacking an `AsyncError`.
final detailsViewModelProvider =
    AsyncNotifierProvider<DetailsViewModel, Result<DetailsUiState, AppFailure>>(
      DetailsViewModel.new,
      isAutoDispose: true,
    );

/// Composes the shared feed with the units and the clock.
final class DetailsViewModel
    extends AsyncNotifier<Result<DetailsUiState, AppFailure>> {
  @override
  Future<Result<DetailsUiState, AppFailure>> build() async {
    final units = await ref.watch(unitPreferencesProvider.future);
    final feed = await ref.watch(weatherFeedProvider.future);
    final clock = ref.watch(clockProvider);

    return feed.map(
      (value) => DetailsUiState(
        snapshot: value.snapshot,
        units: units,
        now: clock.now(),
      ),
    );
  }
}
