import 'package:aura_core/aura_core.dart';
import 'package:aura_domain/src/entities/location_ref.dart';
import 'package:aura_domain/src/entities/weather_snapshot.dart';

/// Where a fetched snapshot is kept so it survives going offline.
///
/// Lives in the domain rather than in the storage package, which is what lets
/// the repository stay pure Dart and testable without a Flutter binding.
abstract interface class WeatherCachePort {
  /// The last snapshot stored for [location], or a `CacheMiss`.
  Future<Result<Stale<WeatherSnapshot>, AppFailure>> read(
    LocationRef location,
  );

  /// Stores [snapshot] against [location], stamped [fetchedAt].
  Future<Result<void, AppFailure>> write(
    LocationRef location,
    WeatherSnapshot snapshot, {
    required DateTime fetchedAt,
  });

  /// Drops everything cached. Used when the user changes units, since a
  /// stored snapshot is in whatever units it was fetched with.
  Future<Result<void, AppFailure>> clear();
}
