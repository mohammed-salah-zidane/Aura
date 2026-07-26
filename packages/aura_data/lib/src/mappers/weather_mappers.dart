import 'package:aura_core/aura_core.dart';
import 'package:aura_domain/aura_domain.dart';
import 'package:aura_weather_api/aura_weather_api.dart';

/// Turns a whole `forecast.json` response into the snapshot a screen renders.
///
/// Every value here is a field WeatherAPI returned, a published scale applied
/// to one, or arithmetic over one. Nothing is composed, defaulted or invented:
/// where the service says `No sunrise`, the entity says null.
///
/// Times arrive as the place's own wall clock rather than the device's, and
/// are kept that way. A sunrise, an hourly reading and `location.localtime`
/// are only comparable to each other if they all sit in the same frame.
///
/// Throws [FormatException] if a timestamp arrives in a shape WeatherAPI has
/// never sent. The repository is the only caller and turns that into a failure,
/// which is better than rendering a silently wrong time.
WeatherSnapshot snapshotFromDto(ForecastResponseDto dto) => WeatherSnapshot(
  placeName: dto.location.name,
  region: dto.location.region,
  country: dto.location.country,
  localTime: DateTime.parse(dto.location.localtime),
  current: _currentFromDto(dto.current),
  days: dto.forecast.forecastday
      .map(_forecastDayFromDto)
      .toList(growable: false),
  airQuality: _airQualityFromDto(dto.current.airQuality),
  alerts:
      dto.alerts?.alert.map(_alertFromDto).toList(growable: false) ??
      const <WeatherAlert>[],
);

/// Turns one `search.json` match into a suggestion the search screen lists.
///
/// The suggestion carries coordinates rather than the place name, because a
/// name is ambiguous across countries and the coordinates are what the user
/// actually picked.
CitySuggestion citySuggestionFromDto(SearchResultDto dto) => CitySuggestion(
  location: LocationRef.coordinates(
    latitude: dto.lat,
    longitude: dto.lon,
    displayName: dto.name,
  ),
  name: dto.name,
  region: dto.region,
  country: dto.country,
);

/// Turns a `current.json` response into the reading a list row shows.
CityReading cityReadingFromDto(CurrentResponseDto dto) => CityReading(
  placeName: dto.location.name,
  region: dto.location.region,
  country: dto.location.country,
  localTime: DateTime.parse(dto.location.localtime),
  current: _currentFromDto(dto.current),
);

CurrentConditions _currentFromDto(CurrentDto dto) => CurrentConditions(
  observedAt: DateTime.parse(dto.lastUpdated),
  temperature: Temperature.celsius(dto.tempC),
  feelsLike: Temperature.celsius(dto.feelslikeC),
  condition: conditionFromCode(dto.condition.code, isDay: dto.isDay == 1),
  conditionText: dto.condition.text,
  isDay: dto.isDay == 1,
  windSpeed: Speed.kilometersPerHour(dto.windKph),
  windDirection: dto.windDir,
  gustSpeed: Speed.kilometersPerHour(dto.gustKph),
  humidityPercent: dto.humidity,
  dewPoint: Temperature.celsius(dto.dewpointC),
  pressure: Pressure.millibars(dto.pressureMb),
  // Taken as reported rather than converted from millibars: the two disagree
  // in the last digit, and the reported one is what the service publishes.
  pressureInchesOfMercury: dto.pressureIn,
  visibility: Distance.kilometers(dto.visKm),
  uvIndex: dto.uv,
  cloudPercent: dto.cloud,
);

