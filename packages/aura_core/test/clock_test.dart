import 'package:aura_core/aura_core.dart';
import 'package:test/test.dart';

void main() {
  group('SystemClock', () {
    test('now returns the current instant', () {
      const clock = SystemClock();
      final before = DateTime.now();
      final reading = clock.now();
      final after = DateTime.now();

      expect(reading.isBefore(before), isFalse);
      expect(reading.isAfter(after), isFalse);
    });

    test('now moves forward between readings', () async {
      const clock = SystemClock();
      final first = clock.now();
      await Future<void>.delayed(const Duration(milliseconds: 2));
      expect(clock.now().isAfter(first), isTrue);
    });
  });

  group('FixedClock', () {
    final instant = DateTime.utc(2026, 7, 26, 14, 34);

    test('now returns the same instant on every reading', () {
      final clock = FixedClock(instant);
      expect(clock.now(), instant);
      expect(clock.now(), instant);
    });

    test('advance moves the clock forward by the given duration', () {
      final clock = FixedClock(instant)..advance(const Duration(hours: 2));
      expect(clock.now(), instant.add(const Duration(hours: 2)));
    });

    test('advance with a negative duration moves the clock back', () {
      final clock = FixedClock(instant)..advance(const Duration(minutes: -30));
      expect(clock.now(), DateTime.utc(2026, 7, 26, 14, 4));
    });

    test('advance accumulates across calls', () {
      final clock = FixedClock(instant)
        ..advance(const Duration(hours: 1))
        ..advance(const Duration(minutes: 15));
      expect(clock.now(), DateTime.utc(2026, 7, 26, 15, 49));
    });

    test('instant can be set directly', () {
      final clock = FixedClock(instant)..instant = DateTime.utc(2030);
      expect(clock.now(), DateTime.utc(2030));
    });
  });
}
