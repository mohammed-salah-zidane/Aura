import 'package:aura_core/aura_core.dart';
import 'package:aura_data/aura_data.dart';
import 'package:aura_domain/aura_domain.dart';
import 'package:aura_weather_api/aura_weather_api.dart';
import 'package:mocktail/mocktail.dart';
// aura_core's Timeout failure and package:test's own Timeout annotation share
// a name, and only one of them belongs in a test file about failures.
import 'package:test/test.dart' hide Timeout;

import 'fixtures.dart';

class _MockWeatherApi extends Mock implements WeatherApi {}

class _MockCache extends Mock implements WeatherCachePort {}

ForecastResponseDto _cairoResponse([
  void Function(Map<String, dynamic> json)? patch,
]) {
  final json = loadJsonObject('forecast_cairo');
  patch?.call(json);
  return ForecastResponseDto.fromJson(json);
}

/// Every failure the repository can be handed. `NoConnection` is deliberately
/// absent: it is the one that behaves differently and has its own group.
const List<AppFailure> _definiteFailures = <AppFailure>[
  Timeout(),
  InvalidCity(),
  Unauthorized(),
  RateLimited(),
  ServerError(),
  Unknown(),
];

void main() {
  const location = LocationRef(query: 'Cairo');
  final now = DateTime.utc(2026, 7, 26, 14);

  late _MockWeatherApi api;
  late _MockCache cache;
  late FixedClock clock;
  late WeatherRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(const LocationRef(query: 'fallback'));
    registerFallbackValue(snapshotFromDto(_cairoResponse()));
  });

  setUp(() {
    api = _MockWeatherApi();
    cache = _MockCache();
    clock = FixedClock(now);
    repository = WeatherRepositoryImpl(api: api, cache: cache, clock: clock);

    when(
      () => cache.write(any(), any(), fetchedAt: any(named: 'fetchedAt')),
    ).thenAnswer((_) async => const Ok<void, AppFailure>(null));
  });

  void answerForecast(Result<ForecastResponseDto, AppFailure> result) {
    when(
      () => api.forecast(
        query: any(named: 'query'),
        lang: any(named: 'lang'),
      ),
    ).thenAnswer((_) async => result);
  }

  group('snapshot when the network answers', () {
    setUp(() {
      answerForecast(Ok<ForecastResponseDto, AppFailure>(_cairoResponse()));
    });

    test('snapshot returns the mapped reading', () async {
      final result = await repository.snapshot(location);

      expect(result.isOk, isTrue);
      expect(result.valueOrNull?.value.placeName, 'Cairo');
      expect(result.valueOrNull?.value.days, hasLength(3));
    });

    // A fresh reading is still a Stale: it carries when it was fetched, and
    // "now" is what makes "last updated just now" true rather than assumed.
    test('snapshot stamps a fresh reading with the clock', () async {
      final result = await repository.snapshot(location);

      expect(result.valueOrNull?.fetchedAt, now);
      expect(result.valueOrNull?.age(clock), Duration.zero);
    });

    test('snapshot writes the reading to the cache', () async {
      await repository.snapshot(location);

      final captured = verify(
        () => cache.write(
          captureAny(),
          captureAny(),
          fetchedAt: captureAny(named: 'fetchedAt'),
        ),
      ).captured;
      expect(captured[0], location);
      expect((captured[1] as WeatherSnapshot).placeName, 'Cairo');
      expect(captured[2], now);
    });

    test('snapshot never reads the cache when the network answered', () async {
      await repository.snapshot(location);

      verifyNever(() => cache.read(any()));
    });

    // The user has the reading they asked for. All a rejected cache costs them
    // is the offline copy, which is not worth failing a successful fetch over.
    test('snapshot returns the reading when the cache write fails', () async {
      when(
        () => cache.write(any(), any(), fetchedAt: any(named: 'fetchedAt')),
      ).thenAnswer((_) async => const Err<void, AppFailure>(Unknown()));

      final result = await repository.snapshot(location);

      expect(result.isOk, isTrue);
      expect(result.valueOrNull?.value.placeName, 'Cairo');
    });

    test('snapshot sends the location query it was given', () async {
      await repository.snapshot(location);

      final captured = verify(
        () => api.forecast(
          query: captureAny(named: 'query'),
          lang: any(named: 'lang'),
        ),
      ).captured;
      expect(captured.single, 'Cairo');
    });

    test('snapshot sends the locale so condition text arrives '
        'translated', () async {
      await repository.snapshot(location, lang: 'ar');

      final captured = verify(
        () => api.forecast(
          query: any(named: 'query'),
          lang: captureAny(named: 'lang'),
        ),
      ).captured;
      expect(captured.single, 'ar');
    });
  });

  group('snapshot when the response cannot be mapped', () {
    test('snapshot returns Unknown when a timestamp changes shape', () async {
      answerForecast(
        Ok<ForecastResponseDto, AppFailure>(
          _cairoResponse((json) {
            (json['location']! as Map<String, dynamic>)['localtime'] = 'noon';
          }),
        ),
      );

      final result = await repository.snapshot(location);

      expect(result.failureOrNull, isA<Unknown>());
    });

    test('snapshot does not cache a reading it could not map', () async {
      answerForecast(
        Ok<ForecastResponseDto, AppFailure>(
          _cairoResponse((json) {
            (json['location']! as Map<String, dynamic>)['localtime'] = 'noon';
          }),
        ),
      );

      await repository.snapshot(location);

      verifyNever(
        () => cache.write(any(), any(), fetchedAt: any(named: 'fetchedAt')),
      );
    });
  });

  group('snapshot when the request never landed', () {
    final fetchedAt = now.subtract(const Duration(hours: 2));

    setUp(() {
      answerForecast(
        const Err<ForecastResponseDto, AppFailure>(NoConnection()),
      );
    });

    test('snapshot falls back to the cached reading', () async {
      final cached = Stale<WeatherSnapshot>(
        snapshotFromDto(_cairoResponse()),
        fetchedAt: fetchedAt,
      );
      when(() => cache.read(location)).thenAnswer(
        (_) async => Ok<Stale<WeatherSnapshot>, AppFailure>(cached),
      );

      final result = await repository.snapshot(location);

      expect(result.isOk, isTrue);
      expect(result.valueOrNull?.value.placeName, 'Cairo');
    });

    // This is what renders "Last updated 2h ago". A cached reading keeps the
    // moment it was fetched, never the moment it was read back.
    test('snapshot keeps the age the cached reading was stored with', () async {
      when(() => cache.read(location)).thenAnswer(
        (_) async => Ok<Stale<WeatherSnapshot>, AppFailure>(
          Stale<WeatherSnapshot>(
            snapshotFromDto(_cairoResponse()),
            fetchedAt: fetchedAt,
          ),
        ),
      );

      final result = await repository.snapshot(location);

      expect(result.valueOrNull?.fetchedAt, fetchedAt);
      expect(result.valueOrNull?.age(clock), const Duration(hours: 2));
    });

    // No connection is what the user can act on. "Nothing cached" describes how
    // the app tried to cope, and putting it on screen hides the real cause.
    test(
      'snapshot reports the network failure when nothing is cached',
      () async {
        when(() => cache.read(location)).thenAnswer(
          (_) async =>
              const Err<Stale<WeatherSnapshot>, AppFailure>(CacheMiss()),
        );

        final result = await repository.snapshot(location);

        expect(result.failureOrNull, isA<NoConnection>());
      },
    );

    test('snapshot reports the network failure when the cache itself '
        'fails', () async {
      when(() => cache.read(location)).thenAnswer(
        (_) async => const Err<Stale<WeatherSnapshot>, AppFailure>(Unknown()),
      );

      final result = await repository.snapshot(location);

      expect(result.failureOrNull, isA<NoConnection>());
    });

    test('snapshot asks the cache for the location it was given', () async {
      when(() => cache.read(any())).thenAnswer(
        (_) async => const Err<Stale<WeatherSnapshot>, AppFailure>(CacheMiss()),
      );

      await repository.snapshot(location);

      expect(verify(() => cache.read(captureAny())).captured.single, location);
    });
  });

  group('snapshot when the server gave a definite answer', () {
    for (final failure in _definiteFailures) {
      test('snapshot returns $failure unchanged', () async {
        answerForecast(Err<ForecastResponseDto, AppFailure>(failure));

        final result = await repository.snapshot(location);

        expect(result.failureOrNull, failure);
      });

      // Yesterday's weather over a spent quota or a rejected key would hide a
      // problem the user can do something about.
      test('snapshot does not fall back to the cache on $failure', () async {
        answerForecast(Err<ForecastResponseDto, AppFailure>(failure));

        await repository.snapshot(location);

        verifyNever(() => cache.read(any()));
      });
    }
  });

  group('search', () {
    void answerSearch(Result<List<SearchResultDto>, AppFailure> result) {
      when(() => api.search(any())).thenAnswer((_) async => result);
    }

    List<SearchResultDto> cairoMatches() => loadJsonArray(
      'search_cair',
    ).map((e) => SearchResultDto.fromJson(e as Map<String, dynamic>)).toList();

    test('search returns a suggestion per match', () async {
      answerSearch(Ok<List<SearchResultDto>, AppFailure>(cairoMatches()));

      final result = await repository.search('cair');

      expect(result.valueOrNull, hasLength(cairoMatches().length));
      expect(result.valueOrNull?.first.name, 'Cairo');
      expect(result.valueOrNull?.first.location.query, '30.05,31.25');
    });

    test('search sends the prefix it was given', () async {
      answerSearch(
        const Ok<List<SearchResultDto>, AppFailure>(
          <SearchResultDto>[],
        ),
      );

      await repository.search('cair');

      expect(verify(() => api.search(captureAny())).captured.single, 'cair');
    });

    // An empty box is a normal state of the search screen. Sending it spends a
    // request to be told `q` is missing, and shows the user an error for it.
    test('search answers a blank prefix without a request', () async {
      final result = await repository.search('   ');

      expect(result.valueOrNull, isEmpty);
      verifyNever(() => api.search(any()));
    });

    test('search returns an empty list when nothing matched', () async {
      answerSearch(
        const Ok<List<SearchResultDto>, AppFailure>(
          <SearchResultDto>[],
        ),
      );

      expect((await repository.search('zzzz')).valueOrNull, isEmpty);
    });

    test('search returns the failure unchanged', () async {
      answerSearch(
        const Err<List<SearchResultDto>, AppFailure>(RateLimited()),
      );

      expect(
        (await repository.search('cair')).failureOrNull,
        isA<RateLimited>(),
      );
    });

    test('search never touches the cache', () async {
      answerSearch(Ok<List<SearchResultDto>, AppFailure>(cairoMatches()));

      await repository.search('cair');

      verifyNever(() => cache.read(any()));
      verifyNever(
        () => cache.write(any(), any(), fetchedAt: any(named: 'fetchedAt')),
      );
    });
  });
}
