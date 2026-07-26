import 'package:aura_core/aura_core.dart';
import 'package:aura_data/aura_data.dart';
import 'package:aura_domain/aura_domain.dart';
import 'package:aura_weather_api/aura_weather_api.dart';
import 'package:test/test.dart' hide Timeout;

import 'fixtures.dart';

/// A `current.json` response, taken from the captured forecast fixture.
CurrentResponseDto _response() {
  final forecast = ForecastResponseDto.fromJson(
    loadJsonObject('forecast_cairo'),
  );
  return CurrentResponseDto(
    location: forecast.location,
    current: forecast.current,
  );
}

final class _Api implements WeatherApi {
  _Api({this.failure});

  final AppFailure? failure;
  int calls = 0;
  String? lastQuery;
  String? lastLang;

  @override
  Future<Result<CurrentResponseDto, AppFailure>> current({
    required String query,
    String? lang,
  }) async {
    calls++;
    lastQuery = query;
    lastLang = lang;
    final reason = failure;
    return reason == null
        ? Ok<CurrentResponseDto, AppFailure>(_response())
        : Err<CurrentResponseDto, AppFailure>(reason);
  }

  @override
  Future<Result<ForecastResponseDto, AppFailure>> forecast({
    required String query,
    String? lang,
  }) async => const Err<ForecastResponseDto, AppFailure>(Unknown());

  @override
  Future<Result<List<SearchResultDto>, AppFailure>> search(
    String prefix,
  ) async => const Ok<List<SearchResultDto>, AppFailure>(<SearchResultDto>[]);
}

final class _Cache implements WeatherCachePort {
  @override
  Future<Result<Stale<WeatherSnapshot>, AppFailure>> read(
    LocationRef location,
  ) async => const Err<Stale<WeatherSnapshot>, AppFailure>(CacheMiss());

  @override
  Future<Result<void, AppFailure>> write(
    LocationRef location,
    WeatherSnapshot snapshot, {
    required DateTime fetchedAt,
  }) async => const Ok<void, AppFailure>(null);

  @override
  Future<Result<void, AppFailure>> clear() async =>
      const Ok<void, AppFailure>(null);
}

WeatherRepositoryImpl _repository(_Api api) => WeatherRepositoryImpl(
  api: api,
  cache: _Cache(),
  clock: FixedClock(DateTime(2026, 7, 26, 14, 34)),
);

void main() {
  group('reading', () {
    test(
      'reading maps the response into the entity a list row shows',
      () async {
        final api = _Api();
        final result = await _repository(api).reading(
          const LocationRef(query: 'Cairo'),
        );

        final reading = result.valueOrNull!;
        expect(reading.placeName, 'Cairo');
        expect(reading.country, 'Egypt');
        expect(reading.current.temperature.celsius, isA<double>());
      },
    );

    test('reading asks the service for the place it was given', () async {
      final api = _Api();
      await _repository(
        api,
      ).reading(const LocationRef(query: 'Cairns'), lang: 'ar');

      expect(api.lastQuery, 'Cairns');
      expect(api.lastLang, 'ar');
    });

    test('reading never falls back to the cache', () async {
      // The user is choosing between places. A number from yesterday would
      // decide it, so no answer is better than an old one.
      final api = _Api(failure: const NoConnection());
      final result = await _repository(api).reading(
        const LocationRef(query: 'Cairo'),
      );

      expect(result.failureOrNull, const NoConnection());
    });

    test('reading passes a failure through unchanged', () async {
      final api = _Api(failure: const RateLimited());
      final result = await _repository(api).reading(
        const LocationRef(query: 'Cairo'),
      );

      expect(result.failureOrNull, const RateLimited());
    });
  });
}
