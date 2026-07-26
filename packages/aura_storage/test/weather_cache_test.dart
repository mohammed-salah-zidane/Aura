import 'dart:io';

import 'package:aura_core/aura_core.dart';
import 'package:aura_domain/aura_domain.dart';
import 'package:aura_storage/aura_storage.dart';
// The generated companion is how a test writes a row the cache did not write,
// which is the only way to reach the unreadable-row branch.
import 'package:aura_storage/src/database/aura_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/captured_snapshot.dart';

void main() {
  const cairo = LocationRef(query: 'Cairo');
  const london = LocationRef(query: 'London');
  final fetchedAt = DateTime.utc(2026, 7, 26, 11, 30);

  late AuraDatabase database;
  late WeatherCache cache;

  setUp(() {
    database = AuraDatabase(NativeDatabase.memory());
    cache = WeatherCache(database);
  });

  tearDown(() => database.close());

  group('read with nothing stored', () {
    test('read returns CacheMiss for a place never fetched', () async {
      expect((await cache.read(cairo)).failureOrNull, isA<CacheMiss>());
    });

    test('read returns CacheMiss for a different place', () async {
      await cache.write(
        cairo,
        capturedSnapshot('forecast_cairo'),
        fetchedAt: fetchedAt,
      );

      expect((await cache.read(london)).failureOrNull, isA<CacheMiss>());
    });
  });

  group('read after a write', () {
    late WeatherSnapshot written;

    setUp(() async {
      written = capturedSnapshot('forecast_cairo');
      await cache.write(cairo, written, fetchedAt: fetchedAt);
    });

    test('read returns the stored reading', () async {
      final result = await cache.read(cairo);

      expect(result.isOk, isTrue);
      expect(result.valueOrNull?.value.placeName, written.placeName);
      expect(result.valueOrNull?.value.region, written.region);
      expect(result.valueOrNull?.value.country, written.country);
    });

    // This is what renders "Last updated 2h ago", so it has to survive the
    // round trip as the instant it was written with.
    test('read returns the moment the reading was fetched', () async {
      final result = await cache.read(cairo);

      expect(result.valueOrNull?.fetchedAt.isAtSameMomentAs(fetchedAt), isTrue);
      expect(
        result.valueOrNull?.age(
          FixedClock(fetchedAt.add(const Duration(hours: 2))),
        ),
        const Duration(hours: 2),
      );
    });

    // A place's wall clock is not the device's. Storing an epoch would shift
    // a 6:10 sunrise into whatever zone the phone happens to be in.
    test('read keeps every wall clock unshifted', () async {
      final read = (await cache.read(cairo)).valueOrNull?.value;

      expect(read?.localTime, written.localTime);
      expect(read?.localTime.isUtc, isFalse);
      expect(read?.current.observedAt, written.current.observedAt);
      expect(read?.today.date, written.today.date);
      expect(read?.today.astro.sunrise, written.today.astro.sunrise);
      expect(read?.today.astro.sunset, written.today.astro.sunset);
      expect(read?.today.hours.first.time, written.today.hours.first.time);
      expect(read?.today.hours.last.time, written.today.hours.last.time);
    });

    test('read returns every current field it was given', () async {
      final read = (await cache.read(cairo)).valueOrNull?.value.current;
      final source = written.current;

      expect(read?.temperature, source.temperature);
      expect(read?.feelsLike, source.feelsLike);
      expect(read?.condition, source.condition);
      expect(read?.conditionText, source.conditionText);
      expect(read?.isDay, source.isDay);
      expect(read?.windSpeed, source.windSpeed);
      expect(read?.windDirection, source.windDirection);
      expect(read?.gustSpeed, source.gustSpeed);
      expect(read?.humidityPercent, source.humidityPercent);
      expect(read?.dewPoint, source.dewPoint);
      expect(read?.pressure, source.pressure);
      expect(
        read?.pressureInchesOfMercury,
        source.pressureInchesOfMercury,
      );
      expect(read?.visibility, source.visibility);
      expect(read?.uvIndex, source.uvIndex);
      expect(read?.cloudPercent, source.cloudPercent);
      expect(read?.uvSeverity, source.uvSeverity);
    });

    test('read returns all three days with their 24 hours', () async {
      final read = (await cache.read(cairo)).valueOrNull?.value;

      expect(read?.days, hasLength(written.days.length));
      for (var i = 0; i < written.days.length; i++) {
        final source = written.days[i];
        final day = read?.days[i];
        expect(day?.date, source.date);
        expect(day?.low, source.low);
        expect(day?.high, source.high);
        expect(day?.condition, source.condition);
        expect(day?.conditionText, source.conditionText);
        expect(day?.chanceOfRainPercent, source.chanceOfRainPercent);
        expect(day?.uvIndex, source.uvIndex);
        expect(day?.hours, hasLength(24));
      }
    });

    test('read returns an hour with every field it was given', () async {
      final read = (await cache.read(cairo)).valueOrNull?.value;
      final source = written.today.hours[14];
      final hour = read?.today.hours[14];

      expect(hour?.time, source.time);
      expect(hour?.temperature, source.temperature);
      expect(hour?.condition, source.condition);
      expect(hour?.conditionText, source.conditionText);
      expect(hour?.isDay, source.isDay);
      expect(hour?.chanceOfRainPercent, source.chanceOfRainPercent);
    });

    test('read returns the moon phase and illumination', () async {
      final astro = (await cache.read(cairo)).valueOrNull?.value.today.astro;

      expect(astro?.moonPhase, written.today.astro.moonPhase);
      expect(astro?.moonrise, written.today.astro.moonrise);
      expect(astro?.moonset, written.today.astro.moonset);
      expect(
        astro?.moonIlluminationPercent,
        written.today.astro.moonIlluminationPercent,
      );
    });

    test('read returns every pollutant and the EPA index', () async {
      final air = (await cache.read(cairo)).valueOrNull?.value.airQuality;

      expect(air?.usEpaIndex, written.airQuality?.usEpaIndex);
      expect(air?.category, written.airQuality?.category);
      for (final pollutant in Pollutant.values) {
        expect(
          air?.concentrations[pollutant],
          written.airQuality?.concentrations[pollutant],
          reason: 'lost $pollutant',
        );
      }
      expect(air?.bandFor(Pollutant.co), isNull);
    });

    test('write replaces the reading rather than adding a second', () async {
      final later = fetchedAt.add(const Duration(hours: 3));
      await cache.write(cairo, written, fetchedAt: later);

      final rows = await database.select(database.cachedSnapshots).get();
      expect(rows, hasLength(1));
      expect(
        (await cache.read(
          cairo,
        )).valueOrNull?.fetchedAt.isAtSameMomentAs(later),
        isTrue,
      );
    });

    test('write keeps two places apart', () async {
      await cache.write(
        london,
        capturedSnapshot('forecast_alerts_las_vegas'),
        fetchedAt: fetchedAt,
      );

      expect((await cache.read(cairo)).valueOrNull?.value.placeName, 'Cairo');
      expect(
        (await cache.read(london)).valueOrNull?.value.placeName,
        isNot('Cairo'),
      );
    });
  });

  group('read after a write carrying the shapes Cairo does not have', () {
    test('read returns every alert it was given', () async {
      final written = capturedSnapshot('forecast_alerts_las_vegas');
      await cache.write(cairo, written, fetchedAt: fetchedAt);

      final read = (await cache.read(cairo)).valueOrNull?.value;

      expect(read?.alerts, hasLength(written.alerts.length));
      expect(read?.alerts.first.event, written.alerts.first.event);
      expect(read?.alerts.first.severity, written.alerts.first.severity);
      expect(read?.alerts.first.category, written.alerts.first.category);
      expect(read?.alerts.first.areas, written.alerts.first.areas);
      expect(
        read?.alerts.first.description,
        written.alerts.first.description,
      );
      expect(
        read?.alerts.first.instruction,
        written.alerts.first.instruction,
      );
      expect(read?.headlineAlert?.severity, AlertSeverity.severe);
    });

    // An alert's times carry a zone offset, so unlike everything else in a
    // snapshot they are instants and have to come back as instants.
    test('read keeps an alert time an instant', () async {
      final written = capturedSnapshot('forecast_alerts_las_vegas');
      await cache.write(cairo, written, fetchedAt: fetchedAt);

      final alert = (await cache.read(cairo)).valueOrNull?.value.alerts.first;

      expect(alert?.effective, written.alerts.first.effective);
      expect(alert?.effective?.isUtc, isTrue);
      expect(alert?.expires, written.alerts.first.expires);
    });

    test('read returns a day with no sunrise as having none', () async {
      final written = capturedSnapshot(
        'forecast_cairo',
        patch: (json) {
          final astro =
              ((json['forecast']! as Map<String, dynamic>)['forecastday']!
                          as List<dynamic>)
                      .first
                  as Map<String, dynamic>;
          (astro['astro']! as Map<String, dynamic>)
            ..['sunrise'] = 'No sunrise'
            ..['sunset'] = 'No sunset';
        },
      );
      await cache.write(cairo, written, fetchedAt: fetchedAt);

      final astro = (await cache.read(cairo)).valueOrNull?.value.today.astro;

      expect(astro?.sunrise, isNull);
      expect(astro?.sunset, isNull);
      expect(astro?.moonset, isNotNull);
    });

    test('read returns a reading with no air quality as having none', () async {
      final written = capturedSnapshot(
        'forecast_cairo',
        patch: (json) =>
            (json['current']! as Map<String, dynamic>).remove('air_quality'),
      );
      await cache.write(cairo, written, fetchedAt: fetchedAt);

      expect((await cache.read(cairo)).valueOrNull?.value.airQuality, isNull);
    });

    test('read returns an empty alert list as no alerts', () async {
      await cache.write(
        cairo,
        capturedSnapshot('forecast_cairo'),
        fetchedAt: fetchedAt,
      );

      expect((await cache.read(cairo)).valueOrNull?.value.alerts, isEmpty);
    });
  });

  group('read of a row this build cannot use', () {
    // A row left by a build that wrote a different shape is a row that is not
    // there. Reporting a miss lets the next fetch overwrite it, where a hard
    // failure would leave the app stuck on it.
    test('read returns CacheMiss for a payload it cannot parse', () async {
      await database
          .into(database.cachedSnapshots)
          .insert(
            CachedSnapshotsCompanion.insert(
              locationQuery: cairo.query,
              fetchedAt: fetchedAt,
              payload: '{"placeName":"Cairo"}',
            ),
          );

      expect((await cache.read(cairo)).failureOrNull, isA<CacheMiss>());
    });

    test('read returns CacheMiss for a payload that is not JSON', () async {
      await database
          .into(database.cachedSnapshots)
          .insert(
            CachedSnapshotsCompanion.insert(
              locationQuery: cairo.query,
              fetchedAt: fetchedAt,
              payload: 'not json at all',
            ),
          );

      expect((await cache.read(cairo)).failureOrNull, isA<CacheMiss>());
    });

    test('a later write overwrites a row that could not be read', () async {
      await database
          .into(database.cachedSnapshots)
          .insert(
            CachedSnapshotsCompanion.insert(
              locationQuery: cairo.query,
              fetchedAt: fetchedAt,
              payload: 'not json at all',
            ),
          );

      await cache.write(
        cairo,
        capturedSnapshot('forecast_cairo'),
        fetchedAt: fetchedAt,
      );

      expect((await cache.read(cairo)).valueOrNull?.value.placeName, 'Cairo');
    });
  });

  group('clear', () {
    test('clear drops every place', () async {
      await cache.write(
        cairo,
        capturedSnapshot('forecast_cairo'),
        fetchedAt: fetchedAt,
      );
      await cache.write(
        london,
        capturedSnapshot('forecast_alerts_las_vegas'),
        fetchedAt: fetchedAt,
      );

      expect((await cache.clear()).isOk, isTrue);

      expect((await cache.read(cairo)).failureOrNull, isA<CacheMiss>());
      expect((await cache.read(london)).failureOrNull, isA<CacheMiss>());
    });

    test('clear on an empty cache succeeds', () async {
      expect((await cache.clear()).isOk, isTrue);
    });
  });

  // Storage is the last layer that can still throw. A file it cannot open
  // stands in for the real cases: a full disk, a revoked container, a database
  // another isolate holds.
  group('when the database cannot be opened', () {
    late WeatherCache unopenable;

    setUp(() async {
      // The working database goes first, so only one exists at a time and
      // drift has nothing to warn about.
      await database.close();
      unopenable = WeatherCache(
        AuraDatabase(
          NativeDatabase(File('/aura-test-no-such-directory/aura.sqlite')),
        ),
      );
    });

    test('read reports a failure rather than throwing', () async {
      expect((await unopenable.read(cairo)).failureOrNull, isA<Unknown>());
    });

    test('write reports a failure rather than throwing', () async {
      final result = await unopenable.write(
        cairo,
        capturedSnapshot('forecast_cairo'),
        fetchedAt: fetchedAt,
      );

      expect(result.failureOrNull, isA<Unknown>());
    });

    test('clear reports a failure rather than throwing', () async {
      expect((await unopenable.clear()).failureOrNull, isA<Unknown>());
    });
  });
}
