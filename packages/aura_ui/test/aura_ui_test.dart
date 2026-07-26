import 'package:aura_core/aura_core.dart';
import 'package:aura_design/aura_design.dart';
import 'package:aura_domain/aura_domain.dart';
import 'package:aura_l10n/aura_l10n.dart';
import 'package:aura_ui/aura_ui.dart';
import 'package:flutter/widgets.dart';
// aura_core publishes a Timeout failure, and so does the test framework.
import 'package:flutter_test/flutter_test.dart' hide Timeout;
import 'package:intl/intl.dart' hide TextDirection;

late AppLocalizations en;
late AppLocalizations ar;

AuraFormat _format({
  AppLocalizations? l10n,
  UnitPreferences units = const UnitPreferences(),
}) => AuraFormat(l10n: l10n ?? en, units: units);

void main() {
  setUpAll(() async {
    await AuraLocales.loadDateSymbols();
    en = await AppLocalizations.delegate.load(const Locale('en'));
    ar = await AppLocalizations.delegate.load(const Locale('ar'));
    AuraLocales.adopt(const Locale('en'));
  });

  group('AuraFormat temperature', () {
    test('temperature rounds to the whole degree the design shows', () {
      expect(_format().temperature(const Temperature.celsius(34.6)), '35°');
    });

    test('temperature keeps a negative reading negative', () {
      expect(_format().temperature(const Temperature.celsius(-2.4)), '-2°');
    });

    test('temperature converts to the chosen scale', () {
      final fahrenheit = _format(
        units: const UnitPreferences(temperature: TemperatureUnit.fahrenheit),
      );
      expect(fahrenheit.temperature(const Temperature.celsius(35)), '95°');
    });

    test('high and low wear the labels the design gives them', () {
      final format = _format();
      expect(format.high(const Temperature.celsius(37)), 'H:37°');
      expect(format.low(const Temperature.celsius(24)), 'L:24°');
    });
  });

  group('AuraFormat units', () {
    test('speed carries the symbol for the chosen unit', () {
      expect(_format().speed(const Speed.kilometersPerHour(15)), '15 km/h');
      expect(
        _format(
          units: const UnitPreferences(speed: SpeedUnit.milesPerHour),
        ).speed(const Speed.kilometersPerHour(16.09344)),
        '10 mph',
      );
    });

    test('distance follows the speed unit, because they travel together', () {
      expect(_format().distance(const Distance.kilometers(10)), '10 km');
      expect(
        _format(
          units: const UnitPreferences(speed: SpeedUnit.milesPerHour),
        ).distance(const Distance.kilometers(16.09344)),
        '10 mi',
      );
    });

    test('distance keeps the decimal a sub-kilometre reading needs', () {
      expect(_format().distance(const Distance.kilometers(0.8)), '0.8 km');
    });

    test('pressure is written the way a barometer is read', () {
      // Never `1,013`.
      expect(_format().pressure(const Pressure.millibars(1013)), '1013');
    });

    test('pressureInches keeps the two decimals the service publishes', () {
      expect(_format().pressureInches(29.92), '29.92 inHg');
    });

    test('percent is a whole number with its sign', () {
      expect(_format().percent(38), '38%');
    });
  });

  group('AuraFormat scales', () {
    test('uvBand names the WHO band', () {
      expect(_format().uvBand(UvBand.veryHigh), en.uvBandVeryHigh);
    });

    test('epaCategory names the EPA category', () {
      expect(_format().epaCategory(EpaCategory.good), en.epaGood);
    });

    test(
      'epaMeaning renders the published description, not a summary of it',
      () {
        expect(_format().epaMeaning(EpaCategory.good), en.epaGoodMeaning);
      },
    );

    test('moonPhase leaves the slot empty for a phase with no name', () {
      expect(_format().moonPhase(MoonPhase.unknown), isEmpty);
    });
  });

  group('AuraFormat time', () {
    test('age coarsens to the largest unit that fits', () {
      final format = _format();
      expect(format.age(const Duration(seconds: 20)), en.durationJustNow);
      expect(format.age(const Duration(minutes: 45)), en.durationMinutes(45));
      expect(format.age(const Duration(hours: 2)), en.durationHours(2));
      expect(format.age(const Duration(days: 3)), en.durationDays(3));
    });

    test('age reads as Arabic rather than as a translated English count', () {
      // Arabic has a dual, and two hours is not "2 hours".
      AuraLocales.adopt(const Locale('ar'));
      addTearDown(() => AuraLocales.adopt(const Locale('en')));

      expect(
        _format(l10n: ar).age(const Duration(hours: 2)),
        'ساعتين',
      );
    });

    test('day says today for the first row and a weekday after it', () {
      final format = _format();
      final date = DateTime(2026, 7, 27);
      expect(format.day(date, isToday: true), en.dayToday);
      expect(format.day(date, isToday: false), DateFormat.E().format(date));
    });

    test('clock reads the 24-hour dial the astro rows are set on', () {
      expect(_format().clock(DateTime(2026, 7, 26, 5, 14)), '05:14');
    });
  });

  group('AuraConditionVisuals', () {
    test('sky answers for every condition the domain can produce', () {
      for (final condition in AuraCondition.values) {
        expect(AuraConditionVisuals.sky(condition), isA<AuraSkyKind>());
        expect(AuraConditionVisuals.icon(condition), isA<IconData>());
        expect(AuraConditionVisuals.tint(condition), isA<Color>());
      }
    });

    test(
      'sky falls back to the brand sky for a code the domain cannot place',
      () {
        // WeatherAPI can add codes. Guessing at a neighbouring sky would be
        // worse than showing the one no condition owns.
        expect(
          AuraConditionVisuals.sky(AuraCondition.unknown),
          AuraSkyKind.systemBrand,
        );
      },
    );

    test('hourIcon swaps to a sunset for the hour the sun goes down', () {
      expect(
        AuraConditionVisuals.hourIcon(
          AuraCondition.clearDay,
          isSunset: true,
        ),
        AuraIcons.sunset,
      );
      expect(
        AuraConditionVisuals.hourIcon(
          AuraCondition.clearDay,
          isSunset: false,
        ),
        AuraIcons.sun,
      );
    });
  });

  group('AuraFailureCopy', () {
    test('of answers for every failure the app can produce', () {
      const failures = <AppFailure>[
        NoConnection(),
        Timeout(),
        InvalidCity(),
        Unauthorized(),
        RateLimited(),
        ServerError(),
        CacheMiss(),
        Unknown(),
      ];
      for (final failure in failures) {
        final copy = AuraFailureCopy.of(en, failure);
        expect(copy.title, isNotEmpty, reason: '$failure has no title');
        expect(copy.body, isNotEmpty, reason: '$failure has no body');
      }
    });

    test('of names a lost connection as the offline state', () {
      expect(
        AuraFailureCopy.of(en, const NoConnection()).title,
        en.offlineTitle,
      );
    });
  });
}
