import 'package:aura_domain/aura_domain.dart';
import 'package:test/test.dart';

/// The readings the design shows on the air quality screen, with the band the
/// European index puts each one in.
const List<(Pollutant pollutant, double value, AirBand? band)> _designReadings =
    <(Pollutant, double, AirBand?)>[
      (Pollutant.pm25, 8.2, AirBand.good),
      (Pollutant.pm10, 14, AirBand.good),
      (Pollutant.o3, 68, AirBand.fair),
      (Pollutant.no2, 12, AirBand.good),
      (Pollutant.so2, 4, AirBand.good),
      (Pollutant.co, 210, null),
    ];

void main() {
  group('the US EPA index', () {
    test('epaCategory maps every index in range', () {
      expect(epaCategory(1), EpaCategory.good);
      expect(epaCategory(2), EpaCategory.moderate);
      expect(epaCategory(3), EpaCategory.unhealthyForSensitiveGroups);
      expect(epaCategory(4), EpaCategory.unhealthy);
      expect(epaCategory(5), EpaCategory.veryUnhealthy);
      expect(epaCategory(6), EpaCategory.hazardous);
    });

    test('epaCategory covers all six published levels', () {
      final covered = <EpaCategory>{
        for (var i = lowestEpaIndex; i <= highestEpaIndex; i++) ?epaCategory(i),
      };
      expect(covered, EpaCategory.values.toSet());
    });

    test('epaCategory returns null outside the range', () {
      for (final index in const <int>[0, -1, 7, 100]) {
        expect(epaCategory(index), isNull, reason: '$index');
      }
    });

    test('epaScalePosition spans the bar from index 1 to index 6', () {
      expect(epaScalePosition(1), 0);
      expect(epaScalePosition(6), 1);
    });

    test('epaScalePosition places the middle indexes evenly', () {
      expect(epaScalePosition(2), closeTo(0.2, 1e-9));
      expect(epaScalePosition(4), closeTo(0.6, 1e-9));
    });

    test('epaScalePosition clamps an out-of-range index to the track', () {
      expect(epaScalePosition(0), 0);
      expect(epaScalePosition(99), 1);
    });
  });

  group('the design readings', () {
    // Every number and word on the air quality screen, checked against the
    // scale. The design says Fair for ozone at 68, which is the European
    // index. The US EPA scale has no Fair band and would call the same
    // reading Good.
    for (final (pollutant, value, band) in _designReadings) {
      test('pollutantBand puts ${pollutant.name} $value in ${band?.name}', () {
        expect(pollutantBand(pollutant, value), band);
      });
    }
  });

  group('band boundaries', () {
    test('pollutantBand treats a value on a ceiling as inside its band', () {
      expect(pollutantBand(Pollutant.pm25, 10), AirBand.good);
      expect(pollutantBand(Pollutant.pm25, 20), AirBand.fair);
      expect(pollutantBand(Pollutant.pm25, 25), AirBand.moderate);
      expect(pollutantBand(Pollutant.pm25, 50), AirBand.poor);
      expect(pollutantBand(Pollutant.pm25, 75), AirBand.veryPoor);
    });

    test('pollutantBand moves up a band just past a ceiling', () {
      expect(pollutantBand(Pollutant.pm25, 10.01), AirBand.fair);
      expect(pollutantBand(Pollutant.pm10, 20.01), AirBand.fair);
      expect(pollutantBand(Pollutant.no2, 40.01), AirBand.fair);
      expect(pollutantBand(Pollutant.o3, 50.01), AirBand.fair);
      expect(pollutantBand(Pollutant.so2, 100.01), AirBand.fair);
    });

    test('pollutantBand leaves the top band open-ended', () {
      expect(pollutantBand(Pollutant.pm25, 900), AirBand.extremelyPoor);
      expect(pollutantBand(Pollutant.pm10, 5000), AirBand.extremelyPoor);
      expect(pollutantBand(Pollutant.o3, 1000), AirBand.extremelyPoor);
    });

    test('pollutantBand reads zero as the best band', () {
      for (final pollutant in Pollutant.values) {
        if (pollutant == Pollutant.co) continue;
        expect(
          pollutantBand(pollutant, 0),
          AirBand.good,
          reason: pollutant.name,
        );
      }
    });

    test('pollutantBand rejects a negative concentration', () {
      expect(pollutantBand(Pollutant.pm25, -1), isNull);
    });

    test('pollutantBand reaches every band for pm2.5', () {
      final reached = <AirBand>{
        for (final value in const <double>[5, 15, 22, 40, 60, 200])
          ?pollutantBand(Pollutant.pm25, value),
      };
      expect(reached, AirBand.values.toSet());
    });
  });

  group('carbon monoxide', () {
    // The European index does not cover CO, and no other published scale
    // bands it at these concentrations. Returning nothing keeps an invented
    // descriptor off the screen.
    test('pollutantBand has no band for carbon monoxide', () {
      for (final value in const <double>[0, 210, 5000, 50000]) {
        expect(pollutantBand(Pollutant.co, value), isNull, reason: '$value');
      }
    });
  });

  group('AirQuality', () {
    test('category reads the stored EPA index', () {
      const air = AirQuality(usEpaIndex: 1, concentrations: {});
      expect(air.category, EpaCategory.good);
    });

    test('bandFor reads a stored concentration', () {
      const air = AirQuality(
        usEpaIndex: 1,
        concentrations: {Pollutant.o3: 68},
      );
      expect(air.bandFor(Pollutant.o3), AirBand.fair);
    });

    test('bandFor returns null for a pollutant with no reading', () {
      const air = AirQuality(usEpaIndex: 1, concentrations: {});
      expect(air.bandFor(Pollutant.pm25), isNull);
    });
  });
}
