import 'package:aura_core/aura_core.dart';
import 'package:aura_domain/aura_domain.dart';
import 'package:aura_test_kit/src/weather_fixture.dart';

/// A repository that answers from memory.
///
/// Every method can be told to fail, so a screen's failure branch is exercised
/// with the same fake that exercises its ready one.
final class FakeWeatherRepository implements WeatherRepository {
  /// Creates a repository over a fixed answer.
  FakeWeatherRepository({
    WeatherSnapshot? snapshot,
    this.fetchedAt,
    this.failure,
    this.suggestions = const <CitySuggestion>[],
    this.reading_,
    this.searchFailure,
    this.delay = Duration.zero,
  }) : snapshot_ = snapshot ?? weatherFixture();

  /// What `snapshot` answers with.
  WeatherSnapshot snapshot_;

  /// When that reading was taken. Defaults to the fixture's own instant.
  DateTime? fetchedAt;

  /// Fails `snapshot` with this instead of answering.
  AppFailure? failure;

  /// What `search` answers with.
  List<CitySuggestion> suggestions;

  /// What `reading` answers with.
  CityReading? reading_;

  /// Fails `search` with this instead of answering.
  AppFailure? searchFailure;

  /// How long every answer takes, so a loading state can be looked at.
  Duration delay;

  /// How many times a snapshot has been asked for.
  int snapshotCalls = 0;

  @override
  Future<Result<Stale<WeatherSnapshot>, AppFailure>> snapshot(
    LocationRef location, {
    String? lang,
  }) async {
    snapshotCalls++;
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    final reason = failure;
    if (reason != null) {
      return Err<Stale<WeatherSnapshot>, AppFailure>(reason);
    }
    return Ok<Stale<WeatherSnapshot>, AppFailure>(
      Stale<WeatherSnapshot>(
        snapshot_,
        fetchedAt: fetchedAt ?? fixtureNow,
      ),
    );
  }

  @override
  Future<Result<List<CitySuggestion>, AppFailure>> search(
    String prefix,
  ) async {
    final reason = searchFailure;
    return reason == null
        ? Ok<List<CitySuggestion>, AppFailure>(suggestions)
        : Err<List<CitySuggestion>, AppFailure>(reason);
  }

  @override
  Future<Result<CityReading, AppFailure>> reading(
    LocationRef location, {
    String? lang,
  }) async {
    final answer = reading_;
    return answer == null
        ? const Err<CityReading, AppFailure>(CacheMiss())
        : Ok<CityReading, AppFailure>(answer);
  }
}

/// Preferences held in memory.
final class FakeSettings implements SettingsPort {
  /// Creates a settings store over its starting values.
  FakeSettings({
    this.units = const UnitPreferences(),
    this.notifications = const NotificationPreferences(),
  });

  /// The stored units.
  UnitPreferences units;

  /// The stored notification choices.
  NotificationPreferences notifications;

  @override
  Future<Result<UnitPreferences, AppFailure>> readUnits() async =>
      Ok<UnitPreferences, AppFailure>(units);

  @override
  Future<Result<void, AppFailure>> writeUnits(
    UnitPreferences preferences,
  ) async {
    units = preferences;
    return const Ok<void, AppFailure>(null);
  }

  @override
  Future<Result<NotificationPreferences, AppFailure>>
  readNotifications() async =>
      Ok<NotificationPreferences, AppFailure>(notifications);

  @override
  Future<Result<void, AppFailure>> writeNotifications(
    NotificationPreferences preferences,
  ) async {
    notifications = preferences;
    return const Ok<void, AppFailure>(null);
  }
}

/// Kept cities held in memory.
final class FakeSavedCities implements SavedCitiesPort {
  /// Creates a store over its starting list.
  FakeSavedCities([List<SavedCity>? cities]) : cities = <SavedCity>[...?cities];

  /// What is kept.
  final List<SavedCity> cities;

  @override
  Future<Result<List<SavedCity>, AppFailure>> readAll() async =>
      Ok<List<SavedCity>, AppFailure>(List<SavedCity>.unmodifiable(cities));

  @override
  Future<Result<void, AppFailure>> add(SavedCity city) async {
    if (!cities.contains(city)) cities.add(city);
    return const Ok<void, AppFailure>(null);
  }

  @override
  Future<Result<void, AppFailure>> remove(LocationRef location) async {
    cities.removeWhere((city) => city.location == location);
    return const Ok<void, AppFailure>(null);
  }
}

/// A location port that answers whatever it was told to.
final class FakeLocation implements LocationPort {
  /// Creates a location port.
  FakeLocation({
    this.state = LocationPermission.notDetermined,
    this.granted,
    this.position,
  });

  /// What `permission` answers.
  LocationPermission state;

  /// What `request` answers. Defaults to [state].
  LocationPermission? granted;

  /// What `currentPosition` answers, or null to fail.
  LocationRef? position;

  /// How many times permission has been asked for.
  int requests = 0;

  @override
  Future<LocationPermission> permission() async => state;

  @override
  Future<LocationPermission> request() async {
    requests++;
    return granted ?? state;
  }

  @override
  Future<Result<LocationRef, AppFailure>> currentPosition() async {
    final answer = position;
    return answer == null
        ? const Err<LocationRef, AppFailure>(Unknown())
        : Ok<LocationRef, AppFailure>(answer);
  }
}

/// A notification port that records what it was asked to do.
final class FakeNotifications implements NotificationPort {
  /// Creates a notification port.
  FakeNotifications({this.permitted = true});

  /// Whether the platform grants permission.
  bool permitted;

  /// The hour the daily forecast is scheduled for, or null when it is off.
  int? scheduledHour;

  /// The alerts that were posted.
  final List<WeatherAlert> shown = <WeatherAlert>[];

  /// Whether everything was cancelled.
  bool cancelled = false;

  @override
  Future<bool> requestPermission() async => permitted;

  @override
  Future<Result<void, AppFailure>> scheduleDailyForecast({
    required int? hour,
    required String title,
    required String body,
  }) async {
    scheduledHour = hour;
    return const Ok<void, AppFailure>(null);
  }

  @override
  Future<Result<void, AppFailure>> showAlert(WeatherAlert alert) async {
    shown.add(alert);
    return const Ok<void, AppFailure>(null);
  }

  @override
  Future<Result<void, AppFailure>> cancelAll() async {
    cancelled = true;
    return const Ok<void, AppFailure>(null);
  }
}
