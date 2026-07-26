import 'package:aura_domain/src/entities/current_conditions.dart';
import 'package:meta/meta.dart';

/// One place's reading for right now, with no forecast behind it.
///
/// What `current.json` returns. The search screen puts a temperature beside
/// every match with it, where pulling a whole forecast per match would spend
/// quota on days nothing shows.
@immutable
final class CityReading {
  /// Creates a reading.
  const CityReading({
    required this.placeName,
    required this.region,
    required this.country,
    required this.localTime,
    required this.current,
  });

  /// The place's name, as the service resolved it.
  final String placeName;

  /// Its administrative region. Empty when the service gave none.
  final String region;

  /// Its country.
  final String country;

  /// The local time where the place is, which is not the device's time.
  final DateTime localTime;

  /// The reading itself.
  final CurrentConditions current;
}
