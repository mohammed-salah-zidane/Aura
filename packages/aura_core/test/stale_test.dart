import 'package:aura_core/aura_core.dart';
import 'package:test/test.dart';

final _fetchedAt = DateTime.utc(2026, 7, 26, 12);

void main() {
  group('age', () {
    test('age is the gap between the clock and fetchedAt', () {
      final clock = FixedClock(DateTime.utc(2026, 7, 26, 14));
      expect(
        Stale(35, fetchedAt: _fetchedAt).age(clock),
        const Duration(hours: 2),
      );
    });

    test('age is zero when the clock reads exactly fetchedAt', () {
      final clock = FixedClock(_fetchedAt);
      expect(Stale(1, fetchedAt: _fetchedAt).age(clock), Duration.zero);
    });

    test('age is negative when fetchedAt is ahead of the clock', () {
      final clock = FixedClock(DateTime.utc(2026, 7, 26, 11, 30));
      expect(
        Stale(1, fetchedAt: _fetchedAt).age(clock),
        const Duration(minutes: -30),
      );
    });

    test('age follows the clock as it advances', () {
      final clock = FixedClock(_fetchedAt);
      final stale = Stale(1, fetchedAt: _fetchedAt);
      expect(stale.age(clock), Duration.zero);
      clock.advance(const Duration(minutes: 90));
      expect(stale.age(clock), const Duration(minutes: 90));
    });

    test('age spans a UTC and a local fetchedAt by absolute time', () {
      final local = DateTime.utc(2026, 7, 26, 12).toLocal();
      final clock = FixedClock(DateTime.utc(2026, 7, 26, 13));
      expect(Stale(1, fetchedAt: local).age(clock), const Duration(hours: 1));
    });
  });

  group('equality', () {
    test('== is true for the same value and fetchedAt', () {
      expect(
        Stale('a', fetchedAt: _fetchedAt),
        Stale('a', fetchedAt: _fetchedAt),
      );
      expect(
        Stale('a', fetchedAt: _fetchedAt).hashCode,
        Stale('a', fetchedAt: _fetchedAt).hashCode,
      );
    });

    test('== is false for a different value', () {
      expect(
        Stale('a', fetchedAt: _fetchedAt),
        isNot(Stale('b', fetchedAt: _fetchedAt)),
      );
    });

    test('== is false for a different fetchedAt', () {
      expect(
        Stale('a', fetchedAt: _fetchedAt),
        isNot(Stale('a', fetchedAt: DateTime.utc(2026, 7, 26, 13))),
      );
    });

    test('== is false across different value types', () {
      expect(
        Stale<Object>('a', fetchedAt: _fetchedAt),
        isNot(Stale<String>('a', fetchedAt: _fetchedAt)),
      );
    });
  });

  test('toString names the value and the fetch time', () {
    expect(
      Stale(35, fetchedAt: _fetchedAt).toString(),
      'Stale(35, fetchedAt: 2026-07-26 12:00:00.000Z)',
    );
  });
}
