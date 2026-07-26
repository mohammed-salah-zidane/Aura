import 'package:aura_core/aura_core.dart';
import 'package:aura_domain/aura_domain.dart';

/// The instant every fixture is built around.
///
/// A Sunday afternoon in Cairo: the sun is up, the hourly strip runs into the
/// evening, and the first forecast day is today.
final DateTime fixtureNow = DateTime(2026, 7, 26, 14, 34);

/// A reading with every field the screens draw.
///
/// Defaults describe the pen's own sample: a clear afternoon in Cairo. Each
/// named argument swaps one part of it, so a test says what it is about and
/// nothing else.
WeatherSnapshot weatherFixture({
  String placeName = 'Cairo',
  String country = 'Egypt',
  AuraCondition condition = AuraCondition.clearDay,
  String conditionText = 'Sunny',
  double temperature = 35,
  double uvIndex = 9,
  AirQuality? airQuality = const AirQuality(
    usEpaIndex: 1,
    concentrations: <Pollutant, double>{
      Pollutant.pm25: 8.2,
      Pollutant.pm10: 14,
      Pollutant.o3: 68,
      Pollutant.no2: 12,
      Pollutant.so2: 4,
      Pollutant.co: 210,
    },
  ),
  List<WeatherAlert> alerts = const <WeatherAlert>[],
  DateTime? localTime,
  int moonIlluminationPercent = 34,
  MoonPhase moonPhase = MoonPhase.waxingCrescent,
  bool hasSunTimes = true,
}) {
  final now = localTime ?? fixtureNow;
  return WeatherSnapshot(
    placeName: placeName,
    region: 'Cairo Governorate',
    country: country,
    localTime: now,
    current: CurrentConditions(
      observedAt: now,
      temperature: Temperature.celsius(temperature),
      feelsLike: const Temperature.celsius(38),
      condition: condition,
      conditionText: conditionText,
      isDay: true,
      windSpeed: const Speed.kilometersPerHour(15),
      windDirection: 'NW',
      gustSpeed: const Speed.kilometersPerHour(22),
      humidityPercent: 38,
      dewPoint: const Temperature.celsius(19),
      pressure: const Pressure.millibars(1013),
      pressureInchesOfMercury: 29.92,
      visibility: const Distance.kilometers(10),
      uvIndex: uvIndex,
      cloudPercent: 5,
    ),
    days: <ForecastDay>[
      for (var day = 0; day < 3; day++)
        ForecastDay(
          date: DateTime(now.year, now.month, now.day + day),
          low: Temperature.celsius(24 + day.toDouble()),
          high: Temperature.celsius(37 + day.toDouble()),
          condition: condition,
          conditionText: conditionText,
          chanceOfRainPercent: day == 2 ? 10 : 0,
          uvIndex: uvIndex,
          astro: AstroInfo(
            sunrise: hasSunTimes
                ? DateTime(now.year, now.month, now.day + day, 5, 14)
                : null,
            sunset: hasSunTimes
                ? DateTime(now.year, now.month, now.day + day, 19, 2)
                : null,
            moonrise: DateTime(now.year, now.month, now.day + day, 9, 42),
            moonset: DateTime(now.year, now.month, now.day + day, 22, 18),
            moonPhase: moonPhase,
            moonIlluminationPercent: moonIlluminationPercent,
          ),
          hours: <HourlyPoint>[
            for (var hour = 0; hour < 24; hour++)
              HourlyPoint(
                time: DateTime(now.year, now.month, now.day + day, hour),
                temperature: Temperature.celsius(30 + (hour % 6).toDouble()),
                condition: condition,
                conditionText: conditionText,
                isDay: hour > 5 && hour < 19,
                chanceOfRainPercent: 0,
              ),
          ],
        ),
    ],
    airQuality: airQuality,
    alerts: alerts,
  );
}

/// An alert with everything the alert screen draws.
WeatherAlert alertFixture({
  String event = 'Heat Advisory',
  AlertSeverity severity = AlertSeverity.moderate,
  String instruction =
      'Stay hydrated, and drink water regularly.\n'
      'Avoid direct sun between 12 and 4 PM.',
  DateTime? effective,
  DateTime? expires,
}) => WeatherAlert(
  event: event,
  headline: 'Heat Advisory issued by the Egyptian Meteorological Authority',
  severity: severity,
  category: 'Met',
  areas: const <String>['Cairo', 'Giza'],
  description:
      'A period of dangerously hot conditions with highs up to 41°C '
      'expected across Greater Cairo through this evening.',
  instruction: instruction,
  effective: effective ?? DateTime(2026, 7, 26, 12),
  expires: expires ?? DateTime(2026, 7, 26, 20),
);

/// A place the user has kept.
SavedCity savedCityFixture({
  String name = 'London',
  String country = 'United Kingdom',
}) => SavedCity(
  location: LocationRef(query: name, displayName: name),
  name: name,
  country: country,
  addedAt: fixtureNow,
);
