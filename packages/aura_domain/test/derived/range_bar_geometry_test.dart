import 'package:aura_domain/aura_domain.dart';
import 'package:test/test.dart';

void main() {
  group('placing a day inside the period', () {
    // The three days the design shows: 24 to 37, 25 to 38, 24 to 36.
    // The period runs 24 to 38, so the span is 14 degrees.
    test('rangeBarGeometry places the first day', () {
      final bar = rangeBarGeometry(
        low: 24,
        high: 37,
        periodLow: 24,
        periodHigh: 38,
      );
      expect(bar.start, closeTo(0, 1e-9));
      expect(bar.extent, closeTo(13 / 14, 1e-9));
    });

    test('rangeBarGeometry places the warmest day at the end', () {
      final bar = rangeBarGeometry(
        low: 25,
        high: 38,
        periodLow: 24,
        periodHigh: 38,
      );
      expect(bar.start, closeTo(1 / 14, 1e-9));
      expect(bar.start + bar.extent, closeTo(1, 1e-9));
    });

    test('rangeBarGeometry fills the track for a day spanning the period', () {
      final bar = rangeBarGeometry(
        low: 24,
        high: 38,
        periodLow: 24,
        periodHigh: 38,
      );
      expect(bar.start, 0);
      expect(bar.extent, 1);
    });

    test('rangeBarGeometry handles a period crossing zero', () {
      final bar = rangeBarGeometry(
        low: -7,
        high: 0,
        periodLow: -7,
        periodHigh: 3,
      );
      expect(bar.start, closeTo(0, 1e-9));
      expect(bar.extent, closeTo(0.7, 1e-9));
    });
  });

  group('degenerate ranges', () {
    // A day whose high equals its low is a real reading, not an error.
    test('rangeBarGeometry gives a day with no spread zero extent', () {
      final bar = rangeBarGeometry(
        low: 30,
        high: 30,
        periodLow: 24,
        periodHigh: 38,
      );
      expect(bar.extent, 0);
      expect(bar.start, closeTo(6 / 14, 1e-9));
    });

    // Every day sharing one temperature leaves no range to position within.
    // A zero-width bar would read as missing data, so the track fills.
    test('rangeBarGeometry fills the track when the period has no spread', () {
      final bar = rangeBarGeometry(
        low: 30,
        high: 30,
        periodLow: 30,
        periodHigh: 30,
      );
      expect(bar.start, 0);
      expect(bar.extent, 1);
    });

    test('rangeBarGeometry fills the track for an inverted period', () {
      final bar = rangeBarGeometry(
        low: 30,
        high: 32,
        periodLow: 38,
        periodHigh: 24,
      );
      expect(bar.start, 0);
      expect(bar.extent, 1);
    });
  });

  group('the bar always fits the track', () {
    test('rangeBarGeometry clamps a day colder than the period', () {
      final bar = rangeBarGeometry(
        low: 10,
        high: 30,
        periodLow: 24,
        periodHigh: 38,
      );
      expect(bar.start, 0);
      expect(bar.start + bar.extent, lessThanOrEqualTo(1));
    });

    test('rangeBarGeometry clamps a day warmer than the period', () {
      final bar = rangeBarGeometry(
        low: 30,
        high: 60,
        periodLow: 24,
        periodHigh: 38,
      );
      expect(bar.start + bar.extent, closeTo(1, 1e-9));
    });

    test('rangeBarGeometry never leaves the track for any input', () {
      const values = <double>[-40, -7, 0, 24, 30, 38, 60];
      for (final low in values) {
        for (final high in values) {
          final bar = rangeBarGeometry(
            low: low,
            high: high,
            periodLow: -40,
            periodHigh: 60,
          );
          expect(bar.start, inInclusiveRange(0, 1), reason: '$low to $high');
          expect(bar.extent, inInclusiveRange(0, 1), reason: '$low to $high');
          expect(
            bar.start + bar.extent,
            lessThanOrEqualTo(1.000000001),
            reason: '$low to $high',
          );
        }
      }
    });
  });
}
