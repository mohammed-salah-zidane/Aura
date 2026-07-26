import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'aura_database.g.dart';

/// One cached reading per place.
///
/// The snapshot is kept as a single document rather than spread across tables
/// for days, hours, alerts and pollutants. It is written and read as a whole,
/// it is never queried by any field inside it, and a normalised schema would
/// buy joins nobody performs at the cost of a migration per entity change.
@DataClassName('CachedSnapshot')
class CachedSnapshots extends Table {
  /// The `q` value the reading was fetched with. One row per place.
  ///
  /// Keyed on the query alone: the weather at a place does not change with the
  /// label the app happens to be showing it under.
  TextColumn get locationQuery => text()();

  /// When the reading came off the network.
  ///
  /// Stored to the second as an instant. The wall-clock times the screens
  /// render live inside the payload, where their zone survives intact.
  DateTimeColumn get fetchedAt => dateTime()();

  /// The snapshot as JSON.
  TextColumn get payload => text()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{locationQuery};
}

/// A place the user has kept.
@DataClassName('SavedCityRow')
class SavedCityRows extends Table {
  /// The `q` value this city is asked about with.
  TextColumn get locationQuery => text()();

  /// The name to show before the real one loads, or null when unknown.
  TextColumn get displayName => text().nullable()();

  /// Its name, as the user saw it when they added it.
  TextColumn get name => text()();

  /// Its country.
  TextColumn get country => text()();

  /// When it was added. Orders the list.
  DateTimeColumn get addedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{locationQuery};
}

/// Aura's local database.
///
/// Holds the offline copy of the last reading per place, and the user's saved
/// cities. Settings live in platform preferences instead: they are a handful
/// of scalars, and a table for them would cost a migration every time one is
/// added.
@DriftDatabase(tables: <Type>[CachedSnapshots, SavedCityRows])
class AuraDatabase extends _$AuraDatabase {
  /// Opens the database over the given query executor.
  ///
  /// Tests pass an in-memory one; the app uses [AuraDatabase.onDevice].
  AuraDatabase(super.e);

  /// Opens the database file the app ships with.
  AuraDatabase.onDevice() : super(driftDatabase(name: _fileName));

  static const String _fileName = 'aura';

  @override
  int get schemaVersion => 1;
}
