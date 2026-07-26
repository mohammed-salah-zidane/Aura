import 'package:aura_weather_api/aura_weather_api.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

/// Every key the fixture carries, at every level, as `a.b.c` paths.
///
/// Lists collapse to their first element: WeatherAPI repeats the same shape
/// across all 24 hours, so checking one proves the shape without making the
/// expectation 24 times longer.
Set<String> _keyPaths(Object? node, [String prefix = '']) {
  final paths = <String>{};
  if (node is Map<String, dynamic>) {
    for (final entry in node.entries) {
      final path = prefix.isEmpty ? entry.key : '$prefix.${entry.key}';
      paths
        ..add(path)
        ..addAll(_keyPaths(entry.value, path));
    }
  } else if (node is List && node.isNotEmpty) {
    paths.addAll(_keyPaths(node.first, prefix));
  }
  return paths;
}

void main() {
  group('forecast.json decodes the captured Cairo response', () {
    late ForecastResponseDto dto;

    setUp(() {
      dto = ForecastResponseDto.fromJson(loadJsonObject('forecast_cairo'));
    });

    test('fromJson reads the location', () {
      expect(dto.location.name, 'Cairo');
      expect(dto.location.country, 'Egypt');
      expect(dto.location.tzId, 'Africa/Cairo');
      expect(dto.location.lat, closeTo(30.05, 0.001));
    });

    test('fromJson reads the current condition', () {
      expect(dto.current.condition.code, 1000);
      expect(dto.current.condition.text, isNotEmpty);
      expect(dto.current.isDay, anyOf(0, 1));
    });

    test('fromJson reads every metric the home screen renders', () {
      expect(dto.current.tempC, isA<double>());
      expect(dto.current.feelslikeC, isA<double>());
      expect(dto.current.windKph, isA<double>());
      expect(dto.current.windDir, isNotEmpty);
      expect(dto.current.gustKph, isA<double>());
      expect(dto.current.humidity, inInclusiveRange(0, 100));
      expect(dto.current.dewpointC, isA<double>());
      expect(dto.current.uv, greaterThanOrEqualTo(0));
      expect(dto.current.visKm, greaterThanOrEqualTo(0));
      expect(dto.current.pressureMb, greaterThan(0));
      expect(dto.current.pressureIn, greaterThan(0));
    });

    test('fromJson reads air quality including the EPA index', () {
      final air = dto.current.airQuality;
      expect(air, isNotNull);
      expect(air?.usEpaIndex, inInclusiveRange(1, 6));
      expect(air?.gbDefraIndex, inInclusiveRange(1, 10));
      expect(air?.pm25, greaterThanOrEqualTo(0));
      expect(air?.pm10, greaterThanOrEqualTo(0));
      expect(air?.o3, greaterThanOrEqualTo(0));
      expect(air?.no2, greaterThanOrEqualTo(0));
      expect(air?.so2, greaterThanOrEqualTo(0));
      expect(air?.co, greaterThanOrEqualTo(0));
    });

    // The free tier caps at three whatever days asks for, with HTTP 200.
    test('fromJson reads exactly three forecast days', () {
      expect(dto.forecast.forecastday, hasLength(3));
    });

    test('fromJson reads 24 hours for every forecast day', () {
      for (final day in dto.forecast.forecastday) {
        expect(day.hour, hasLength(24), reason: day.date);
      }
    });

    test('fromJson reads the daily high and low', () {
      final day = dto.forecast.forecastday.first.day;
      expect(day.maxtempC, greaterThanOrEqualTo(day.mintempC));
      expect(day.dailyChanceOfRain, inInclusiveRange(0, 100));
    });

    // astro lives inside forecastday, which is why astronomy.json is never
    // called.
    test('fromJson reads astro from inside the forecast day', () {
      final astro = dto.forecast.forecastday.first.astro;
      expect(astro.sunrise, isNotEmpty);
      expect(astro.sunset, isNotEmpty);
      expect(astro.moonPhase, isNotEmpty);
      expect(astro.moonIllumination, inInclusiveRange(0, 100));
    });

    // hour.uv arrives as a bare integer overnight while current.uv is a
    // decimal. A double field would throw on the integer if it were read as
    // one rather than as a number.
    test('fromJson reads an integer hourly uv as a double', () {
      final overnight = dto.forecast.forecastday.first.hour.first;
      expect(overnight.uv, isA<double>());
    });

    test('fromJson reads an empty alert list as no alerts', () {
      expect(dto.alerts?.alert, isEmpty);
    });

    test('toJson carries every key the response had', () {
      final source = loadJsonObject('forecast_cairo');
      expect(_keyPaths(dto.toJson()), containsAll(_keyPaths(source)));
    });
  });

  group('forecast.json decodes a response carrying real alerts', () {
    late ForecastResponseDto dto;

    setUp(() {
      dto = ForecastResponseDto.fromJson(
        loadJsonObject('forecast_alerts_las_vegas'),
      );
    });

    test('fromJson reads every active alert', () {
      expect(dto.alerts?.alert, isNotEmpty);
    });

    test('fromJson reads the fields the alert screen renders', () {
      final alert = (dto.alerts?.alert ?? const <AlertDto>[]).first;
      expect(alert.event, isNotEmpty);
      expect(alert.severity, isNotEmpty);
      expect(alert.category, isNotEmpty);
      expect(alert.areas, isNotEmpty);
      expect(alert.desc, isNotEmpty);
      expect(alert.instruction, isNotEmpty);
      expect(DateTime.parse(alert.effective), isA<DateTime>());
      expect(DateTime.parse(alert.expires), isA<DateTime>());
    });

    test('toJson carries every key the response had', () {
      final source = loadJsonObject('forecast_alerts_las_vegas');
      expect(_keyPaths(dto.toJson()), containsAll(_keyPaths(source)));
    });
  });

  group('search.json decodes the captured autocomplete response', () {
    test('fromJson reads every match', () {
      final results = loadJsonArray('search_cair')
          .map((e) => SearchResultDto.fromJson(e as Map<String, dynamic>))
          .toList();

      expect(results, hasLength(3));
      expect(results.first.name, 'Cairo');
      expect(results.first.country, 'Egypt');
      expect(results.first.url, 'cairo-al-qahirah-egypt');
      expect(results.first.id, greaterThan(0));
    });

    test('fromJson reads a negative latitude', () {
      final results = loadJsonArray('search_cair')
          .map((e) => SearchResultDto.fromJson(e as Map<String, dynamic>))
          .toList();

      expect(results[1].name, 'Cairns');
      expect(results[1].lat, lessThan(0));
    });

    test('toJson carries every key each match had', () {
      for (final entry in loadJsonArray('search_cair')) {
        final source = entry as Map<String, dynamic>;
        final dto = SearchResultDto.fromJson(source);
        expect(_keyPaths(dto.toJson()), containsAll(_keyPaths(source)));
      }
    });
  });

  group('a response missing a required field', () {
    test('fromJson throws rather than producing a half-built DTO', () {
      final broken = loadJsonObject('forecast_cairo')..remove('current');
      expect(() => ForecastResponseDto.fromJson(broken), throwsA(anything));
    });
  });
}
