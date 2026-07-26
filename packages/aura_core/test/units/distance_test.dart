import 'package:aura_core/aura_core.dart';
import 'package:test/test.dart';

/// Kilometres paired with the miles they must produce.
/// One mile is 1.609344 km by definition, so these are exact.
const List<(double kilometers, double miles)> _table = <(double, double)>[
  (0, 0),
  (0.8, 0.4970969538), // San Francisco fog
  (1.609344, 1),
  (2, 1.2427423845),
  (10, 6.2137119224),
  (16, 9.9419390758),
  (16.09344, 10),
  (18, 11.1846814603),
];

void main() {
  group('kilometers to miles', () {
    for (final (kilometers, miles) in _table) {
      test('$kilometers km reads as $miles mi', () {
        expect(Distance.kilometers(kilometers).miles, closeTo(miles, 1e-9));
      });
    }
  });

  group('miles to kilometers', () {
    for (final (kilometers, miles) in _table) {
      test('$miles mi stores as $kilometers km', () {
        expect(Distance.miles(miles).kilometers, closeTo(kilometers, 1e-9));
      });
    }
  });

  group('round trip', () {
    test('km survives a trip through miles', () {
      for (final kilometers in const <double>[0, 0.4, 0.8, 6, 11, 18, 160]) {
        final round = Distance.miles(Distance.kilometers(kilometers).miles);
        expect(
          round.kilometers,
          closeTo(kilometers, 1e-9),
          reason: '$kilometers',
        );
      }
    });
  });

  group('inUnit', () {
    test('inUnit returns kilometers for DistanceUnit.kilometers', () {
      expect(const Distance.kilometers(10).inUnit(DistanceUnit.kilometers), 10);
    });

    test('inUnit returns miles for DistanceUnit.miles', () {
      expect(
        const Distance.kilometers(10).inUnit(DistanceUnit.miles),
        closeTo(6.2137119224, 1e-9),
      );
    });

    test('inUnit answers for every unit in the enum', () {
      const distance = Distance.kilometers(0.8);
      for (final unit in DistanceUnit.values) {
        expect(distance.inUnit(unit), isA<double>(), reason: '$unit');
      }
    });
  });

  group('equality', () {
    test('== is true for the same kilometers value', () {
      expect(const Distance.kilometers(10), const Distance.kilometers(10));
      expect(
        const Distance.kilometers(10).hashCode,
        const Distance.kilometers(10).hashCode,
      );
    });

    test('== is true across constructors for the same distance', () {
      expect(const Distance.kilometers(1.609344), const Distance.miles(1));
    });

    test('== is false for a different distance', () {
      expect(
        const Distance.kilometers(10),
        isNot(const Distance.kilometers(11)),
      );
    });
  });

  test('toString names the canonical unit', () {
    expect(
      const Distance.kilometers(0.8).toString(),
      'Distance.kilometers(0.8)',
    );
  });
}
