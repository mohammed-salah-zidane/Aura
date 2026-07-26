import 'package:aura_core/aura_core.dart';
import 'package:test/test.dart';

/// Celsius paired with the Fahrenheit it must produce.
const List<(double celsius, double fahrenheit)> _table = <(double, double)>[
  (-273.15, -459.67), // absolute zero
  (-40, -40), // the one point where the two scales meet
  (-17.5, 0.5),
  (-7, 19.4), // Zermatt overnight low
  (-2, 28.4),
  (-0.5, 31.1),
  (0, 32),
  (13, 55.4),
  (24, 75.2),
  (35, 95),
  (37, 98.6),
  (100, 212),
];

void main() {
  group('celsius to fahrenheit', () {
    for (final (celsius, fahrenheit) in _table) {
      test('$celsius C reads as $fahrenheit F', () {
        expect(
          Temperature.celsius(celsius).fahrenheit,
          closeTo(fahrenheit, 1e-9),
        );
      });
    }
  });

  group('fahrenheit to celsius', () {
    for (final (celsius, fahrenheit) in _table) {
      test('$fahrenheit F stores as $celsius C', () {
        expect(
          Temperature.fahrenheit(fahrenheit).celsius,
          closeTo(celsius, 1e-9),
        );
      });
    }
  });

  group('the -40 crossover', () {
    test('celsius -40 reads as fahrenheit -40', () {
      expect(const Temperature.celsius(-40).fahrenheit, -40);
    });

    test('fahrenheit -40 stores as celsius -40', () {
      expect(const Temperature.fahrenheit(-40).celsius, -40);
    });

    test('the two constructors agree at -40', () {
      expect(const Temperature.celsius(-40), const Temperature.fahrenheit(-40));
    });

    test('-40 is the only point where the scales agree', () {
      for (final celsius in const <double>[-41, -39, -1, 0, 1, 40]) {
        expect(
          Temperature.celsius(celsius).fahrenheit,
          isNot(closeTo(celsius, 1e-9)),
          reason: '$celsius C',
        );
      }
    });
  });

  group('round trip', () {
    test('celsius survives a trip through fahrenheit', () {
      for (final celsius in const <double>[
        -273.15,
        -40,
        -18.3,
        -7,
        -0.1,
        0,
        0.1,
        21.5,
        35,
        56.7,
      ]) {
        final round = Temperature.fahrenheit(
          Temperature.celsius(celsius).fahrenheit,
        );
        expect(round.celsius, closeTo(celsius, 1e-9), reason: '$celsius C');
      }
    });
  });

  group('inUnit', () {
    test('inUnit returns celsius for TemperatureUnit.celsius', () {
      expect(const Temperature.celsius(35).inUnit(TemperatureUnit.celsius), 35);
    });

    test('inUnit returns fahrenheit for TemperatureUnit.fahrenheit', () {
      expect(
        const Temperature.celsius(35).inUnit(TemperatureUnit.fahrenheit),
        closeTo(95, 1e-9),
      );
    });

    test('inUnit answers for every unit in the enum', () {
      const temperature = Temperature.celsius(-5);
      for (final unit in TemperatureUnit.values) {
        expect(temperature.inUnit(unit), isA<double>(), reason: '$unit');
      }
    });
  });

  group('equality', () {
    test('== is true for the same celsius value', () {
      expect(const Temperature.celsius(35), const Temperature.celsius(35));
      expect(
        const Temperature.celsius(35).hashCode,
        const Temperature.celsius(35).hashCode,
      );
    });

    test('== is true across constructors for the same temperature', () {
      expect(const Temperature.celsius(100), const Temperature.fahrenheit(212));
    });

    test('== is false for a different temperature', () {
      expect(
        const Temperature.celsius(35),
        isNot(const Temperature.celsius(34)),
      );
    });
  });

  test('toString names the canonical unit', () {
    expect(
      const Temperature.celsius(-2).toString(),
      'Temperature.celsius(-2.0)',
    );
  });
}
