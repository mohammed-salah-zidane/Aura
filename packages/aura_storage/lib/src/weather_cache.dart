import 'dart:convert';

import 'package:aura_core/aura_core.dart';
import 'package:aura_domain/aura_domain.dart';
import 'package:aura_storage/src/database/aura_database.dart';
import 'package:aura_storage/src/database/weather_snapshot_codec.dart';
import 'package:aura_storage/src/guarded.dart';

/// The offline copy of the last reading for each place.
///
/// One row per place, overwritten on every successful fetch. There is no
/// expiry: the repository always tries the network first, so a row is only read
/// when there is nothing better, and a week-old reading beside "last updated 6
/// days ago" beats an empty screen.
final class WeatherCache implements WeatherCachePort {
  /// Creates the cache over [_database].
  const WeatherCache(this._database);

  final AuraDatabase _database;

  @override
  Future<Result<Stale<WeatherSnapshot>, AppFailure>> read(
    LocationRef location,
  ) async {
    final found = await guarded(
      () =>
          (_database.select(_database.cachedSnapshots)
                ..where((row) => row.locationQuery.equals(location.query)))
              .getSingleOrNull(),
    );

    return found.fold(_decodeRow, Err<Stale<WeatherSnapshot>, AppFailure>.new);
  }

  @override
  Future<Result<void, AppFailure>> write(
    LocationRef location,
    WeatherSnapshot snapshot, {
    required DateTime fetchedAt,
  }) => guarded<void>(
    () => _database
        .into(_database.cachedSnapshots)
        .insertOnConflictUpdate(
          CachedSnapshotsCompanion.insert(
            locationQuery: location.query,
            fetchedAt: fetchedAt,
            payload: jsonEncode(encodeSnapshot(snapshot)),
          ),
        ),
  );

  @override
  Future<Result<void, AppFailure>> clear() =>
      guarded<void>(() => _database.delete(_database.cachedSnapshots).go());

  Result<Stale<WeatherSnapshot>, AppFailure> _decodeRow(CachedSnapshot? row) {
    if (row == null) {
      return const Err<Stale<WeatherSnapshot>, AppFailure>(CacheMiss());
    }

    try {
      final payload = jsonDecode(row.payload);
      final snapshot = decodeSnapshot(payload as Map<String, Object?>);
      return Ok<Stale<WeatherSnapshot>, AppFailure>(
        Stale<WeatherSnapshot>(snapshot, fetchedAt: row.fetchedAt),
      );
    } on Object catch (error) {
      // A row this build cannot read is a row that is not there. Reporting a
      // miss lets the next successful fetch overwrite it, where reporting a
      // failure would leave the app stuck on a bad row until it was cleared.
      return Err<Stale<WeatherSnapshot>, AppFailure>(CacheMiss(cause: error));
    }
  }
}
