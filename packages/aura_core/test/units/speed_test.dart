import 'package:aura_core/aura_core.dart';
import 'package:test/test.dart';

/// Kilometres per hour paired with the miles per hour it must produce.
/// One mile is 1.609344 km by definition, so these are exact.
const List<(double kph, double mph)> _table = <(double, double)>[
  (0, 0),
  (1.609344, 1),
  (8, 4.9709695379), // Cairo overnight breeze
  (15, 9.3205678835),
  (16.09344, 10),
  (24, 14.9129086138), // London gusting front
  (30, 18.6411357671),
  (100, 62.1371192237),
];

void main() {
  group('kilometers per hour to miles per hour', () {
    for (final (kph, mph) in _table) {
      test('$kph km/h reads as $mph mph', () {
        expect(Speed.kilometersPerHour(kph).milesPerHour, closeTo(mph, 1e-9));
      });
    }
  });

  group('miles per hour to kilometers per hour', () {
    for (final (kph, mph) in _table) {
      test('$mph mph stores as $kph km/h', () {
        expect(Speed.milesPerHour(mph).kilometersPerHour, closeTo(kph, 1e-9));
      });
    }
  });

  group('round trip', () {
    test('km/h survives a trip through mph', () {
      for (final kph in const <double>[0, 0.5, 8, 15, 52, 130]) {
        final round = Speed.milesPerHour(
          Speed.kilometersPerHour(kph).milesPerHour,
        );
        expect(round.kilometersPerHour, closeTo(kph, 1e-9), reason: '$kph');
      }
    });
  });

  group('inUnit', () {
    test('inUnit returns km/h for SpeedUnit.kilometersPerHour', () {
      expect(
        const Speed.kilometersPerHour(15).inUnit(SpeedUnit.kilometersPerHour),
        15,
      );
    });

    test('inUnit returns mph for SpeedUnit.milesPerHour', () {
      expect(
        const Speed.kilometersPerHour(15).inUnit(SpeedUnit.milesPerHour),
        closeTo(9.3205678835, 1e-9),
      );
    });

    test('inUnit answers for every unit in the enum', () {
      const speed = Speed.kilometersPerHour(22);
      for (final unit in SpeedUnit.values) {
        expect(speed.inUnit(unit), isA<double>(), reason: '$unit');
      }
    });
  });

  group('equality', () {
    test('== is true for the same km/h value', () {
      expect(
        const Speed.kilometersPerHour(15),
        const Speed.kilometersPerHour(15),
      );
      expect(
        const Speed.kilometersPerHour(15).hashCode,
        const Speed.kilometersPerHour(15).hashCode,
      );
    });

    test('== is true across constructors for the same speed', () {
      expect(
        const Speed.kilometersPerHour(1.609344),
        const Speed.milesPerHour(1),
      );
    });

    test('== is false for a different speed', () {
      expect(
        const Speed.kilometersPerHour(15),
        isNot(const Speed.kilometersPerHour(16)),
      );
    });
  });

  test('toString names the canonical unit', () {
    expect(
      const Speed.kilometersPerHour(15).toString(),
      'Speed.kilometersPerHour(15.0)',
    );
  });
}
