import 'package:aura_feature_home/src/home_ui_state.dart';
import 'package:aura_providers/aura_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The home screen's state.
final homeViewModelProvider = AsyncNotifierProvider<HomeViewModel, HomeUiState>(
  HomeViewModel.new,
);

/// Composes the reading, the units and how fresh the reading is.
///
/// Holds no formatting and no layout: it decides which of the three states the
/// screen is in, and the view decides how each one looks.
final class HomeViewModel extends AsyncNotifier<HomeUiState> {
  /// Whether the user has chosen to look at a stored reading anyway.
  ///
  /// Kept on the notifier rather than in the state, because it survives a
  /// rebuild triggered by anything other than a fresh request.
  bool _acceptedStoredReading = false;

  @override
  Future<HomeUiState> build() async {
    final units = await ref.watch(unitPreferencesProvider.future);
    final feed = await ref.watch(weatherFeedProvider.future);
    final clock = ref.watch(clockProvider);

    return feed.fold(
      (value) => value.isLive || _acceptedStoredReading
          ? HomeReady(feed: value, units: units)
          : HomeStale(feed: value, age: value.age(clock), units: units),
      (failure) => HomeUnavailable(failure: failure, units: units),
    );
  }

  /// Asks the service again, from the top.
  ///
  /// The invalidation names the active place's own feed: the shared provider
  /// only mirrors it, and invalidating the mirror alone would hand back the
  /// same held reading.
  Future<void> refresh() async {
    _acceptedStoredReading = false;
    ref.invalidate(placeFeedProvider(ref.read(activeLocationProvider)));
    await ref.read(weatherFeedProvider.future);
  }

  /// Shows the stored reading the offline screen offered.
  ///
  /// Nothing is fetched: the reading is already in hand, and the user has just
  /// said they would rather read it than wait.
  void useStoredReading() {
    final current = state.value;
    if (current is! HomeStale) return;
    _acceptedStoredReading = true;
    state = AsyncData<HomeUiState>(
      HomeReady(feed: current.feed, units: current.units),
    );
  }
}
