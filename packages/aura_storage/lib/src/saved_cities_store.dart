import 'package:aura_core/aura_core.dart';
import 'package:aura_domain/aura_domain.dart';
import 'package:aura_storage/src/database/aura_database.dart';
import 'package:aura_storage/src/guarded.dart';
import 'package:drift/drift.dart';

/// The cities the user has kept.
///
/// Holds only what the list needs to exist. The reading beside each row is
/// fetched separately, so removing a city never waits on its weather.
final class SavedCitiesStore implements SavedCitiesPort {
  /// Creates the store over [_database].
  const SavedCitiesStore(this._database);

  final AuraDatabase _database;

  @override
  Future<Result<List<SavedCity>, AppFailure>> readAll() => guarded(() async {
    final query = _database.select(_database.savedCityRows)
      ..orderBy(<OrderClauseGenerator<$SavedCityRowsTable>>[
        (row) => OrderingTerm.asc(row.addedAt),
      ]);
    final rows = await query.get();
    return rows.map(_toCity).toList(growable: false);
  });

  @override
  Future<Result<void, AppFailure>> add(SavedCity city) => guarded<void>(
    // Adding a city that is already saved changes nothing, including the
    // moment it was added, which is what orders the list.
    () => _database
        .into(_database.savedCityRows)
        .insert(
          SavedCityRowsCompanion.insert(
            locationQuery: city.location.query,
            displayName: Value<String?>(city.location.displayName),
            name: city.name,
            country: city.country,
            addedAt: city.addedAt,
          ),
          mode: InsertMode.insertOrIgnore,
        ),
  );

  @override
  Future<Result<void, AppFailure>> remove(LocationRef location) =>
      guarded<void>(
        () => (_database.delete(
          _database.savedCityRows,
        )..where((row) => row.locationQuery.equals(location.query))).go(),
      );

  SavedCity _toCity(SavedCityRow row) => SavedCity(
    location: LocationRef(
      query: row.locationQuery,
      displayName: row.displayName,
    ),
    name: row.name,
    country: row.country,
    addedAt: row.addedAt,
  );
}
