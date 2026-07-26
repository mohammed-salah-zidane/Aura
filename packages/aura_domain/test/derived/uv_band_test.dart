import 'package:aura_domain/aura_domain.dart';
import 'package:test/test.dart';

/// A reading paired with the band the WHO scale puts it in.
const List<(double uv, UvBand band)> _table = <(double, UvBand)>[
  (0, UvBand.none),
  (0.4, UvBand.none),
  (1, UvBand.low),
  (2, UvBand.low),
  (2.9, UvBand.low),
  (3, UvBand.moderate),
  (4, UvBand.moderate), // Alexandria, overcast
  (5, UvBand.moderate),
  (5.9, UvBand.moderate),
  (6, UvBand.high),
  (7, UvBand.high), // Cairo, partly cloudy
  (7.9, UvBand.high),
  (8, UvBand.veryHigh),
  (9, UvBand.veryHigh), // Cairo, mostly sunny
  (10, UvBand.veryHigh),
  (10.7, UvBand.veryHigh), // the value the live capture returned
  (11, UvBand.extreme),
  (14, UvBand.extreme),
];

void main() {
  group('the WHO bands', () {
    for (final (uv, band) in _table) {
      test('uvBand puts $uv in ${band.name}', () {
        expect(uvBand(uv), band);
      });
    }
  });

  group('band boundaries', () {
    test('uvBand changes band exactly at each published floor', () {
      expect(uvBand(0.999), UvBand.none);
      expect(uvBand(1), UvBand.low);
      expect(uvBand(2.999), UvBand.low);
      expect(uvBand(3), UvBand.moderate);
      expect(uvBand(5.999), UvBand.moderate);
      expect(uvBand(6), UvBand.high);
      expect(uvBand(7.999), UvBand.high);
      expect(uvBand(8), UvBand.veryHigh);
      expect(uvBand(10.999), UvBand.veryHigh);
      expect(uvBand(11), UvBand.extreme);
    });

    // The design shows UV INDEX 0 / None on the clear night screen. The
    // published scale starts at 1, so zero gets its own band.
    test('uvBand reads a night-time zero as none', () {
      expect(uvBand(0), UvBand.none);
    });

    test('uvBand treats a negative reading as none rather than throwing', () {
      expect(uvBand(-1), UvBand.none);
    });
  });

  group('scale position', () {
    test('uvScalePosition puts zero at the start of the bar', () {
      expect(uvScalePosition(0), 0);
    });

    test('uvScalePosition puts the extreme floor at the end', () {
      expect(uvScalePosition(11), 1);
    });

    test('uvScalePosition pins anything past extreme to the end', () {
      expect(uvScalePosition(14), 1);
      expect(uvScalePosition(30), 1);
    });

    test('uvScalePosition places a mid reading proportionally', () {
      expect(uvScalePosition(5.5), closeTo(0.5, 1e-9));
    });

    test('uvScalePosition never leaves the track', () {
      for (final uv in const <double>[-5, 0, 1, 7, 10.9, 11, 25]) {
        expect(uvScalePosition(uv), inInclusiveRange(0, 1), reason: '$uv');
      }
    });
  });
}
