import 'package:aura_core/aura_core.dart';
import 'package:aura_domain/aura_domain.dart';

/// Writes a snapshot to the shape the cache column holds.
///
/// Entities are stored rather than the wire response, so the cache never has
/// to be re-mapped and never depends on a DTO staying the shape it is today.
///
/// Every time is written as ISO 8601, which keeps a place's wall clock a wall
/// clock and an alert's instant an instant. Storing them as epoch seconds would
/// shift a sunrise into the device's own zone.
Map<String, Object?> encodeSnapshot(WeatherSnapshot snapshot) =>
    <String, Object?>{
      'placeName': snapshot.placeName,
      'region': snapshot.region,
      'country': snapshot.country,
      'localTime': snapshot.localTime.toIso8601String(),
      'current': _encodeCurrent(snapshot.current),
      'days': snapshot.days.map(_encodeDay).toList(),
      'airQuality': _encodeAirQuality(snapshot.airQuality),
      'alerts': snapshot.alerts.map(_encodeAlert).toList(),
    };

/// Reads a snapshot back out of the cache column.
///
/// Throws [FormatException] when the stored shape is not the one this build
/// writes, which is what a row left by an older version looks like. The cache
/// reports that as a miss, so the next fetch simply overwrites it.
WeatherSnapshot decodeSnapshot(Map<String, Object?> json) => WeatherSnapshot(
  placeName: _field<String>(json, 'placeName'),
  region: _field<String>(json, 'region'),
  country: _field<String>(json, 'country'),
  localTime: _time(json, 'localTime'),
  current: _decodeCurrent(_object(json, 'current')),
  days: _list(json, 'days').map(_decodeDay).toList(growable: false),
  airQuality: _decodeAirQuality(json['airQuality']),
  alerts: _list(json, 'alerts').map(_decodeAlert).toList(growable: false),
);

Map<String, Object?> _encodeCurrent(CurrentConditions current) =>
    <String, Object?>{
      'observedAt': current.observedAt.toIso8601String(),
      'temperature': current.temperature.celsius,
      'feelsLike': current.feelsLike.celsius,
      'condition': current.condition.name,
      'conditionText': current.conditionText,
      'isDay': current.isDay,
      'windSpeed': current.windSpeed.kilometersPerHour,
      'windDirection': current.windDirection,
      'gustSpeed': current.gustSpeed.kilometersPerHour,
      'humidityPercent': current.humidityPercent,
      'dewPoint': current.dewPoint.celsius,
      'pressure': current.pressure.millibars,
      'pressureInchesOfMercury': current.pressureInchesOfMercury,
      'visibility': current.visibility.kilometers,
      'uvIndex': current.uvIndex,
      'cloudPercent': current.cloudPercent,
    };

CurrentConditions _decodeCurrent(Map<String, Object?> json) =>
    CurrentConditions(
      observedAt: _time(json, 'observedAt'),
      temperature: Temperature.celsius(_number(json, 'temperature')),
      feelsLike: Temperature.celsius(_number(json, 'feelsLike')),
      condition: _enum(AuraCondition.values, json, 'condition'),
      conditionText: _field<String>(json, 'conditionText'),
      isDay: _field<bool>(json, 'isDay'),
      windSpeed: Speed.kilometersPerHour(_number(json, 'windSpeed')),
      windDirection: _field<String>(json, 'windDirection'),
      gustSpeed: Speed.kilometersPerHour(_number(json, 'gustSpeed')),
      humidityPercent: _integer(json, 'humidityPercent'),
      dewPoint: Temperature.celsius(_number(json, 'dewPoint')),
      pressure: Pressure.millibars(_number(json, 'pressure')),
      pressureInchesOfMercury: _number(json, 'pressureInchesOfMercury'),
      visibility: Distance.kilometers(_number(json, 'visibility')),
      uvIndex: _number(json, 'uvIndex'),
      cloudPercent: _integer(json, 'cloudPercent'),
    );

Map<String, Object?> _encodeDay(ForecastDay day) => <String, Object?>{
  'date': day.date.toIso8601String(),
  'low': day.low.celsius,
  'high': day.high.celsius,
  'condition': day.condition.name,
  'conditionText': day.conditionText,
  'chanceOfRainPercent': day.chanceOfRainPercent,
  'uvIndex': day.uvIndex,
  'astro': _encodeAstro(day.astro),
  'hours': day.hours.map(_encodeHour).toList(),
};

ForecastDay _decodeDay(Object? entry) {
  final json = _asObject(entry, 'day');
  return ForecastDay(
    date: _time(json, 'date'),
    low: Temperature.celsius(_number(json, 'low')),
    high: Temperature.celsius(_number(json, 'high')),
    condition: _enum(AuraCondition.values, json, 'condition'),
    conditionText: _field<String>(json, 'conditionText'),
    chanceOfRainPercent: _integer(json, 'chanceOfRainPercent'),
    uvIndex: _number(json, 'uvIndex'),
    astro: _decodeAstro(_object(json, 'astro')),
    hours: _list(json, 'hours').map(_decodeHour).toList(growable: false),
  );
}

