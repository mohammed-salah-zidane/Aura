// package:test exports its own Timeout, which shadows the AppFailure variant.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:aura_core/aura_core.dart';
import 'package:aura_network/aura_network.dart';
import 'package:aura_weather_api/aura_weather_api.dart';
import 'package:dio/dio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart' hide Timeout;

class _MockAdapter extends Mock implements HttpClientAdapter {}

class _FakeRequestOptions extends Fake implements RequestOptions {}

const String _key = 'test-key-not-a-real-credential';

String _fixture(String name) =>
    File('test/fixtures/$name.json').readAsStringSync();

void main() {
  late _MockAdapter adapter;
  RequestOptions? capturedRequest;

  setUpAll(() => registerFallbackValue(_FakeRequestOptions()));

  setUp(() {
    adapter = _MockAdapter();
    capturedRequest = null;
  });

  WeatherApi apiUnder() => WeatherApi(
    NetworkClient(
      baseUrl: WeatherApi.defaultBaseUrl,
      defaultQuery: const {'key': _key},
      redactedKeys: const {'key'},
      mapApiError: weatherApiFailure,
      retryBackoff: Duration.zero,
      dio: Dio()..httpClientAdapter = adapter,
    ),
  );

  void answerWith(String body, [int status = 200]) {
    when(() => adapter.fetch(any(), any(), any())).thenAnswer(
      (_) async => ResponseBody(
        Stream<Uint8List>.value(Uint8List.fromList(utf8.encode(body))),
        status,
        headers: <String, List<String>>{
          Headers.contentTypeHeader: <String>[Headers.jsonContentType],
        },
      ),
    );
  }

  // Memoised: verify consumes the recorded calls, so a second call would find
  // nothing and fail with a misleading "no matching calls".
  RequestOptions sentRequest() => capturedRequest ??=
      verify(() => adapter.fetch(captureAny(), any(), any())).captured.first
          as RequestOptions;

  group('forecast', () {
    test('forecast decodes a real response into a DTO', () async {
      answerWith(_fixture('forecast_cairo'));

      final result = await apiUnder().forecast(query: 'Cairo');

      expect(result.valueOrNull?.location.name, 'Cairo');
      expect(result.valueOrNull?.forecast.forecastday, hasLength(3));
    });

    test('forecast asks for aqi and alerts in the same call', () async {
      answerWith(_fixture('forecast_cairo'));

      await apiUnder().forecast(query: 'Cairo');

      final query = sentRequest().uri.queryParameters;
      expect(query['aqi'], 'yes');
      expect(query['alerts'], 'yes');
    });

    // Asking for more returns three anyway, with HTTP 200 and no sign of the
    // truncation, so the request never asks for more.
    test('forecast never asks for more than three days', () async {
      answerWith(_fixture('forecast_cairo'));

      await apiUnder().forecast(query: 'Cairo');

      expect(sentRequest().uri.queryParameters['days'], '3');
    });

    test('forecast sends the query it was given', () async {
      answerWith(_fixture('forecast_cairo'));

      await apiUnder().forecast(query: 'auto:ip');

      expect(sentRequest().uri.queryParameters['q'], 'auto:ip');
    });

    test('forecast sends lang when a locale is given', () async {
      answerWith(_fixture('forecast_cairo'));

      await apiUnder().forecast(query: 'Cairo', lang: 'ar');

      expect(sentRequest().uri.queryParameters['lang'], 'ar');
    });

    test('forecast omits lang when none is given', () async {
      answerWith(_fixture('forecast_cairo'));

      await apiUnder().forecast(query: 'Cairo');

      expect(sentRequest().uri.queryParameters.containsKey('lang'), isFalse);
    });

    // One request feeds the whole home screen. astronomy.json in particular
    // is never called, because astro already sits inside forecastday.
    test('forecast calls forecast.json exactly once', () async {
      answerWith(_fixture('forecast_cairo'));

      await apiUnder().forecast(query: 'Cairo');

      final requests = verify(
        () => adapter.fetch(captureAny(), any(), any()),
      ).captured.cast<RequestOptions>();
      expect(requests, hasLength(1));
      expect(requests.single.uri.path, endsWith('/forecast.json'));
    });
  });

  group('forecast failures', () {
    // 1006 arrives as HTTP 400, so only the body can identify it.
    test('forecast returns InvalidCity for code 1006', () async {
      answerWith(_fixture('error_1006'), 400);

      final result = await apiUnder().forecast(query: 'zzzzqqqxx');

      expect(result.failureOrNull, const InvalidCity());
    });

    test('forecast returns Unauthorized for code 2006', () async {
      answerWith('{"error":{"code":2006,"message":"key invalid"}}', 401);

      final result = await apiUnder().forecast(query: 'Cairo');

      expect(result.failureOrNull, const Unauthorized());
    });

    test('forecast returns RateLimited for code 2007', () async {
      answerWith('{"error":{"code":2007,"message":"quota exceeded"}}', 403);

      final result = await apiUnder().forecast(query: 'Cairo');

      expect(result.failureOrNull, const RateLimited());
    });

    test('forecast returns NoConnection when nothing lands', () async {
      when(() => adapter.fetch(any(), any(), any())).thenThrow(
        DioException.connectionError(
          requestOptions: RequestOptions(path: '/forecast.json'),
          reason: 'offline',
        ),
      );

      final result = await apiUnder().forecast(query: 'Cairo');

      expect(result.failureOrNull, const NoConnection());
    });

    // A decode error is the last place an exception could escape this layer.
    test('forecast returns Unknown when a field is missing', () async {
      final broken =
          jsonDecode(_fixture('forecast_cairo')) as Map<String, dynamic>
            ..remove('current');
      answerWith(jsonEncode(broken));

      final result = await apiUnder().forecast(query: 'Cairo');

      expect(result.failureOrNull, const Unknown());
    });

    test('forecast returns Unknown when the body is an array', () async {
      answerWith('[]');

      final result = await apiUnder().forecast(query: 'Cairo');

      expect(result.failureOrNull, const Unknown());
    });
  });

  group('search', () {
    test('search decodes a real response into DTOs', () async {
      answerWith(_fixture('search_cair'));

      final result = await apiUnder().search('cair');

      expect(result.valueOrNull, hasLength(3));
      expect(result.valueOrNull?.first.name, 'Cairo');
    });

    test('search sends the prefix it was given', () async {
      answerWith(_fixture('search_cair'));

      await apiUnder().search('cair');

      expect(sentRequest().uri.path, endsWith('/search.json'));
      expect(sentRequest().uri.queryParameters['q'], 'cair');
    });

    test('search returns an empty list when nothing matches', () async {
      answerWith('[]');

      final result = await apiUnder().search('zzzzqqqxx');

      expect(result.valueOrNull, isEmpty);
    });

    test('search returns Unknown when an entry is not an object', () async {
      answerWith('["Cairo"]');

      final result = await apiUnder().search('cair');

      expect(result.failureOrNull, const Unknown());
    });

    test('search returns Unknown when the body is an object', () async {
      answerWith('{"error":"nope"}');

      final result = await apiUnder().search('cair');

      expect(result.failureOrNull, const Unknown());
    });
  });

  group('current', () {
    test('current calls current.json without forecast parameters', () async {
      final forecast =
          jsonDecode(_fixture('forecast_cairo')) as Map<String, dynamic>;
      answerWith(
        jsonEncode(<String, dynamic>{
          'location': forecast['location'],
          'current': forecast['current'],
        }),
      );

      final result = await apiUnder().current(query: 'Cairo');

      expect(result.valueOrNull?.location.name, 'Cairo');
      final query = sentRequest().uri.queryParameters;
      expect(query.containsKey('days'), isFalse);
      expect(query.containsKey('alerts'), isFalse);
    });

    test('current sends lang when a locale is given', () async {
      final forecast =
          jsonDecode(_fixture('forecast_cairo')) as Map<String, dynamic>;
      answerWith(
        jsonEncode(<String, dynamic>{
          'location': forecast['location'],
          'current': forecast['current'],
        }),
      );

      await apiUnder().current(query: 'Cairo', lang: 'ar');

      expect(sentRequest().uri.queryParameters['lang'], 'ar');
    });
  });

  group('the assembled client', () {
    // withKey builds its own Dio, so the stub adapter cannot reach inside it.
    // These drive an identically configured client instead, and prove the two
    // behaviours the assembly exists to provide: the credential travels on
    // every request, and it never reaches a log line.
    NetworkClient assembled(LogSink? onLog) => NetworkClient(
      baseUrl: WeatherApi.defaultBaseUrl,
      defaultQuery: const {'key': _key},
      redactedKeys: const {'key'},
      mapApiError: weatherApiFailure,
      onLog: onLog,
      dio: Dio()..httpClientAdapter = adapter,
    );

    test('the credential travels on every request', () async {
      answerWith(_fixture('forecast_cairo'));

      await WeatherApi(assembled(null)).forecast(query: 'Cairo');

      expect(sentRequest().uri.queryParameters['key'], _key);
    });

    test('the credential never reaches a log line', () async {
      final lines = <String>[];
      answerWith(_fixture('forecast_cairo'));

      await WeatherApi(assembled(lines.add)).forecast(query: 'Cairo');

      expect(lines, isNotEmpty);
      expect(lines.join('\n'), isNot(contains(_key)));
      expect(lines.join('\n'), contains('key=$redactedValue'));
    });

    test('withKey points at the public api root', () {
      expect(WeatherApi.defaultBaseUrl, 'https://api.weatherapi.com/v1');
      expect(WeatherApi.withKey(apiKey: _key), isA<WeatherApi>());
    });
  });
}
