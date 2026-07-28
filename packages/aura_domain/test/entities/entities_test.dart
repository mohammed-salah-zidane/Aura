import 'package:aura_core/aura_core.dart';
import 'package:aura_domain/aura_domain.dart';
import 'package:test/test.dart';

WeatherAlert _alert(String event, AlertSeverity severity) => WeatherAlert(
  event: event,
  headline: '$event issued by the met service',
  severity: severity,
  category: 'Met',
  areas: const <String>['Cairo'],
  description: 'desc',
  instruction: 'instruction',
);

HourlyPoint _hour(DateTime time) => HourlyPoint(
  time: time,
  temperature: const Temperature.celsius(20),
  condition: AuraCondition.clearDay,
  conditionText: 'Sunny',
  isDay: true,
  chanceOfRainPercent: 0,
);

CurrentConditions _current({double uv = 9}) => CurrentConditions(
  observedAt: DateTime.utc(2026, 7, 26, 13, 30),
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
  uvIndex: uv,
  cloudPercent: 0,
);

ForecastDay _day(DateTime date, List<HourlyPoint> hours) => ForecastDay(
  date: date,
  low: const Temperature.celsius(24),
  high: const Temperature.celsius(37),
  condition: AuraCondition.clearDay,
  conditionText: 'Sunny',
  chanceOfRainPercent: 10,
  uvIndex: 9,
  astro: const AstroInfo(
    moonPhase: MoonPhase.waxingCrescent,
    moonIlluminationPercent: 34,
  ),
  hours: hours,
);

WeatherSnapshot _snapshot({
  List<WeatherAlert> alerts = const <WeatherAlert>[],
  List<ForecastDay>? days,
}) => WeatherSnapshot(
  placeName: 'Cairo',
  region: 'Al Qahirah',
  country: 'Egypt',
  localTime: DateTime.utc(2026, 7, 26, 14, 34),
  current: _current(),
  days: days ?? <ForecastDay>[_day(DateTime.utc(2026, 7, 26), <HourlyPoint>[])],
  alerts: alerts,
);

