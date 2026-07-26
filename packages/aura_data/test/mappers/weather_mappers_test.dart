import 'package:aura_data/aura_data.dart';
import 'package:aura_domain/aura_domain.dart';
import 'package:aura_weather_api/aura_weather_api.dart';
import 'package:test/test.dart';

import '../fixtures.dart';

/// Reaches into the raw fixture so an expectation names the wire field it came
/// from. A mapper that reads `feelslike_c` where it meant `temp_c` fails here,
/// which asserting `isA<double>()` would not catch.
Object? _raw(Map<String, dynamic> json, String path) {
  Object? node = json;
  for (final key in path.split('.')) {
    final index = int.tryParse(key);
    if (index != null && node is List) {
      node = node[index];
    } else if (node is Map<String, dynamic>) {
      node = node[key];
    } else {
      return null;
    }
  }
  return node;
}

void main() {
  group('snapshotFromDto over the captured Cairo response', () {
    late Map<String, dynamic> json;
    late WeatherSnapshot snapshot;

    setUp(() {
      json = loadJsonObject('forecast_cairo');
      snapshot = snapshotFromDto(ForecastResponseDto.fromJson(json));
    });

    test('snapshotFromDto reads the place from location', () {
      expect(snapshot.placeName, _raw(json, 'location.name'));
      expect(snapshot.region, _raw(json, 'location.region'));
      expect(snapshot.country, _raw(json, 'location.country'));
    });

    test('snapshotFromDto keeps localtime as the place own wall clock', () {
      expect(snapshot.localTime, DateTime(2026, 7, 26, 13, 54));
      expect(snapshot.localTime.isUtc, isFalse);
      expect(_raw(json, 'location.localtime'), '2026-07-26 13:54');
    });

    test('snapshotFromDto maps every current field the design renders', () {
      final current = snapshot.current;
      expect(current.temperature.celsius, _raw(json, 'current.temp_c'));
      expect(current.feelsLike.celsius, _raw(json, 'current.feelslike_c'));
      expect(current.conditionText, _raw(json, 'current.condition.text'));
      expect(
        current.windSpeed.kilometersPerHour,
        _raw(json, 'current.wind_kph'),
      );
      expect(current.windDirection, _raw(json, 'current.wind_dir'));
      expect(
        current.gustSpeed.kilometersPerHour,
        _raw(json, 'current.gust_kph'),
      );
      expect(current.humidityPercent, _raw(json, 'current.humidity'));
      expect(current.dewPoint.celsius, _raw(json, 'current.dewpoint_c'));
      expect(current.pressure.millibars, _raw(json, 'current.pressure_mb'));
      expect(current.visibility.kilometers, _raw(json, 'current.vis_km'));
      expect(current.uvIndex, _raw(json, 'current.uv'));
      expect(current.cloudPercent, _raw(json, 'current.cloud'));
      expect(_raw(json, 'current.last_updated'), '2026-07-26 13:30');
      expect(current.observedAt, DateTime(2026, 7, 26, 13, 30));
      expect(current.observedAt.isUtc, isFalse);
    });

    // pressure_in and pressure_mb disagree in the last digit, so the reported
    // value is carried rather than converted.
    test('snapshotFromDto carries pressure_in as reported', () {
      expect(
        snapshot.current.pressureInchesOfMercury,
        _raw(json, 'current.pressure_in'),
      );
      expect(
        snapshot.current.pressureInchesOfMercury,
        isNot(closeTo(snapshot.current.pressure.inchesOfMercury, 0.0000001)),
      );
    });

    test('snapshotFromDto reads the sky from the code and is_day', () {
      expect(_raw(json, 'current.condition.code'), 1000);
      expect(_raw(json, 'current.is_day'), 1);
      expect(snapshot.current.condition, AuraCondition.clearDay);
      expect(snapshot.current.isDay, isTrue);
    });

    test('snapshotFromDto maps all three forecast days', () {
      expect(snapshot.days, hasLength(3));
      expect(snapshot.today.date, DateTime(2026, 7, 26));
      expect(snapshot.days.last.date, DateTime(2026, 7, 28));
    });

    test('snapshotFromDto maps a day summary from its day block', () {
      final day = snapshot.today;
      expect(
        day.low.celsius,
        _raw(json, 'forecast.forecastday.0.day.mintemp_c'),
      );
      expect(
        day.high.celsius,
        _raw(json, 'forecast.forecastday.0.day.maxtemp_c'),
      );
      expect(
        day.chanceOfRainPercent,
        _raw(json, 'forecast.forecastday.0.day.daily_chance_of_rain'),
      );
      expect(day.uvIndex, _raw(json, 'forecast.forecastday.0.day.uv'));
      expect(
        day.conditionText,
        _raw(json, 'forecast.forecastday.0.day.condition.text'),
      );
    });

    // A row in the forecast list never shows a night sky, so a daily summary
    // resolves its clear code to the daytime one whatever hour it is read at.
    test('snapshotFromDto resolves a daily clear code to the day sky', () {
      expect(_raw(json, 'forecast.forecastday.0.day.condition.code'), 1000);
      expect(snapshot.today.condition, AuraCondition.clearDay);
    });

    test('snapshotFromDto maps 24 hours per day in ascending order', () {
      for (final day in snapshot.days) {
        expect(day.hours, hasLength(24));
        for (var i = 1; i < day.hours.length; i++) {
          expect(day.hours[i].time.isAfter(day.hours[i - 1].time), isTrue);
        }
      }
    });

    test('snapshotFromDto maps an hour from its own fields', () {
      final hour = snapshot.today.hours[14];
      expect(hour.time, DateTime(2026, 7, 26, 14));
      expect(
        hour.temperature.celsius,
        _raw(json, 'forecast.forecastday.0.hour.14.temp_c'),
      );
      expect(
        hour.chanceOfRainPercent,
        _raw(json, 'forecast.forecastday.0.hour.14.chance_of_rain'),
      );
      expect(
        hour.conditionText,
        _raw(json, 'forecast.forecastday.0.hour.14.condition.text'),
      );
    });

    test('snapshotFromDto reads is_day per hour, not from the day', () {
      final overnight = snapshot.today.hours[2];
      final afternoon = snapshot.today.hours[14];
      expect(overnight.isDay, isFalse);
      expect(afternoon.isDay, isTrue);
      expect(overnight.condition, AuraCondition.clearNight);
    });

    test('snapshotFromDto dates astro times onto the day that carried '
        'them', () {
      final astro = snapshot.today.astro;
      expect(_raw(json, 'forecast.forecastday.0.astro.sunrise'), '06:10 AM');
      expect(_raw(json, 'forecast.forecastday.0.astro.sunset'), '07:52 PM');
      expect(astro.sunrise, DateTime(2026, 7, 26, 6, 10));
      expect(astro.sunset, DateTime(2026, 7, 26, 19, 52));
      expect(astro.moonrise, DateTime(2026, 7, 26, 18, 8));
      expect(astro.moonset, DateTime(2026, 7, 26, 3, 13));
    });

    test('snapshotFromDto maps the moon phase and illumination', () {
      expect(
        _raw(json, 'forecast.forecastday.0.astro.moon_phase'),
        'Waxing Gibbous',
      );
      expect(snapshot.today.astro.moonPhase, MoonPhase.waxingGibbous);
      expect(
        snapshot.today.astro.moonIlluminationPercent,
        _raw(json, 'forecast.forecastday.0.astro.moon_illumination'),
      );
    });

    test('snapshotFromDto maps all six pollutants and the EPA index', () {
      final air = snapshot.airQuality;
      expect(air, isNotNull);
      expect(air?.usEpaIndex, _raw(json, 'current.air_quality.us-epa-index'));
      expect(
        air?.concentrations[Pollutant.pm25],
        _raw(json, 'current.air_quality.pm2_5'),
      );
      expect(
        air?.concentrations[Pollutant.pm10],
        _raw(json, 'current.air_quality.pm10'),
      );
      expect(
        air?.concentrations[Pollutant.no2],
        _raw(json, 'current.air_quality.no2'),
      );
      expect(
        air?.concentrations[Pollutant.o3],
        _raw(json, 'current.air_quality.o3'),
      );
      expect(
        air?.concentrations[Pollutant.so2],
        _raw(json, 'current.air_quality.so2'),
      );
      expect(
        air?.concentrations[Pollutant.co],
        _raw(json, 'current.air_quality.co'),
      );
    });

    // No published index covers carbon monoxide at these concentrations. The
    // reading is still mapped; only the descriptor is absent.
    test('snapshotFromDto maps co without a band', () {
      expect(snapshot.airQuality?.concentrations[Pollutant.co], isNotNull);
      expect(snapshot.airQuality?.bandFor(Pollutant.co), isNull);
      expect(snapshot.airQuality?.bandFor(Pollutant.pm25), isNotNull);
    });

    test('snapshotFromDto reads an empty alert list as no alerts', () {
      expect(_raw(json, 'alerts.alert'), isEmpty);
      expect(snapshot.alerts, isEmpty);
      expect(snapshot.headlineAlert, isNull);
    });
  });

  group('snapshotFromDto over a response carrying real alerts', () {
    late Map<String, dynamic> json;
    late WeatherSnapshot snapshot;

    setUp(() {
      json = loadJsonObject('forecast_alerts_las_vegas');
      snapshot = snapshotFromDto(ForecastResponseDto.fromJson(json));
    });

    test('snapshotFromDto maps every active alert', () {
      expect(snapshot.alerts, hasLength(4));
      expect(snapshot.alerts.first.event, _raw(json, 'alerts.alert.0.event'));
      expect(
        snapshot.alerts.first.description,
        _raw(json, 'alerts.alert.0.desc'),
      );
      expect(
        snapshot.alerts.first.instruction,
        _raw(json, 'alerts.alert.0.instruction'),
      );
      expect(
        snapshot.alerts.first.category,
        _raw(json, 'alerts.alert.0.category'),
      );
    });

    test('snapshotFromDto reads the issuer severity grade', () {
      expect(_raw(json, 'alerts.alert.0.severity'), 'Moderate');
      expect(snapshot.alerts.first.severity, AlertSeverity.moderate);
      expect(_raw(json, 'alerts.alert.1.severity'), 'Severe');
      expect(snapshot.alerts[1].severity, AlertSeverity.severe);
    });

    test('snapshotFromDto splits areas on the semicolon', () {
      expect(
        _raw(json, 'alerts.alert.0.areas'),
        'San Bernardino County Mountains; Riverside County Mountains',
      );
      expect(snapshot.alerts.first.areas, <String>[
        'San Bernardino County Mountains',
        'Riverside County Mountains',
      ]);
    });

    // These two carry a zone offset, unlike every other time in the response.
    test('snapshotFromDto reads alert times as absolute instants', () {
      expect(
        _raw(json, 'alerts.alert.0.effective'),
        '2026-07-25T14:02:00-07:00',
      );
      expect(
        snapshot.alerts.first.effective,
        DateTime.utc(2026, 7, 25, 21, 2),
      );
      expect(snapshot.alerts.first.effective?.isUtc, isTrue);
      expect(snapshot.alerts.first.expires, isNotNull);
    });

    test('snapshotFromDto leaves the worst alert reachable as the '
        'headline', () {
      expect(snapshot.headlineAlert?.severity, AlertSeverity.severe);
    });
  });

  group('snapshotFromDto on readings the live captures do not contain', () {
    test('snapshotFromDto reads No sunrise as no sunrise', () {
      final json = loadJsonObject('forecast_cairo');
      final astro =
          _raw(json, 'forecast.forecastday.0.astro')! as Map<String, dynamic>;
      astro['sunrise'] = 'No sunrise';
      astro['sunset'] = 'No sunset';
      astro['moonrise'] = 'No moonrise';

      final day = snapshotFromDto(ForecastResponseDto.fromJson(json)).today;
      expect(day.astro.sunrise, isNull);
      expect(day.astro.sunset, isNull);
      expect(day.astro.moonrise, isNull);
      expect(day.astro.moonset, isNotNull);
      expect(
        daylightSpan(sunrise: day.astro.sunrise, sunset: day.astro.sunset),
        isNull,
      );
    });

    test('snapshotFromDto reads midnight and noon in the right half of '
        'the day', () {
      final json = loadJsonObject('forecast_cairo');
      final astro =
          _raw(json, 'forecast.forecastday.0.astro')! as Map<String, dynamic>;
      astro['sunrise'] = '12:00 AM';
      astro['sunset'] = '12:00 PM';

      final day = snapshotFromDto(ForecastResponseDto.fromJson(json)).today;
      expect(day.astro.sunrise, DateTime(2026, 7, 26));
      expect(day.astro.sunset, DateTime(2026, 7, 26, 12));
    });

    test('snapshotFromDto reads a 24-hour astro time without a meridiem', () {
      final json = loadJsonObject('forecast_cairo');
      final astro =
          _raw(json, 'forecast.forecastday.0.astro')! as Map<String, dynamic>;
      astro['sunset'] = '19:52';

      final day = snapshotFromDto(ForecastResponseDto.fromJson(json)).today;
      expect(day.astro.sunset, DateTime(2026, 7, 26, 19, 52));
    });

    test('snapshotFromDto reads an unparsable astro time as absent', () {
      final json = loadJsonObject('forecast_cairo');
      final astro =
          _raw(json, 'forecast.forecastday.0.astro')! as Map<String, dynamic>;
      astro['sunrise'] = '25:99 AM';

      final day = snapshotFromDto(ForecastResponseDto.fromJson(json)).today;
      expect(day.astro.sunrise, isNull);
    });

    test('snapshotFromDto reads a condition code it does not know as '
        'unknown', () {
      final json = loadJsonObject('forecast_cairo');
      final condition =
          _raw(json, 'current.condition')! as Map<String, dynamic>;
      condition['code'] = 1999;

      final snapshot = snapshotFromDto(ForecastResponseDto.fromJson(json));
      expect(snapshot.current.condition, AuraCondition.unknown);
      expect(snapshot.current.conditionText, condition['text']);
    });

    test('snapshotFromDto reads a response without air quality as none', () {
      final json = loadJsonObject('forecast_cairo');
      (json['current']! as Map<String, dynamic>).remove('air_quality');

      expect(
        snapshotFromDto(ForecastResponseDto.fromJson(json)).airQuality,
        isNull,
      );
    });

    test('snapshotFromDto reads a response without alerts as none', () {
      final json = loadJsonObject('forecast_cairo')..remove('alerts');

      expect(
        snapshotFromDto(ForecastResponseDto.fromJson(json)).alerts,
        isEmpty,
      );
    });

    test('snapshotFromDto throws when a timestamp changes shape', () {
      final json = loadJsonObject('forecast_cairo');
      (json['location']! as Map<String, dynamic>)['localtime'] = '26/07/2026';

      expect(
        () => snapshotFromDto(ForecastResponseDto.fromJson(json)),
        throwsFormatException,
      );
    });
  });

  group('citySuggestionFromDto', () {
    late List<dynamic> json;
    late List<CitySuggestion> suggestions;

    setUp(() {
      json = loadJsonArray('search_cair');
      suggestions = json
          .map((e) => SearchResultDto.fromJson(e as Map<String, dynamic>))
          .map(citySuggestionFromDto)
          .toList();
    });

    test('citySuggestionFromDto maps every match', () {
      expect(suggestions, hasLength(json.length));
      expect(suggestions.first.name, 'Cairo');
      expect(suggestions.first.region, 'Al Qahirah');
      expect(suggestions.first.country, 'Egypt');
    });

    // A name is ambiguous across countries; the coordinates are the place the
    // user actually picked, and `q` takes them directly.
    test('citySuggestionFromDto queries by coordinates', () {
      expect(suggestions.first.location.query, '30.05,31.25');
      expect(suggestions.first.location.displayName, 'Cairo');
      expect(suggestions.first.location.isCurrentLocation, isFalse);
    });

    test('citySuggestionFromDto keeps two matches distinguishable', () {
      expect(
        suggestions.first.location,
        isNot(equals(suggestions[1].location)),
      );
    });
  });
}
