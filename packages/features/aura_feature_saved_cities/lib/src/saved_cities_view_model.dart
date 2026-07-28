import 'dart:async';

import 'package:aura_domain/aura_domain.dart';
import 'package:aura_providers/aura_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';

/// One row of the saved list: a place, and its reading once it arrives.
@immutable
final class SavedCityRow {
  /// Creates a row.
  const SavedCityRow({
    required this.location,
    required this.name,
    required this.isCurrentLocation,
    this.snapshot,
  });

  /// How to ask the service about it.
  final LocationRef location;

  /// What to call it before its reading arrives.
  final String name;

  /// Whether this is the device's own position rather than a kept place.
  final bool isCurrentLocation;

  /// Its reading, or null while it is on its way or after it failed.
  final WeatherSnapshot? snapshot;

  /// The same row, dressed with its reading.
  SavedCityRow withSnapshot(WeatherSnapshot snapshot) => SavedCityRow(
    location: location,
    name: name,
    isCurrentLocation: isCurrentLocation,
    snapshot: snapshot,
  );
}

/// The saved cities screen's state.
final savedCitiesViewModelProvider =
    AsyncNotifierProvider<SavedCitiesViewModel, List<SavedCityRow>>(
      SavedCitiesViewModel.new,
      isAutoDispose: true,
    );

/// Reads every kept place, with the device's own position at the top.
///
/// The rows appear at once, named, with each reading filling in as its own
/// request lands: a list that waits for the slowest answer holds every city
/// hostage to it, and a row whose request fails keeps its name, because a
/// list that drops a city the user saved is worse than one that admits it
/// could not reach the service.
///
/// The readings come through the per-place feed the home pager reads, so a
/// city the user has already looked at costs nothing here, and opening this
/// list warms the pages the user is about to swipe through.
final class SavedCitiesViewModel extends AsyncNotifier<List<SavedCityRow>> {
  /// Which build the in-flight fills belong to.
  int _run = 0;

  @override
  Future<List<SavedCityRow>> build() async {
    final saved = await ref.watch(savedCitiesProvider.future);

    const here = LocationRef.currentByIp();
    final rows = <SavedCityRow>[
      const SavedCityRow(location: here, name: '', isCurrentLocation: true),
      for (final city in saved)
        SavedCityRow(
          location: city.location,
          name: city.name,
          isCurrentLocation: false,
        ),
    ];

    final run = ++_run;
    for (final row in rows) {
      unawaited(_fill(row.location, run));
    }
    return rows;
  }

  Future<void> _fill(LocationRef location, int run) async {
    final result = await ref.read(placeFeedProvider(location).future);
    final snapshot = result.valueOrNull?.snapshot;
    final rows = state.value;
    if (run != _run || snapshot == null || rows == null) return;

    state = AsyncData<List<SavedCityRow>>(<SavedCityRow>[
      for (final row in rows)
        if (row.location == location) row.withSnapshot(snapshot) else row,
    ]);
  }

  /// Forgets a kept place.
  Future<void> remove(LocationRef location) =>
      ref.read(savedCitiesProvider.notifier).remove(location);
}
