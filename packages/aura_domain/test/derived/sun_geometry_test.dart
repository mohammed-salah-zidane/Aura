import 'package:aura_domain/aura_domain.dart';
import 'package:test/test.dart';

final _sunrise = DateTime.utc(2026, 7, 26, 5, 14);
final _sunset = DateTime.utc(2026, 7, 26, 19, 2);

void main() {
  group('daylightSpan', () {
    // The design shows 13h 48m for a 05:14 sunrise and a 19:02 sunset.
    test('daylightSpan is the gap between sunrise and sunset', () {
      expect(
        daylightSpan(sunrise: _sunrise, sunset: _sunset),
        const Duration(hours: 13, minutes: 48),
      );
    });

    test('daylightSpan is zero when they fall at the same instant', () {
      expect(
        daylightSpan(sunrise: _sunrise, sunset: _sunrise),
        Duration.zero,
      );
    });

    // A polar day answers "No sunset", which reaches the domain as null.
    test('daylightSpan is null on a day with no sunset', () {
      expect(daylightSpan(sunrise: _sunrise), isNull);
    });

    test('daylightSpan is null on a day with no sunrise', () {
      expect(daylightSpan(sunset: _sunset), isNull);
    });

    test('daylightSpan is null when neither is known', () {
      expect(daylightSpan(), isNull);
    });

    test('daylightSpan is null when sunset precedes sunrise', () {
      expect(daylightSpan(sunrise: _sunset, sunset: _sunrise), isNull);
    });
  });

  group('sunArcPosition', () {
    test('sunArcPosition is 0 at sunrise', () {
      expect(
        sunArcPosition(now: _sunrise, sunrise: _sunrise, sunset: _sunset),
        0,
      );
    });

    test('sunArcPosition is 1 at sunset', () {
      expect(
        sunArcPosition(now: _sunset, sunrise: _sunrise, sunset: _sunset),
        1,
      );
    });

    test('sunArcPosition is a half at solar noon', () {
      final midpoint = _sunrise.add(
        Duration(
          microseconds: _sunset.difference(_sunrise).inMicroseconds ~/ 2,
        ),
      );
      expect(
        sunArcPosition(now: midpoint, sunrise: _sunrise, sunset: _sunset),
        closeTo(0.5, 1e-9),
      );
    });

    test('sunArcPosition clamps to 0 before sunrise', () {
      expect(
        sunArcPosition(
          now: _sunrise.subtract(const Duration(hours: 3)),
          sunrise: _sunrise,
          sunset: _sunset,
        ),
        0,
      );
    });

    test('sunArcPosition clamps to 1 after sunset', () {
      expect(
        sunArcPosition(
          now: _sunset.add(const Duration(hours: 4)),
          sunrise: _sunrise,
          sunset: _sunset,
        ),
        1,
      );
    });

    test('sunArcPosition never leaves the arc', () {
      for (final offset in const <int>[-600, -1, 0, 300, 828, 829, 2000]) {
        final position = sunArcPosition(
          now: _sunrise.add(Duration(minutes: offset)),
          sunrise: _sunrise,
          sunset: _sunset,
        );
        expect(position, isNotNull);
        expect(position, inInclusiveRange(0, 1), reason: '$offset minutes');
      }
    });

    test('sunArcPosition is null on a day with no sunset', () {
      expect(
        sunArcPosition(now: _sunrise, sunrise: _sunrise),
        isNull,
      );
    });

    test('sunArcPosition is null when sunrise and sunset coincide', () {
      expect(
        sunArcPosition(now: _sunrise, sunrise: _sunrise, sunset: _sunrise),
        isNull,
      );
    });

    test('sunArcPosition is null when sunset precedes sunrise', () {
      expect(
        sunArcPosition(now: _sunrise, sunrise: _sunset, sunset: _sunrise),
        isNull,
      );
    });
  });
}
