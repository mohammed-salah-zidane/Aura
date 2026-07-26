/// Local storage.
///
/// Implements the domain's three storage ports against the device: the last
/// reading per place and the user's saved cities in a Drift database, and the
/// user's own choices in platform preferences.
///
/// Knows nothing about weather beyond the entities it stores, and nothing about
/// the network at all. It never decides *whether* to use the cache; that is the
/// repository's job.
library;

export 'src/database/aura_database.dart' show AuraDatabase;
export 'src/preferences_store.dart';
export 'src/saved_cities_store.dart';
export 'src/weather_cache.dart';
