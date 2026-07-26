import 'package:aura_core/aura_core.dart';
import 'package:test/test.dart';

/// Millibars paired with the inches of mercury they must produce.
/// One inch of mercury is 3386.389 Pa by convention, so 33.86389 mb.
const List<(double millibars, double inchesOfMercury)> _table =
    <(double, double)>[
      (0, 0),
      (33.86389, 1),
      (338.6389, 10),
      (997, 29.4413902242), // Kuala Lumpur, storm low
      (1004, 29.6481000854),
      (1009, 29.7957499862),
      (1013, 29.9138699069), // Cairo, the reading on the pressure card
      (1016, 30.0024598473),
    ];

void main() {
  group('millibars to inches of mercury', () {
    for (final (millibars, inchesOfMercury) in _table) {
      test('$millibars mb reads as $inchesOfMercury inHg', () {
        expect(
          Pressure.millibars(millibars).inchesOfMercury,
          closeTo(inchesOfMercury, 1e-9),
        );
      });
    }
  });

  group('inches of mercury to millibars', () {
    for (final (millibars, inchesOfMercury) in _table) {
      test('$inchesOfMercury inHg stores as $millibars mb', () {
        expect(
          Pressure.inchesOfMercury(inchesOfMercury).millibars,
          closeTo(millibars, 1e-8),
        );
      });
    }
  });

  group('round trip', () {
    test('mb survives a trip through inHg', () {
      for (final millibars in const <double>[0, 870, 997, 1013, 1084]) {
        final round = Pressure.inchesOfMercury(
          Pressure.millibars(millibars).inchesOfMercury,
        );
        expect(round.millibars, closeTo(millibars, 1e-9), reason: '$millibars');
      }
    });
  });

  group('inUnit', () {
    test('inUnit returns millibars for PressureUnit.millibars', () {
      expect(
        const Pressure.millibars(1013).inUnit(PressureUnit.millibars),
        1013,
      );
    });

    test('inUnit returns inHg for PressureUnit.inchesOfMercury', () {
      expect(
        const Pressure.millibars(1013).inUnit(PressureUnit.inchesOfMercury),
        closeTo(29.9138699069, 1e-9),
      );
    });

    test('inUnit answers for every unit in the enum', () {
      const pressure = Pressure.millibars(1009);
      for (final unit in PressureUnit.values) {
        expect(pressure.inUnit(unit), isA<double>(), reason: '$unit');
      }
    });
  });

  group('equality', () {
    test('== is true for the same millibars value', () {
      expect(const Pressure.millibars(1013), const Pressure.millibars(1013));
      expect(
        const Pressure.millibars(1013).hashCode,
        const Pressure.millibars(1013).hashCode,
      );
    });

    test('== is true across constructors for the same pressure', () {
      expect(
        const Pressure.millibars(33.86389),
        const Pressure.inchesOfMercury(1),
      );
    });

    test('== is false for a different pressure', () {
      expect(
        const Pressure.millibars(1013),
        isNot(const Pressure.millibars(1012)),
      );
    });
  });

  test('toString names the canonical unit', () {
    expect(
      const Pressure.millibars(1013).toString(),
      'Pressure.millibars(1013.0)',
    );
  });
}
