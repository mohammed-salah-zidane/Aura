import 'package:aura/src/aura_env.dart';
import 'package:aura_core/aura_core.dart';
import 'package:aura_data/aura_data.dart';
import 'package:aura_domain/aura_domain.dart';
import 'package:aura_storage/aura_storage.dart';
import 'package:aura_weather_api/aura_weather_api.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Every dependency the app is built from, assembled in one place.
///
/// Riverpod is the container as well as the state management, so there is no
/// second registry to keep in step. A feature asks for a port and gets whatever
/// this file decided implements it, which is what lets a test override one
/// collaborator and leave the rest alone.
///
/// Written by hand: `riverpod_generator` needs `analyzer ^12` and the workspace
/// is capped below that by the SDK's own pins.
///
/// The source of "now". Nothing anywhere else calls `DateTime.now()`.
final clockProvider = Provider<Clock>((ref) => const SystemClock());

/// The local database. Opened once and closed when the app lets go of it.
final databaseProvider = Provider<AuraDatabase>((ref) {
  final database = AuraDatabase.onDevice();
  ref.onDispose(database.close);
  return database;
});

/// The WeatherAPI.com client, carrying the credential for every request.
final weatherApiProvider = Provider<WeatherApi>(
  (ref) => WeatherApi.withKey(
    apiKey: AuraEnv.weatherApiKey,
    baseUrl: AuraEnv.weatherApiBaseUrl ?? WeatherApi.defaultBaseUrl,
  ),
);

/// Where a fetched reading is kept so it survives going offline.
final weatherCacheProvider = Provider<WeatherCachePort>(
  (ref) => WeatherCache(ref.watch(databaseProvider)),
);

/// Where weather comes from, as far as every screen is concerned.
final weatherRepositoryProvider = Provider<WeatherRepository>(
  (ref) => WeatherRepositoryImpl(
    api: ref.watch(weatherApiProvider),
    cache: ref.watch(weatherCacheProvider),
    clock: ref.watch(clockProvider),
  ),
);

/// The user's kept cities.
final savedCitiesProvider = Provider<SavedCitiesPort>(
  (ref) => SavedCitiesStore(ref.watch(databaseProvider)),
);

/// The user's own choices.
final settingsProvider = Provider<SettingsPort>(
  (ref) => PreferencesStore.onDevice(),
);
