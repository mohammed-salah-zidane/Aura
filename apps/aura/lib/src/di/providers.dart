import 'package:aura/src/aura_env.dart';
import 'package:aura/src/platform/device_location.dart';
import 'package:aura/src/platform/device_notifications.dart';
import 'package:aura_data/aura_data.dart';
import 'package:aura_domain/aura_domain.dart';
import 'package:aura_providers/aura_providers.dart';
import 'package:aura_storage/aura_storage.dart';
import 'package:aura_weather_api/aura_weather_api.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Override is published from `misc.dart` rather than the main library.
import 'package:flutter_riverpod/misc.dart' show Override;

/// Everything the app is built from, assembled in one place.
///
/// `aura_providers` declares one provider per domain port and leaves each
/// unimplemented. This file answers them, and it is the only file in the
/// repository that sees the data, storage and platform layers at once. A
/// feature asks for a port and gets whatever is decided here, which is what
/// lets a test override one collaborator and leave the rest alone.
///
/// Written by hand: `riverpod_generator` needs `analyzer ^12` and the
/// workspace is capped below that by the SDK's own pins.
///
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

/// The platform's notification plugin, wrapped in the adapter.
final deviceNotificationsProvider = Provider<DeviceNotifications>(
  (ref) => DeviceNotifications(
    FlutterLocalNotificationsPlugin(),
    ref.watch(clockProvider),
  ),
);

/// What every port declared in `aura_providers` resolves to on a device.
///
/// Handed to the root `ProviderScope`. A test builds its own list and leaves
/// out whatever it is not exercising.
List<Override> deviceOverrides() => <Override>[
  weatherRepositoryProvider.overrideWith(
    (ref) => WeatherRepositoryImpl(
      api: ref.watch(weatherApiProvider),
      cache: ref.watch(weatherCacheProvider),
      clock: ref.watch(clockProvider),
    ),
  ),
  settingsPortProvider.overrideWith((ref) => PreferencesStore.onDevice()),
  savedCitiesPortProvider.overrideWith(
    (ref) => SavedCitiesStore(ref.watch(databaseProvider)),
  ),
  locationPortProvider.overrideWith((ref) => const DeviceLocation()),
  notificationPortProvider.overrideWith(
    (ref) => ref.watch(deviceNotificationsProvider),
  ),
];