Map<String, Object?> _encodeHour(HourlyPoint hour) => <String, Object?>{
  'time': hour.time.toIso8601String(),
  'temperature': hour.temperature.celsius,
  'condition': hour.condition.name,
  'conditionText': hour.conditionText,
  'isDay': hour.isDay,
  'chanceOfRainPercent': hour.chanceOfRainPercent,
};

HourlyPoint _decodeHour(Object? entry) {
  final json = _asObject(entry, 'hour');
  return HourlyPoint(
    time: _time(json, 'time'),
    temperature: Temperature.celsius(_number(json, 'temperature')),
    condition: _enum(AuraCondition.values, json, 'condition'),
    conditionText: _field<String>(json, 'conditionText'),
    isDay: _field<bool>(json, 'isDay'),
    chanceOfRainPercent: _integer(json, 'chanceOfRainPercent'),
  );
}

Map<String, Object?> _encodeAstro(AstroInfo astro) => <String, Object?>{
  'sunrise': astro.sunrise?.toIso8601String(),
  'sunset': astro.sunset?.toIso8601String(),
  'moonrise': astro.moonrise?.toIso8601String(),
  'moonset': astro.moonset?.toIso8601String(),
  'moonPhase': astro.moonPhase.name,
  'moonIlluminationPercent': astro.moonIlluminationPercent,
};

AstroInfo _decodeAstro(Map<String, Object?> json) => AstroInfo(
  sunrise: _optionalTime(json, 'sunrise'),
  sunset: _optionalTime(json, 'sunset'),
  moonrise: _optionalTime(json, 'moonrise'),
  moonset: _optionalTime(json, 'moonset'),
  moonPhase: _enum(MoonPhase.values, json, 'moonPhase'),
  moonIlluminationPercent: _integer(json, 'moonIlluminationPercent'),
);

Map<String, Object?>? _encodeAirQuality(AirQuality? air) {
  if (air == null) return null;
  return <String, Object?>{
    'usEpaIndex': air.usEpaIndex,
    'concentrations': air.concentrations.map(
      (pollutant, value) => MapEntry<String, Object?>(pollutant.name, value),
    ),
  };
}

AirQuality? _decodeAirQuality(Object? entry) {
  if (entry == null) return null;
  final json = _asObject(entry, 'airQuality');
  final raw = _object(json, 'concentrations');
  return AirQuality(
    usEpaIndex: _integer(json, 'usEpaIndex'),
    concentrations: <Pollutant, double>{
      for (final entry in raw.entries)
        Pollutant.values.byName(entry.key): _asNumber(
          entry.value,
          entry.key,
        ),
    },
  );
}

Map<String, Object?> _encodeAlert(WeatherAlert alert) => <String, Object?>{
  'event': alert.event,
  'severity': alert.severity.name,
  'category': alert.category,
  'areas': alert.areas,
  'description': alert.description,
  'instruction': alert.instruction,
  'effective': alert.effective?.toIso8601String(),
  'expires': alert.expires?.toIso8601String(),
};

WeatherAlert _decodeAlert(Object? entry) {
  final json = _asObject(entry, 'alert');
  return WeatherAlert(
    event: _field<String>(json, 'event'),
    severity: _enum(AlertSeverity.values, json, 'severity'),
    category: _field<String>(json, 'category'),
    areas: _list(
      json,
      'areas',
    ).map((area) => _asField<String>(area, 'area')).toList(growable: false),
    description: _field<String>(json, 'description'),
    instruction: _field<String>(json, 'instruction'),
    effective: _optionalTime(json, 'effective'),
    expires: _optionalTime(json, 'expires'),
  );
}

T _field<T>(Map<String, Object?> json, String key) =>
    _asField<T>(json[key], key);

T _asField<T>(Object? value, String key) {
  if (value is T) return value;
  throw FormatException('cached snapshot has no $T at $key');
}

double _number(Map<String, Object?> json, String key) =>
    _asNumber(json[key], key);

double _asNumber(Object? value, String key) => value is num
    ? value.toDouble()
    : throw FormatException('no number at $key');

int _integer(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is int) return value;
  throw FormatException('cached snapshot has no integer at $key');
}

Map<String, Object?> _object(Map<String, Object?> json, String key) =>
    _asObject(json[key], key);

Map<String, Object?> _asObject(Object? value, String key) {
  if (value is Map<String, Object?>) return value;
  throw FormatException('cached snapshot has no object at $key');
}

List<Object?> _list(Map<String, Object?> json, String key) =>
    _field<List<Object?>>(json, key);

DateTime _time(Map<String, Object?> json, String key) =>
    DateTime.parse(_field<String>(json, key));

DateTime? _optionalTime(Map<String, Object?> json, String key) {
  final value = json[key];
  return value == null ? null : DateTime.parse(_asField<String>(value, key));
}

T _enum<T extends Enum>(
  List<T> values,
  Map<String, Object?> json,
  String key,
) => values.byName(_field<String>(json, key));
