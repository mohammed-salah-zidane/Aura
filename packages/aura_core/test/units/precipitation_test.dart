import 'package:aura_core/aura_core.dart';
import 'package:test/test.dart';

/// Millimetres paired with the inches they must produce.
/// One inch is 25.4 mm by definition, so these are exact.
const List<(double millimeters, double inches)> _table = <(double, double)>[
  (0, 0),
  (0.254, 0.01),
  (2.54, 0.1),
  (8, 0.3149606299),
  (25.4, 1),
  (50, 1.968503937),
  (80, 3.1496062992),
];

void main() {
  group('millimeters to inches', () {
    for (final (millimeters, inches) in _table) {
      test('$millimeters mm reads as $inches in', () {
        expect(
          Precipitation.millimeters(millimeters).inches,
          closeTo(inches, 1e-9),
        );
      });
    }
  });

  group('inches to millimeters', () {
    for (final (millimeters, inches) in _table) {
      test('$inches in stores as $millimeters mm', () {
        expect(
          Precipitation.inches(inches).millimeters,
          closeTo(millimeters, 1e-9),
        );
      });
    }
  });

  group('round trip', () {
    test('mm survives a trip through inches', () {
      for (final millimeters in const <double>[0, 0.1, 2.5, 8, 25.4, 120]) {
        final round = Precipitation.inches(
          Precipitation.millimeters(millimeters).inches,
        );
        expect(
          round.millimeters,
          closeTo(millimeters, 1e-9),
          reason: '$millimeters',
        );
      }
    });
  });

  group('inUnit', () {
    test('inUnit returns millimeters for PrecipitationUnit.millimeters', () {
      expect(
        const Precipitation.millimeters(
          8,
        ).inUnit(PrecipitationUnit.millimeters),
        8,
      );
    });

    test('inUnit returns inches for PrecipitationUnit.inches', () {
      expect(
        const Precipitation.millimeters(8).inUnit(PrecipitationUnit.inches),
        closeTo(0.3149606299, 1e-9),
      );
    });

    test('inUnit answers for every unit in the enum', () {
      const precipitation = Precipitation.millimeters(3.2);
      for (final unit in PrecipitationUnit.values) {
        expect(precipitation.inUnit(unit), isA<double>(), reason: '$unit');
      }
    });
  });

  group('equality', () {
    test('== is true for the same millimeters value', () {
      expect(
        const Precipitation.millimeters(8),
        const Precipitation.millimeters(8),
      );
      expect(
        const Precipitation.millimeters(8).hashCode,
        const Precipitation.millimeters(8).hashCode,
      );
    });

    test('== is true across constructors for the same depth', () {
      expect(
        const Precipitation.millimeters(25.4),
        const Precipitation.inches(1),
      );
    });

    test('== is false for a different depth', () {
      expect(
        const Precipitation.millimeters(8),
        isNot(const Precipitation.millimeters(9)),
      );
    });
  });

  test('toString names the canonical unit', () {
    expect(
      const Precipitation.millimeters(8).toString(),
      'Precipitation.millimeters(8.0)',
    );
  });
}
