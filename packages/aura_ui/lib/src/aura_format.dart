import 'package:aura_core/aura_core.dart';
import 'package:aura_domain/aura_domain.dart';
import 'package:aura_l10n/aura_l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// Turns a domain value into the copy a screen shows for it.
///
/// Formatting is presentation, so it lives here rather than in the domain: it
/// needs the active locale, the chosen units and the app's own copy, and none
/// of those belong to an entity. Every method returns a string built from a
/// field WeatherAPI returns, a published scale over one, or arithmetic over
/// one. Nothing here composes a sentence of its own.
///
/// `DateFormat` and `NumberFormat` are given no locale on purpose:
/// `AuraLocales` puts the resolved one in `Intl.defaultLocale` at startup, so
/// they follow whatever `Localizations` chose.
@immutable
class AuraFormat {
  /// Creates a formatter over the active copy and the chosen units.
  const AuraFormat({required this.l10n, required this.units});

  /// Reads the formatter out of a widget's context.
  factory AuraFormat.of(BuildContext context, UnitPreferences units) =>
      AuraFormat(l10n: context.l10n, units: units);

  /// The app's copy, in the active locale.
  final AppLocalizations l10n;

  /// Which units to render values in.
  final UnitPreferences units;

  // ------------------------------------------------------------ temperature

  /// A temperature, as the design writes it everywhere: rounded, degree sign,
  /// no unit letter. Which scale it is in is the user's own setting, and the
  /// settings screen is where it is named.
  String temperature(Temperature value) =>
      '${_integer(value.inUnit(units.temperature))}°';

  /// The day's high, as `H:37°`.
  String high(Temperature value) => l10n.temperatureHigh(temperature(value));

  /// The day's low, as `L:24°`.
  String low(Temperature value) => l10n.temperatureLow(temperature(value));

  /// The high and low pair on one line.
  String highLow(Temperature highValue, Temperature lowValue) =>
      l10n.temperatureHighLow(high(highValue), low(lowValue));

  // ------------------------------------------------------------- other units

  /// A wind speed with its unit, as `15 km/h`.
  String speed(Speed value) {
    final symbol = switch (units.speed) {
      SpeedUnit.kilometersPerHour => l10n.unitSpeedKilometersPerHour,
      SpeedUnit.milesPerHour => l10n.unitSpeedMilesPerHour,
    };
    return '${_integer(value.inUnit(units.speed))} $symbol';
  }

  /// A wind speed with no unit, for the gust reading that follows one.
  String speedValue(Speed value) => _integer(value.inUnit(units.speed));

  /// A visibility with its unit, as `10 km`.
  ///
  /// Kept to one decimal, which drops for a whole number and stays for the
  /// sub-kilometre readings fog produces.
  String distance(Distance value) {
    final unit = units.speed == SpeedUnit.milesPerHour
        ? DistanceUnit.miles
        : DistanceUnit.kilometers;
    final symbol = unit == DistanceUnit.miles
        ? l10n.unitDistanceMiles
        : l10n.unitDistanceKilometers;
    return '${_decimal(value.inUnit(unit), 1)} $symbol';
  }

  /// Pressure in millibars, which is the same number as hectopascals.
  String pressure(Pressure value) => _integer(value.millibars);

  /// Pressure as the service publishes it in inches of mercury.
  String pressureInches(double inchesOfMercury) =>
      '${_decimal(inchesOfMercury, 2)} ${l10n.unitPressureInchesOfMercury}';

  /// A whole-number percentage, as `38%`.
  String percent(int value) =>
      NumberFormat.percentPattern().format(value / 100);

  /// A UV index, rounded to the whole number the WHO scale is banded on.
  String uvIndex(double value) => _integer(value);

  /// A concentration, as the air quality screen lists them.
  String concentration(double microgramsPerCubicMetre) =>
      _decimal(microgramsPerCubicMetre, 1);

  // ------------------------------------------------------------------ scales

