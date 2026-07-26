import 'package:aura_domain/aura_domain.dart';
import 'package:test/test.dart';

/// Every code WeatherAPI documents, with the sky it must produce by day.
const List<(int code, AuraCondition sky, String label)> _table =
    <(int, AuraCondition, String)>[
      (1000, AuraCondition.clearDay, 'Sunny'),
      (1003, AuraCondition.partlyCloudy, 'Partly cloudy'),
      (1006, AuraCondition.overcast, 'Cloudy'),
      (1009, AuraCondition.overcast, 'Overcast'),
      (1030, AuraCondition.fog, 'Mist'),
      (1063, AuraCondition.rain, 'Patchy rain possible'),
      (1066, AuraCondition.snow, 'Patchy snow possible'),
      (1069, AuraCondition.snow, 'Patchy sleet possible'),
      (1072, AuraCondition.snow, 'Patchy freezing drizzle possible'),
      (1087, AuraCondition.thunderstorm, 'Thundery outbreaks possible'),
      (1114, AuraCondition.snow, 'Blowing snow'),
      (1117, AuraCondition.snow, 'Blizzard'),
      (1135, AuraCondition.fog, 'Fog'),
      (1147, AuraCondition.fog, 'Freezing fog'),
      (1150, AuraCondition.rain, 'Patchy light drizzle'),
      (1153, AuraCondition.rain, 'Light drizzle'),
      (1168, AuraCondition.rain, 'Freezing drizzle'),
      (1171, AuraCondition.rain, 'Heavy freezing drizzle'),
      (1180, AuraCondition.rain, 'Patchy light rain'),
      (1183, AuraCondition.rain, 'Light rain'),
      (1186, AuraCondition.rain, 'Moderate rain at times'),
      (1189, AuraCondition.rain, 'Moderate rain'),
      (1192, AuraCondition.rain, 'Heavy rain at times'),
      (1195, AuraCondition.rain, 'Heavy rain'),
      (1198, AuraCondition.rain, 'Light freezing rain'),
      (1201, AuraCondition.rain, 'Moderate or heavy freezing rain'),
      (1204, AuraCondition.snow, 'Light sleet'),
      (1207, AuraCondition.snow, 'Moderate or heavy sleet'),
      (1210, AuraCondition.snow, 'Patchy light snow'),
      (1213, AuraCondition.snow, 'Light snow'),
      (1216, AuraCondition.snow, 'Patchy moderate snow'),
      (1219, AuraCondition.snow, 'Moderate snow'),
      (1222, AuraCondition.snow, 'Patchy heavy snow'),
      (1225, AuraCondition.snow, 'Heavy snow'),
      (1237, AuraCondition.snow, 'Ice pellets'),
      (1240, AuraCondition.rain, 'Light rain shower'),
      (1243, AuraCondition.rain, 'Moderate or heavy rain shower'),
      (1246, AuraCondition.rain, 'Torrential rain shower'),
      (1249, AuraCondition.snow, 'Light sleet showers'),
      (1252, AuraCondition.snow, 'Moderate or heavy sleet showers'),
      (1255, AuraCondition.snow, 'Light snow showers'),
      (1258, AuraCondition.snow, 'Moderate or heavy snow showers'),
      (1261, AuraCondition.snow, 'Light showers of ice pellets'),
      (1264, AuraCondition.snow, 'Moderate or heavy showers of ice pellets'),
      (1273, AuraCondition.thunderstorm, 'Patchy light rain with thunder'),
      (1276, AuraCondition.thunderstorm, 'Moderate or heavy rain with thunder'),
      (1279, AuraCondition.thunderstorm, 'Patchy light snow with thunder'),
      (1282, AuraCondition.thunderstorm, 'Moderate or heavy snow with thunder'),
    ];

void main() {
  group('every documented condition code', () {
    for (final (code, sky, label) in _table) {
      test('conditionFromCode maps $code ($label) to ${sky.name}', () {
        expect(conditionFromCode(code, isDay: true), sky);
      });
    }

    test('conditionFromCode covers every code in the published list', () {
      final covered = _table.map((row) => row.$1).toSet();
      expect(knownConditionCodes, covered);
    });

    test('conditionFromCode never returns unknown for a documented code', () {
      for (final (code, _, label) in _table) {
        expect(
          conditionFromCode(code, isDay: false),
          isNot(AuraCondition.unknown),
          reason: '$code ($label)',
        );
      }
    });
  });

  group('day and night', () {
    test('conditionFromCode splits clear by is_day', () {
      expect(conditionFromCode(1000, isDay: true), AuraCondition.clearDay);
      expect(conditionFromCode(1000, isDay: false), AuraCondition.clearNight);
    });

    test('conditionFromCode ignores is_day for every other code', () {
      for (final (code, sky, label) in _table) {
        if (code == 1000) continue;
        expect(conditionFromCode(code, isDay: false), sky, reason: label);
      }
    });
  });

  group('a code the table does not know', () {
    // WeatherAPI can add codes. The screen falls back to the brand sky and
    // still shows the service's own words, rather than crashing or guessing.
    test('conditionFromCode returns unknown instead of throwing', () {
      for (final code in const <int>[0, 999, 1001, 1300, 2000, -1]) {
        expect(
          conditionFromCode(code, isDay: true),
          AuraCondition.unknown,
          reason: '$code',
        );
      }
    });

    test('conditionFromCode returns unknown for both day and night', () {
      expect(conditionFromCode(1301, isDay: true), AuraCondition.unknown);
      expect(conditionFromCode(1301, isDay: false), AuraCondition.unknown);
    });
  });

  group('coverage of the sky set', () {
    test('every sky except unknown is reachable from some code', () {
      final reached = _table.map((row) => row.$2).toSet()
        ..add(conditionFromCode(1000, isDay: false));
      for (final sky in AuraCondition.values) {
        if (sky == AuraCondition.unknown) continue;
        expect(reached, contains(sky), reason: sky.name);
      }
    });
  });
}
