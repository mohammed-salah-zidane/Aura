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

  /// Its reading, or null when the request for it failed.
  final WeatherSnapshot? snapshot;
}

/// The saved cities screen's state.
final savedCitiesViewModelProvider =
    AsyncNotifierProvider<SavedCitiesViewModel, List<SavedCityRow>>(
      SavedCitiesViewModel.new,
      isAutoDispose: true,
    );

/// Reads every kept place, with the device's own position at the top.
///
/// One request per row, all in flight at once. A row whose request fails keeps
/// its name and loses its reading, because a list that drops a city the user
/// saved is worse than one that admits it could not reach the service.
final class SavedCitiesViewModel extends AsyncNotifier<List<SavedCityRow>> {
  @override
  Future<List<SavedCityRow>> build() async {
    final saved = await ref.watch(savedCitiesProvider.future);
    final language = ref.watch(languageProvider);
    final repository = ref.watch(weatherRepositoryProvider);

    const here = LocationRef.currentByIp();
    final locations = <LocationRef>[here, ...saved.map((c) => c.location)];
    final names = <String>['', ...saved.map((c) => c.name)];

    final snapshots = await Future.wait(
      locations.map(
        (location) => repository.snapshot(location, lang: language),
      ),
    );

    return <SavedCityRow>[
      for (final (index, location) in locations.indexed)
        SavedCityRow(
          location: location,
          name: names[index],
          isCurrentLocation: index == 0,
          snapshot: snapshots[index].valueOrNull?.value,
        ),
    ];
  }

  /// Forgets a kept place.
  Future<void> remove(LocationRef location) =>
      ref.read(savedCitiesProvider.notifier).remove(location);
}