  /// The WHO band for a UV index.
  String uvBand(UvBand band) => switch (band) {
    UvBand.none => l10n.uvBandNone,
    UvBand.low => l10n.uvBandLow,
    UvBand.moderate => l10n.uvBandModerate,
    UvBand.high => l10n.uvBandHigh,
    UvBand.veryHigh => l10n.uvBandVeryHigh,
    UvBand.extreme => l10n.uvBandExtreme,
  };

  /// The US EPA category for an air quality index.
  String epaCategory(EpaCategory category) => switch (category) {
    EpaCategory.good => l10n.epaGood,
    EpaCategory.moderate => l10n.epaModerate,
    EpaCategory.unhealthyForSensitiveGroups =>
      l10n.epaUnhealthyForSensitiveGroups,
    EpaCategory.unhealthy => l10n.epaUnhealthy,
    EpaCategory.veryUnhealthy => l10n.epaVeryUnhealthy,
    EpaCategory.hazardous => l10n.epaHazardous,
  };

  /// The EPA's own published description of a category.
  String epaMeaning(EpaCategory category) => switch (category) {
    EpaCategory.good => l10n.epaGoodMeaning,
    EpaCategory.moderate => l10n.epaModerateMeaning,
    EpaCategory.unhealthyForSensitiveGroups =>
      l10n.epaUnhealthyForSensitiveGroupsMeaning,
    EpaCategory.unhealthy => l10n.epaUnhealthyMeaning,
    EpaCategory.veryUnhealthy => l10n.epaVeryUnhealthyMeaning,
    EpaCategory.hazardous => l10n.epaHazardousMeaning,
  };

  /// The moon phase, as WeatherAPI names it.
  String moonPhase(MoonPhase phase) => switch (phase) {
    MoonPhase.newMoon => l10n.moonNewMoon,
    MoonPhase.waxingCrescent => l10n.moonWaxingCrescent,
    MoonPhase.firstQuarter => l10n.moonFirstQuarter,
    MoonPhase.waxingGibbous => l10n.moonWaxingGibbous,
    MoonPhase.fullMoon => l10n.moonFullMoon,
    MoonPhase.waningGibbous => l10n.moonWaningGibbous,
    MoonPhase.lastQuarter => l10n.moonLastQuarter,
    MoonPhase.waningCrescent => l10n.moonWaningCrescent,
    // A name the service adds later has no phase behind it, so the reading is
    // the illumination alone and this slot stays empty.
    MoonPhase.unknown => '',
  };

  // ------------------------------------------------------------------- time

  /// An hour of the day, in the locale's own clock. `3 PM`
  String hour(DateTime time) => DateFormat.j().format(time);

  /// A clock time on the 24-hour dial, as the design writes sunrise and
  /// sunset. `05:14`
  String clock(DateTime time) => DateFormat.Hm().format(time);

  /// A clock time with minutes, in the locale's own clock. `2:34 PM`
  String timeOfDay(DateTime time) => DateFormat.jm().format(time);

  /// A weekday, abbreviated. `Mon`
  String weekday(DateTime date) => DateFormat.E().format(date);

  /// A weekday, or the word for today on the first forecast day.
  String day(DateTime date, {required bool isToday}) =>
      isToday ? l10n.dayToday : weekday(date);

  /// How old a reading is, coarsened to the largest unit that fits.
  ///
  /// Reads inside "Last updated ... ago", so it names a span rather than an
  /// instant.
  String age(Duration value) {
    if (value.inMinutes < 1) return l10n.durationJustNow;
    if (value.inHours < 1) return l10n.durationMinutes(value.inMinutes);
    if (value.inDays < 1) return l10n.durationHours(value.inHours);
    return l10n.durationDays(value.inDays);
  }

  // ------------------------------------------------------------------ digits

  String _integer(double value) =>
      NumberFormat.decimalPattern().format(value.round());

  String _decimal(double value, int places) =>
      (NumberFormat.decimalPattern()..maximumFractionDigits = places).format(
        value,
      );
}
