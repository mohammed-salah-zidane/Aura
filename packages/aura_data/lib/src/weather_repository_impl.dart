import 'package:aura_core/aura_core.dart';
import 'package:aura_data/src/mappers/weather_mappers.dart';
import 'package:aura_domain/aura_domain.dart';
import 'package:aura_weather_api/aura_weather_api.dart';

/// The only place that decides between the network and the cache.
///
/// Network first, always: a reading the user can see is worth a round trip.
/// When the request never lands, the cache answers instead and the result says
/// how old it is, so the screen can show data and admit it is stale rather than
/// showing an error over data it already has.
final class WeatherRepositoryImpl implements WeatherRepository {
  /// Creates the repository over its three collaborators.
  const WeatherRepositoryImpl({
    required this._api,
    required this._cache,
    required this._clock,
  });

  final WeatherApi _api;
  final WeatherCachePort _cache;
  final Clock _clock;

  @override
  Future<Result<Stale<WeatherSnapshot>, AppFailure>> snapshot(
    LocationRef location, {
    String? lang,
  }) async {
    final response = await _api.forecast(query: location.query, lang: lang);

    switch (response) {
      case Ok<ForecastResponseDto, AppFailure>(:final value):
        return _store(location, value);

      // Only a request that never landed falls back. An invalid city, a spent
      // quota and a rejected key are all definite answers, and answering them
      // with yesterday's weather would hide a problem the user can act on.
      case Err<ForecastResponseDto, AppFailure>(:final failure):
        if (failure is! NoConnection) {
          return Err<Stale<WeatherSnapshot>, AppFailure>(failure);
        }
        final cached = await _cache.read(location);
        // A cache miss is reported as the network failure that caused the
        // lookup. "No connection" is what the user has to fix; "nothing
        // cached" is a detail of how the app tried to cope.
        return cached.isOk
            ? cached
            : Err<Stale<WeatherSnapshot>, AppFailure>(failure);
    }
  }

  @override
  Future<Result<List<CitySuggestion>, AppFailure>> search(String prefix) async {
    // An empty box is a normal state of the search screen, not a query. Sending
    // it spends a request to be told `q` is missing.
    if (prefix.trim().isEmpty) {
      return const Ok<List<CitySuggestion>, AppFailure>(<CitySuggestion>[]);
    }

    final response = await _api.search(prefix);
    return response.map(
      (results) => results.map(citySuggestionFromDto).toList(growable: false),
    );
  }

  /// Maps a fresh response, caches it, and hands it back stamped now.
  ///
  /// A failed write is not a failed read. The user has the reading they asked
  /// for; all a rejected cache costs them is the offline copy.
  Future<Result<Stale<WeatherSnapshot>, AppFailure>> _store(
    LocationRef location,
    ForecastResponseDto dto,
  ) async {
    final WeatherSnapshot snapshot;
    try {
      snapshot = snapshotFromDto(dto);
    } on Object catch (error) {
      // The last place an exception could escape this layer: a timestamp in a
      // shape the service has never sent throws out of the mapper.
      return Err<Stale<WeatherSnapshot>, AppFailure>(Unknown(cause: error));
    }

    final fetchedAt = _clock.now();
    await _cache.write(location, snapshot, fetchedAt: fetchedAt);
    return Ok<Stale<WeatherSnapshot>, AppFailure>(
      Stale<WeatherSnapshot>(snapshot, fetchedAt: fetchedAt),
    );
  }
}
