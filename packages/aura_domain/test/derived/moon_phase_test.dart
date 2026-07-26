import 'package:aura_domain/aura_domain.dart';
import 'package:test/test.dart';

/// The eight names WeatherAPI sends in astro.moon_phase.
const List<(String name, MoonPhase phase)> _table = <(String, MoonPhase)>[
  ('New Moon', MoonPhase.newMoon),
  ('Waxing Crescent', MoonPhase.waxingCrescent),
  ('First Quarter', MoonPhase.firstQuarter),
  ('Waxing Gibbous', MoonPhase.waxingGibbous),
  ('Full Moon', MoonPhase.fullMoon),
  ('Waning Gibbous', MoonPhase.waningGibbous),
  ('Last Quarter', MoonPhase.lastQuarter),
  ('Waning Crescent', MoonPhase.waningCrescent),
];

void main() {
  group('every phase name', () {
    for (final (name, phase) in _table) {
      test('moonPhaseFromName reads "$name" as ${phase.name}', () {
        expect(moonPhaseFromName(name), phase);
      });
    }

    test('moonPhaseFromName covers every phase except unknown', () {
      final covered = _table.map((row) => row.$2).toSet();
      final expected = MoonPhase.values.toSet()..remove(MoonPhase.unknown);
      expect(covered, expected);
    });
  });

  group('tolerating how the value is written', () {
    test('moonPhaseFromName ignores case', () {
      expect(moonPhaseFromName('WAXING GIBBOUS'), MoonPhase.waxingGibbous);
      expect(moonPhaseFromName('waxing gibbous'), MoonPhase.waxingGibbous);
    });

    test('moonPhaseFromName ignores surrounding space', () {
      expect(moonPhaseFromName('  Full Moon '), MoonPhase.fullMoon);
    });

    test('moonPhaseFromName returns unknown for a name it does not know', () {
      expect(moonPhaseFromName('Blue Moon'), MoonPhase.unknown);
      expect(moonPhaseFromName(''), MoonPhase.unknown);
    });
  });

  group('waxing', () {
    test('isWaxing is true while the lit fraction grows', () {
      expect(MoonPhase.waxingCrescent.isWaxing, isTrue);
      expect(MoonPhase.firstQuarter.isWaxing, isTrue);
      expect(MoonPhase.waxingGibbous.isWaxing, isTrue);
    });

    test('isWaxing is false while it shrinks', () {
      expect(MoonPhase.waningGibbous.isWaxing, isFalse);
      expect(MoonPhase.lastQuarter.isWaxing, isFalse);
      expect(MoonPhase.waningCrescent.isWaxing, isFalse);
    });

    test('isWaxing is false where there is no limb to choose', () {
      expect(MoonPhase.newMoon.isWaxing, isFalse);
      expect(MoonPhase.fullMoon.isWaxing, isFalse);
      expect(MoonPhase.unknown.isWaxing, isFalse);
    });
  });
}