void main() {
  group('LocationRef', () {
    test('== is true for the same query and name', () {
      expect(
        const LocationRef(query: 'Cairo'),
        const LocationRef(query: 'Cairo'),
      );
      expect(
        const LocationRef(query: 'Cairo').hashCode,
        const LocationRef(query: 'Cairo').hashCode,
      );
    });

    test('== is false for a different query', () {
      expect(
        const LocationRef(query: 'Cairo'),
        isNot(const LocationRef(query: 'Cairns')),
      );
    });

    test('== treats the same query as the same place whatever its label', () {
      // The same city arrives named from a search suggestion and bare from
      // the saved list; the pager and the feed cache key off this equality.
      expect(
        const LocationRef(query: 'Cairo'),
        const LocationRef(query: 'Cairo', displayName: 'Home'),
      );
    });

    test('currentByIp asks the service to resolve the device', () {
      const ref = LocationRef.currentByIp();
      expect(ref.query, 'auto:ip');
      expect(ref.isCurrentLocation, isTrue);
    });

    test('isCurrentLocation is false for a named place', () {
      expect(const LocationRef(query: 'Cairo').isCurrentLocation, isFalse);
    });

    test('coordinates builds the lat,lon query the service expects', () {
      final ref = LocationRef.coordinates(latitude: 30.05, longitude: 31.25);
      expect(ref.query, '30.05,31.25');
    });

    test('coordinates keeps a negative longitude', () {
      final ref = LocationRef.coordinates(latitude: 36.175, longitude: -115.14);
      expect(ref.query, '36.175,-115.14');
    });
  });

  group('UnitPreferences', () {
    test('the defaults are metric', () {
      const preferences = UnitPreferences();
      expect(preferences.temperature, TemperatureUnit.celsius);
      expect(preferences.speed, SpeedUnit.kilometersPerHour);
      expect(preferences.precipitation, PrecipitationUnit.millimeters);
    });

    test('copyWith replaces only what it is given', () {
      const preferences = UnitPreferences();
      final changed = preferences.copyWith(
        temperature: TemperatureUnit.fahrenheit,
      );
      expect(changed.temperature, TemperatureUnit.fahrenheit);
      expect(changed.speed, SpeedUnit.kilometersPerHour);
    });

    test('== compares every unit', () {
      expect(const UnitPreferences(), const UnitPreferences());
      expect(
        const UnitPreferences(),
        isNot(const UnitPreferences(speed: SpeedUnit.milesPerHour)),
      );
    });
  });

  group('SavedCity', () {
    final city = SavedCity(
      location: const LocationRef(query: 'Cairo'),
      name: 'Cairo',
      country: 'Egypt',
      addedAt: DateTime.utc(2026),
    );

    // Identity is the place, so re-adding a city under a different label or
    // at a different time is still the same city.
    test('== is decided by the location alone', () {
      final again = SavedCity(
        location: const LocationRef(query: 'Cairo'),
        name: 'Cairo, Egypt',
        country: 'Egypt',
        addedAt: DateTime.utc(2030),
      );
      expect(city, again);
      expect(<SavedCity>{city, again}, hasLength(1));
    });

    test('== is false for a different place', () {
      final other = SavedCity(
        location: const LocationRef(query: 'London'),
        name: 'London',
        country: 'United Kingdom',
        addedAt: DateTime.utc(2026),
      );
      expect(city, isNot(other));
    });
  });

  group('CurrentConditions', () {
    test('uvSeverity bands the stored index', () {
      expect(_current().uvSeverity, UvBand.veryHigh);
      expect(_current(uv: 0).uvSeverity, UvBand.none);
    });

    test('pressure carries the value the service published in inHg', () {
      expect(_current().pressureInchesOfMercury, 29.92);
    });
  });

  group('WeatherSnapshot', () {
    test('today is the first forecast day', () {
      final snapshot = _snapshot();
      expect(snapshot.today.date, DateTime.utc(2026, 7, 26));
    });

    test('headlineAlert is null when nothing is active', () {
      expect(_snapshot().headlineAlert, isNull);
    });

    test('headlineAlert is the only alert when there is one', () {
      final snapshot = _snapshot(
        alerts: <WeatherAlert>[_alert('Heat Advisory', AlertSeverity.moderate)],
      );
      expect(snapshot.headlineAlert?.event, 'Heat Advisory');
    });

    // The design has room for one banner, so several alerts show the worst.
    test('headlineAlert is the most severe of several', () {
      final snapshot = _snapshot(
        alerts: <WeatherAlert>[
          _alert('Heat Advisory', AlertSeverity.moderate),
          _alert('Flood Warning', AlertSeverity.extreme),
          _alert('Wind Advisory', AlertSeverity.minor),
        ],
      );
      expect(snapshot.headlineAlert?.event, 'Flood Warning');
    });

    test('headlineAlert prefers a graded alert over an ungraded one', () {
      final snapshot = _snapshot(
        alerts: <WeatherAlert>[
          _alert('Odd Notice', AlertSeverity.unknown),
          _alert('Heat Advisory', AlertSeverity.moderate),
        ],
      );
      expect(snapshot.headlineAlert?.event, 'Heat Advisory');
    });

    test('headlineAlert still answers when every alert is ungraded', () {
      final snapshot = _snapshot(
        alerts: <WeatherAlert>[_alert('Odd Notice', AlertSeverity.unknown)],
      );
      expect(snapshot.headlineAlert?.event, 'Odd Notice');
    });
  });

  group('an hour list crossing midnight', () {
    test('hours stay in order across the day boundary', () {
      final hours = <HourlyPoint>[
        _hour(DateTime.utc(2026, 7, 26, 22)),
        _hour(DateTime.utc(2026, 7, 26, 23)),
        _hour(DateTime.utc(2026, 7, 27)),
        _hour(DateTime.utc(2026, 7, 27, 1)),
      ];
      final day = _day(DateTime.utc(2026, 7, 26), hours);

      for (var i = 1; i < day.hours.length; i++) {
        expect(
          day.hours[i].time.isAfter(day.hours[i - 1].time),
          isTrue,
          reason: 'hour $i went backwards',
        );
      }
    });

    test('a day carries its hours even when they span two dates', () {
      final hours = <HourlyPoint>[
        _hour(DateTime.utc(2026, 7, 26, 23)),
        _hour(DateTime.utc(2026, 7, 27)),
      ];
      expect(_day(DateTime.utc(2026, 7, 26), hours).hours, hasLength(2));
    });
  });

  group('alert severity', () {
    test('alertSeverityFromName reads every published grade', () {
      expect(alertSeverityFromName('Minor'), AlertSeverity.minor);
      expect(alertSeverityFromName('Moderate'), AlertSeverity.moderate);
      expect(alertSeverityFromName('Severe'), AlertSeverity.severe);
      expect(alertSeverityFromName('Extreme'), AlertSeverity.extreme);
    });

    test('alertSeverityFromName ignores case and space', () {
      expect(alertSeverityFromName('  severe '), AlertSeverity.severe);
    });

    test('alertSeverityFromName returns unknown for anything else', () {
      expect(alertSeverityFromName('Catastrophic'), AlertSeverity.unknown);
      expect(alertSeverityFromName(''), AlertSeverity.unknown);
    });
  });
}
