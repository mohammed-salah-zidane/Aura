import 'package:aura_core/aura_core.dart';
import 'package:aura_domain/aura_domain.dart';
import 'package:aura_providers/aura_providers.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:riverpod/riverpod.dart';
import 'package:test/test.dart' hide Timeout;

final DateTime _now = DateTime(2026, 7, 26, 14, 34);

WeatherSnapshot _snapshot() => WeatherSnapshot(
  placeName: 'Cairo',
  region: '',
  country: 'Egypt',
  localTime: _now,
  current: CurrentConditions(
    observedAt: _now,
    temperature: const Temperature.celsius(35),
    feelsLike: const Temperature.celsius(38),
    condition: AuraCondition.clearDay,
    conditionText: 'Sunny',
    isDay: true,
    windSpeed: const Speed.kilometersPerHour(15),
    windDirection: 'NW',
    gustSpeed: const Speed.kilometersPerHour(22),
    humidityPercent: 38,
    dewPoint: const Temperature.celsius(19),
    pressure: const Pressure.millibars(1013),
    pressureInchesOfMercury: 29.92,
    visibility: const Distance.kilometers(10),
    uvIndex: 9,
    cloudPercent: 5,
  ),
  days: <ForecastDay>[
    ForecastDay(
      date: _now,
      low: const Temperature.celsius(24),
      high: const Temperature.celsius(37),
      condition: AuraCondition.clearDay,
      conditionText: 'Sunny',
      chanceOfRainPercent: 0,
      uvIndex: 9,
      astro: const AstroInfo(
        moonPhase: MoonPhase.newMoon,
        moonIlluminationPercent: 0,
      ),
      hours: const <HourlyPoint>[],
    ),
  ],
);

final class _Repository implements WeatherRepository {
  _Repository({this.fetchedAt, this.failure});

  DateTime? fetchedAt;
  AppFailure? failure;
  String? lastLang;
  LocationRef? lastLocation;

  @override
  Future<Result<Stale<WeatherSnapshot>, AppFailure>> snapshot(
    LocationRef location, {
    String? lang,
  }) async {
    lastLocation = location;
    lastLang = lang;
    final reason = failure;
    return reason == null
        ? Ok<Stale<WeatherSnapshot>, AppFailure>(
            Stale<WeatherSnapshot>(_snapshot(), fetchedAt: fetchedAt ?? _now),
          )
        : Err<Stale<WeatherSnapshot>, AppFailure>(reason);
  }

  @override
  Future<Result<List<CitySuggestion>, AppFailure>> search(
    String prefix,
  ) async => const Ok<List<CitySuggestion>, AppFailure>(<CitySuggestion>[]);

  @override
  Future<Result<CityReading, AppFailure>> reading(
    LocationRef location, {
    String? lang,
  }) async => const Err<CityReading, AppFailure>(CacheMiss());
}

final class _Settings implements SettingsPort {
  UnitPreferences units = const UnitPreferences();
  NotificationPreferences notifications = const NotificationPreferences();
  bool fails = false;

  @override
  Future<Result<UnitPreferences, AppFailure>> readUnits() async => fails
      ? const Err<UnitPreferences, AppFailure>(CacheMiss())
      : Ok<UnitPreferences, AppFailure>(units);

  @override
  Future<Result<void, AppFailure>> writeUnits(
    UnitPreferences preferences,
  ) async {
    units = preferences;
    return const Ok<void, AppFailure>(null);
  }

  @override
  Future<Result<NotificationPreferences, AppFailure>>
  readNotifications() async => fails
      ? const Err<NotificationPreferences, AppFailure>(CacheMiss())
      : Ok<NotificationPreferences, AppFailure>(notifications);

  @override
  Future<Result<void, AppFailure>> writeNotifications(
    NotificationPreferences preferences,
  ) async {
    notifications = preferences;
    return const Ok<void, AppFailure>(null);
  }
}

final class _Cities implements SavedCitiesPort {
  final List<SavedCity> cities = <SavedCity>[];

  @override
  Future<Result<List<SavedCity>, AppFailure>> readAll() async =>
      Ok<List<SavedCity>, AppFailure>(List<SavedCity>.of(cities));

  @override
  Future<Result<void, AppFailure>> add(SavedCity city) async {
    cities.add(city);
    return const Ok<void, AppFailure>(null);
  }

  @override
  Future<Result<void, AppFailure>> remove(LocationRef location) async {
    cities.removeWhere((city) => city.location == location);
    return const Ok<void, AppFailure>(null);
  }
}