ForecastDay _forecastDayFromDto(ForecastDayDto dto) {
  final date = DateTime.parse(dto.date);
  return ForecastDay(
    date: date,
    low: Temperature.celsius(dto.day.mintempC),
    high: Temperature.celsius(dto.day.maxtempC),
    // A daily summary stands for the whole day, so its sky is the daytime one.
    // Only the clear code has a night variant, and a forecast row never shows
    // one.
    condition: conditionFromCode(dto.day.condition.code, isDay: true),
    conditionText: dto.day.condition.text,
    chanceOfRainPercent: dto.day.dailyChanceOfRain,
    uvIndex: dto.day.uv,
    astro: _astroFromDto(dto.astro, date),
    hours: dto.hour.map(_hourlyPointFromDto).toList(growable: false),
  );
}

HourlyPoint _hourlyPointFromDto(HourDto dto) => HourlyPoint(
  time: DateTime.parse(dto.time),
  temperature: Temperature.celsius(dto.tempC),
  condition: conditionFromCode(dto.condition.code, isDay: dto.isDay == 1),
  conditionText: dto.condition.text,
  isDay: dto.isDay == 1,
  chanceOfRainPercent: dto.chanceOfRain,
);

/// Astro times arrive as a bare clock reading, so the day they belong to comes
/// from the forecast day that carried them.
///
/// A moonset after midnight is reported against the day it was requested for,
/// and the service sends nothing to say otherwise, so it is dated the same way.
AstroInfo _astroFromDto(AstroDto dto, DateTime date) => AstroInfo(
  sunrise: _clockTimeOn(date, dto.sunrise),
  sunset: _clockTimeOn(date, dto.sunset),
  moonrise: _clockTimeOn(date, dto.moonrise),
  moonset: _clockTimeOn(date, dto.moonset),
  moonPhase: moonPhaseFromName(dto.moonPhase),
  moonIlluminationPercent: dto.moonIllumination,
);

AirQuality? _airQualityFromDto(AirQualityDto? dto) {
  if (dto == null) return null;
  return AirQuality(
    usEpaIndex: dto.usEpaIndex,
    concentrations: <Pollutant, double>{
      Pollutant.pm25: dto.pm25,
      Pollutant.pm10: dto.pm10,
      Pollutant.no2: dto.no2,
      Pollutant.o3: dto.o3,
      Pollutant.so2: dto.so2,
      Pollutant.co: dto.co,
    },
  );
}

WeatherAlert _alertFromDto(AlertDto dto) => WeatherAlert(
  event: dto.event,
  headline: dto.headline,
  severity: alertSeverityFromName(dto.severity),
  category: dto.category,
  areas: _areasFromDto(dto.areas),
  description: dto.desc,
  instruction: dto.instruction,
  // These two carry a zone offset, unlike every other time in the response, so
  // they are absolute instants. Some feeds send an empty string instead.
  effective: DateTime.tryParse(dto.effective),
  expires: DateTime.tryParse(dto.expires),
);

List<String> _areasFromDto(String areas) => areas
    .split(';')
    .map((area) => area.trim())
    .where((area) => area.isNotEmpty)
    .toList(growable: false);

/// Reads `hh:mm a` or `HH:mm` as a time on [date].
///
/// Returns null for anything else, which is how `No sunrise`, `No sunset` and
/// `No moonrise` arrive at high latitudes. A polar day is a real reading, not a
/// parse failure.
DateTime? _clockTimeOn(DateTime date, String value) {
  final text = value.trim().toUpperCase();
  final isMorning = text.endsWith('AM');
  final isAfternoon = text.endsWith('PM');
  final digits = isMorning || isAfternoon
      ? text.substring(0, text.length - 2).trim()
      : text;

  final parts = digits.split(':');
  if (parts.length != 2) return null;

  final rawHour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (rawHour == null || minute == null) return null;
  if (minute < 0 || minute > 59) return null;

  var hour = rawHour;
  if (isMorning || isAfternoon) {
    if (rawHour < 1 || rawHour > 12) return null;
    hour = rawHour % 12 + (isAfternoon ? 12 : 0);
  } else if (rawHour < 0 || rawHour > 23) {
    return null;
  }

  return DateTime(date.year, date.month, date.day, hour, minute);
}
