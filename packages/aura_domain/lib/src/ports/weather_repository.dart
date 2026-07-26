import 'package:aura_core/aura_core.dart';
import 'package:aura_domain/src/entities/city_reading.dart';
import 'package:aura_domain/src/entities/location_ref.dart';
import 'package:aura_domain/src/entities/weather_snapshot.dart';

/// One match from city autocomplete.
class CitySuggestion {
  /// Creates a suggestion.
  const CitySuggestion({
    required this.location,
    required this.name,
    required this.region,
    required this.country,
  });

  /// How to ask the service about it.
  final LocationRef location;

  /// Its name.
  final String name;

  /// Its administrative region. Empty when the service gave none.
  final String region;

  /// Its country.
  final String country;
}

/// Where weather comes from, as far as the app is concerned.
///
/// Declared here and implemented in the data layer, so the domain never
/// points at infrastructure. Everything returns a `Result`: no exception
/// crosses this boundary.
abstract interface class WeatherRepository {
  /// The whole home screen for one place.
  ///
  /// Returns a `Stale` when it fell back to the cache, carrying when the
  /// reading was fetched so the screen can say how old it is.
  Future<Result<Stale<WeatherSnapshot>, AppFailure>> snapshot(
    LocationRef location, {
    String? lang,
  });

  /// City autocomplete.
  Future<Result<List<CitySuggestion>, AppFailure>> search(String prefix);

  /// One place's reading for right now, with no forecast behind it.
  ///
  /// Never falls back to the cache. It answers the temperature beside a search
  /// result, where a stale reading would be worse than none: the user is
  /// choosing between places, and a number from yesterday would decide it.
  Future<Result<CityReading, AppFailure>> reading(
    LocationRef location, {
    String? lang,
  });
}