ProviderContainer _container({
  _Repository? repository,
  _Settings? settings,
  _Cities? cities,
  DateTime? now,
}) => ProviderContainer(
  overrides: <Override>[
    clockProvider.overrideWithValue(FixedClock(now ?? _now)),
    weatherRepositoryProvider.overrideWithValue(repository ?? _Repository()),
    settingsPortProvider.overrideWithValue(settings ?? _Settings()),
    savedCitiesPortProvider.overrideWithValue(cities ?? _Cities()),
  ],
);

void main() {
  group('ports', () {
    test('reading a port with no implementation names it', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        () => container.read(settingsPortProvider),
        throwsA(
          isA<Object>().having(
            (error) => error.toString(),
            'message',
            contains('settingsPortProvider'),
          ),
        ),
      );
    });

    test('the clock has a real implementation, needing no platform', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(clockProvider), isA<SystemClock>());
    });
  });

  group('weatherFeedProvider', () {
    test('build marks a reading taken this run as live', () async {
      final container = _container();
      addTearDown(container.dispose);

      final feed = await container.read(weatherFeedProvider.future);
      expect(feed.valueOrNull?.isLive, isTrue);
    });

    test('build marks a reading older than the request as not live', () async {
      final container = _container(
        repository: _Repository(
          fetchedAt: _now.subtract(const Duration(hours: 2)),
        ),
      );
      addTearDown(container.dispose);

      final feed = await container.read(weatherFeedProvider.future);
      expect(feed.valueOrNull?.isLive, isFalse);
      expect(
        feed.valueOrNull?.age(FixedClock(_now)),
        const Duration(hours: 2),
      );
    });

    test('build carries the failure rather than throwing it', () async {
      final container = _container(
        repository: _Repository(failure: const NoConnection()),
      );
      addTearDown(container.dispose);

      final feed = await container.read(weatherFeedProvider.future);
      expect(feed.failureOrNull, const NoConnection());
    });

    test('build asks about the active place in the active language', () async {
      final repository = _Repository();
      final container = _container(repository: repository);
      addTearDown(container.dispose);

      container.read(languageProvider.notifier).tag = 'ar';
      container.read(activeLocationProvider.notifier).location =
          const LocationRef(query: 'London');

      await container.read(weatherFeedProvider.future);

      expect(repository.lastLocation?.query, 'London');
      expect(repository.lastLang, 'ar');
    });
  });

  group('unitPreferencesProvider', () {
    test(
      'build falls back to the defaults when storage cannot be read',
      () async {
        // A temperature is still worth drawing when a preference is not.
        final settings = _Settings()..fails = true;
        final container = _container(settings: settings);
        addTearDown(container.dispose);

        expect(
          await container.read(unitPreferencesProvider.future),
          const UnitPreferences(),
        );
      },
    );

    test('select stores the choice and publishes it at once', () async {
      final settings = _Settings();
      final container = _container(settings: settings);
      addTearDown(container.dispose);
      await container.read(unitPreferencesProvider.future);

      await container
          .read(unitPreferencesProvider.notifier)
          .select(
            const UnitPreferences(temperature: TemperatureUnit.fahrenheit),
          );

      expect(settings.units.temperature, TemperatureUnit.fahrenheit);
      expect(
        container.read(unitPreferencesProvider).value?.temperature,
        TemperatureUnit.fahrenheit,
      );
    });
  });

  group('savedCitiesProvider', () {
    test('add keeps the place and re-reads the list', () async {
      final cities = _Cities();
      final container = _container(cities: cities);
      addTearDown(container.dispose);
      await container.read(savedCitiesProvider.future);

      await container
          .read(savedCitiesProvider.notifier)
          .add(
            SavedCity(
              location: const LocationRef(query: 'London'),
              name: 'London',
              country: 'United Kingdom',
              addedAt: _now,
            ),
          );

      expect(await container.read(savedCitiesProvider.future), hasLength(1));
    });

    test('remove forgets the place', () async {
      final cities = _Cities();
      final container = _container(cities: cities);
      addTearDown(container.dispose);
      await container.read(savedCitiesProvider.future);
      await container
          .read(savedCitiesProvider.notifier)
          .add(
            SavedCity(
              location: const LocationRef(query: 'London'),
              name: 'London',
              country: 'United Kingdom',
              addedAt: _now,
            ),
          );

      await container
          .read(savedCitiesProvider.notifier)
          .remove(const LocationRef(query: 'London'));

      expect(await container.read(savedCitiesProvider.future), isEmpty);
    });
  });

  group('activeLocationProvider', () {
    test('build starts on the position the service resolves for itself', () {
      final container = _container();
      addTearDown(container.dispose);

      expect(container.read(activeLocationProvider).isCurrentLocation, isTrue);
    });
  });
}
