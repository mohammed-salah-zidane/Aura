import 'package:aura/src/di/providers.dart';
import 'package:aura_core/aura_core.dart';
import 'package:aura_data/aura_data.dart';
import 'package:aura_domain/aura_domain.dart';
import 'package:aura_storage/aura_storage.dart';
import 'package:aura_weather_api/aura_weather_api.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  late AuraDatabase database;
  late ProviderContainer container;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    database = AuraDatabase(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(database)],
    );
  });

  tearDown(() {
    container.dispose();
    return database.close();
  });

  group('the graph the app is built from', () {
    test('weatherRepositoryProvider resolves to the data implementation', () {
      expect(
        container.read(weatherRepositoryProvider),
        isA<WeatherRepositoryImpl>(),
      );
    });

    test('weatherCacheProvider resolves to the Drift cache', () {
      expect(container.read(weatherCacheProvider), isA<WeatherCache>());
    });

    test('savedCitiesProvider resolves to the Drift store', () {
      expect(container.read(savedCitiesProvider), isA<SavedCitiesStore>());
    });

    test('settingsProvider resolves to the preferences store', () {
      expect(container.read(settingsProvider), isA<PreferencesStore>());
    });

    test('weatherApiProvider resolves to the SDK', () {
      expect(container.read(weatherApiProvider), isA<WeatherApi>());
    });

    test('clockProvider resolves to the system clock', () {
      expect(container.read(clockProvider), isA<SystemClock>());
    });
  });

  group('what the graph shares', () {
    // The cache and the saved cities are two views of one database. Two
    // connections to one sqlite file is how a database gets corrupted.
    test('the cache and the saved cities share one database', () {
      var opened = 0;
      final probe = ProviderContainer(
        overrides: [
          databaseProvider.overrideWith((ref) {
            opened++;
            return database;
          }),
        ],
      );
      addTearDown(probe.dispose);

      probe
        ..read(weatherCacheProvider)
        ..read(savedCitiesProvider);

      expect(opened, 1);
    });

    test('the repository is built once and reused', () {
      expect(
        container.read(weatherRepositoryProvider),
        same(container.read(weatherRepositoryProvider)),
      );
    });
  });

  // This is the whole point of the container. A test overrides one port and
  // everything else stays exactly as the app assembles it.
  group('a port swapped for a fake', () {
    test('overriding the repository leaves the rest of the graph alone', () {
      const swapped = _EmptyRepository();
      final overridden = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(database),
          weatherRepositoryProvider.overrideWithValue(swapped),
        ],
      );
      addTearDown(overridden.dispose);

      expect(overridden.read(weatherRepositoryProvider), same(swapped));
      expect(overridden.read(weatherCacheProvider), isA<WeatherCache>());
    });
  });

  // databaseProvider's own body is not exercised here: AuraDatabase.onDevice
  // asks path_provider for the documents directory, which needs a platform
  // binding, and overriding the body would only test the override. The
  // connection it opens, and the onDispose that closes it, are covered by the
  // integration suite, which runs on a device.
}

class _EmptyRepository implements WeatherRepository {
  const _EmptyRepository();

  @override
  Future<Result<Stale<WeatherSnapshot>, AppFailure>> snapshot(
    LocationRef location, {
    String? lang,
  }) async => const Err<Stale<WeatherSnapshot>, AppFailure>(CacheMiss());

  @override
  Future<Result<List<CitySuggestion>, AppFailure>> search(
    String prefix,
  ) async => const Ok<List<CitySuggestion>, AppFailure>(<CitySuggestion>[]);
}
