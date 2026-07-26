import 'package:aura_core/aura_core.dart';
import 'package:aura_domain/aura_domain.dart';
import 'package:test/test.dart';

ForecastDay _day(DateTime date) => ForecastDay(
  date: date,
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
  hours: <HourlyPoint>[
    for (var hour = 0; hour < 24; hour++)
      HourlyPoint(
        time: DateTime(date.year, date.month, date.day, hour),
        temperature: const Temperature.celsius(30),
        condition: AuraCondition.clearDay,
        conditionText: 'Sunny',
        isDay: hour > 5 && hour < 19,
        chanceOfRainPercent: 0,
      ),
  ],
);

final List<ForecastDay> _threeDays = <ForecastDay>[
  _day(DateTime(2026, 7, 26)),
  _day(DateTime(2026, 7, 27)),
  _day(DateTime(2026, 7, 28)),
];

void main() {
  group('upcomingHours', () {
    test('upcomingHours starts at the hour the reading was taken in', () {
      final window = upcomingHours(
        _threeDays,
        from: DateTime(2026, 7, 26, 14, 34),
        count: 3,
      );

      expect(
        window.map((hour) => hour.time.hour),
        <int>[14, 15, 16],
      );
    });

    test('upcomingHours runs past midnight into the next day', () {
      final window = upcomingHours(
        _threeDays,
        from: DateTime(2026, 7, 26, 22),
        count: 4,
      );

      expect(window.map((hour) => hour.time.day), <int>[26, 26, 27, 27]);
      expect(window.map((hour) => hour.time.hour), <int>[22, 23, 0, 1]);
    });

    test('upcomingHours asks for a day and gets one', () {
      expect(
        upcomingHours(_threeDays, from: DateTime(2026, 7, 26, 14)),
        hasLength(24),
      );
    });

    test('upcomingHours returns what is left when the forecast runs out', () {
      final window = upcomingHours(
        _threeDays,
        from: DateTime(2026, 7, 28, 22),
      );
      expect(window, hasLength(2));
    });

    test('upcomingHours returns nothing once every hour is behind', () {
      expect(
        upcomingHours(_threeDays, from: DateTime(2026, 7, 29)),
        isEmpty,
      );
    });

    test('upcomingHours returns nothing when there are no days', () {
      expect(
        upcomingHours(const <ForecastDay>[], from: DateTime(2026, 7, 26)),
        isEmpty,
      );
    });
  });

  group('isSunsetHour', () {
    test('isSunsetHour is true for the hour the sun goes down in', () {
      expect(
        isSunsetHour(DateTime(2026, 7, 26, 19), DateTime(2026, 7, 26, 19, 2)),
        isTrue,
      );
    });

    test('isSunsetHour is false for the hour before and the hour after', () {
      final sunset = DateTime(2026, 7, 26, 19, 2);
      expect(isSunsetHour(DateTime(2026, 7, 26, 18), sunset), isFalse);
      expect(isSunsetHour(DateTime(2026, 7, 26, 20), sunset), isFalse);
    });

    test('isSunsetHour is false for the same hour on another day', () {
      expect(
        isSunsetHour(DateTime(2026, 7, 27, 19), DateTime(2026, 7, 26, 19, 2)),
        isFalse,
      );
    });

    test('isSunsetHour is false where there is no sunset at all', () {
      expect(isSunsetHour(DateTime(2026, 7, 26, 19), null), isFalse);
    });
  });
}
