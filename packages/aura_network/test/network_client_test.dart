// package:test exports its own Timeout, which shadows the AppFailure variant.
import 'dart:convert';
import 'dart:typed_data';

import 'package:aura_core/aura_core.dart';
import 'package:aura_network/aura_network.dart';
import 'package:dio/dio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart' hide Timeout;

class _MockAdapter extends Mock implements HttpClientAdapter {}

class _FakeRequestOptions extends Fake implements RequestOptions {}

const String _baseUrl = 'https://api.example.test/v1';
const String _key = '6f27a7b9512c4882a45162444252101';

void main() {
  late _MockAdapter adapter;

  setUpAll(() => registerFallbackValue(_FakeRequestOptions()));

  setUp(() {
    adapter = _MockAdapter();
  });

  NetworkClient clientUnder({
    ApiErrorMapper? mapApiError,
    int maxAttempts = NetworkClient.defaultMaxAttempts,
    LogSink? onLog,
  }) => NetworkClient(
    baseUrl: _baseUrl,
    defaultQuery: const {'key': _key},
    redactedKeys: const {'key'},
    maxAttempts: maxAttempts,
    // Zero, so a retry test does not spend the real backoff.
    retryBackoff: Duration.zero,
    mapApiError: mapApiError,
    onLog: onLog,
    dio: Dio()..httpClientAdapter = adapter,
  );

  // Built fresh per call: ResponseBody wraps a single-subscription stream, so
  // reusing one instance makes the second attempt of a retry fail with
  // "Stream has already been listened to" instead of the real outcome.
  ResponseBody json(String body, int status) => ResponseBody(
    Stream<Uint8List>.value(Uint8List.fromList(utf8.encode(body))),
    status,
    headers: <String, List<String>>{
      Headers.contentTypeHeader: <String>[Headers.jsonContentType],
    },
  );

  void answerWith(String body, int status) {
    when(
      () => adapter.fetch(any(), any(), any()),
    ).thenAnswer((_) async => json(body, status));
  }

  void answerInTurn(List<(String body, int status)> replies) {
    var call = 0;
    when(() => adapter.fetch(any(), any(), any())).thenAnswer((_) async {
      final (body, status) = replies[call.clamp(0, replies.length - 1)];
      call++;
      return json(body, status);
    });
  }

  void throwOnFetch(Object error) {
    when(() => adapter.fetch(any(), any(), any())).thenThrow(error);
  }

  // verify consumes the recorded calls, so each of these may be called once
  // per test and never both.
  RequestOptions captureRequest() =>
      verify(() => adapter.fetch(captureAny(), any(), any())).captured.first
          as RequestOptions;

  int fetchCount() =>
      verify(() => adapter.fetch(any(), any(), any())).callCount;

  group('a successful response', () {
    test('getJson returns the decoded object', () async {
      answerWith('{"location":{"name":"Cairo"}}', 200);

      final result = await clientUnder().getJson<Map<String, Object?>>(
        '/forecast.json',
      );

      expect(result.isOk, isTrue);
      expect(result.valueOrNull?['location'], <String, Object?>{
        'name': 'Cairo',
      });
    });

    test('getJson returns the decoded array for a list endpoint', () async {
      answerWith('[{"name":"Cairo"},{"name":"Cairns"}]', 200);

      final result = await clientUnder().getJson<List<Object?>>(
        '/search.json',
        query: const {'q': 'cair'},
      );

      expect(result.valueOrNull, hasLength(2));
    });

    test('getJson sends the default query on every request', () async {
      answerWith('{}', 200);

      await clientUnder().getJson<Map<String, Object?>>(
        '/forecast.json',
        query: const {'q': 'Cairo', 'days': 3},
      );

      final sent = captureRequest();
      expect(sent.uri.queryParameters['key'], _key);
      expect(sent.uri.queryParameters['q'], 'Cairo');
      expect(sent.uri.queryParameters['days'], '3');
    });

    test('getJson resolves the path against the base url', () async {
      answerWith('{}', 200);

      await clientUnder().getJson<Map<String, Object?>>('/forecast.json');

      final sent = captureRequest();
      expect(sent.uri.toString(), startsWith(_baseUrl));
      expect(sent.uri.path, endsWith('/forecast.json'));
    });

    test('getJson sends exactly one request when it succeeds', () async {
      answerWith('{}', 200);
      await clientUnder().getJson<Map<String, Object?>>('/forecast.json');
      expect(fetchCount(), 1);
    });
  });

  group('a body that is not the promised shape', () {
    test('getJson fails with Unknown when an object was expected', () async {
      answerWith('[1,2,3]', 200);

      final result = await clientUnder().getJson<Map<String, Object?>>(
        '/forecast.json',
      );

      expect(result.failureOrNull, const Unknown());
    });

    test('getJson fails with Unknown when an array was expected', () async {
      answerWith('{"name":"Cairo"}', 200);

      final result = await clientUnder().getJson<List<Object?>>(
        '/search.json',
      );

      expect(result.failureOrNull, const Unknown());
    });

    test('getJson fails with Unknown for a body that is not JSON', () async {
      answerWith('<html>gateway</html>', 200);

      final result = await clientUnder().getJson<Map<String, Object?>>(
        '/forecast.json',
      );

      expect(result.failureOrNull, const Unknown());
    });

    test('getJson does not retry a shape mismatch', () async {
      answerWith('[1,2,3]', 200);
      await clientUnder().getJson<Map<String, Object?>>('/forecast.json');
      expect(fetchCount(), 1);
    });
  });

  group('transport failures become values, never exceptions', () {
    test('getJson returns NoConnection when the connection fails', () async {
      throwOnFetch(
        DioException.connectionError(
          requestOptions: RequestOptions(path: '/forecast.json'),
          reason: 'no route to host',
        ),
      );

      final result = await clientUnder().getJson<Map<String, Object?>>(
        '/forecast.json',
      );

      expect(result.failureOrNull, const NoConnection());
    });

    test('getJson returns Timeout when the connection times out', () async {
      throwOnFetch(
        DioException.connectionTimeout(
          timeout: const Duration(seconds: 10),
          requestOptions: RequestOptions(path: '/forecast.json'),
        ),
      );

      final result = await clientUnder().getJson<Map<String, Object?>>(
        '/forecast.json',
      );

      expect(result.failureOrNull, const Timeout());
    });

    test('getJson returns Unauthorized on 401', () async {
      answerWith('{"error":{"code":2006,"message":"invalid"}}', 401);

      final result = await clientUnder().getJson<Map<String, Object?>>(
        '/forecast.json',
      );

      expect(result.failureOrNull, const Unauthorized());
    });

    test('getJson returns ServerError on 500', () async {
      answerWith('{}', 500);

      final result = await clientUnder().getJson<Map<String, Object?>>(
        '/forecast.json',
      );

      expect(result.failureOrNull, const ServerError());
    });
  });

  group('the injected api error mapper', () {
    // 1006 arrives as HTTP 400. Without reading the body first, it is
    // indistinguishable from a malformed request.
    test('getJson reads the body code ahead of the 400 status', () async {
      answerWith('{"error":{"code":1006,"message":"no match"}}', 400);

      final result = await clientUnder(
        mapApiError: (body) => body.code == 1006 ? const InvalidCity() : null,
      ).getJson<Map<String, Object?>>('/forecast.json');

      expect(result.failureOrNull, const InvalidCity());
    });

    test('getJson falls back to the status without a mapper', () async {
      answerWith('{"error":{"code":1006,"message":"no match"}}', 400);

      final result = await clientUnder().getJson<Map<String, Object?>>(
        '/forecast.json',
      );

      expect(result.failureOrNull, const Unknown());
    });
  });

  group('retry', () {
    test('getJson retries a 500 and returns the later success', () async {
      answerInTurn([('{}', 500), ('{"ok":true}', 200)]);

      final result = await clientUnder().getJson<Map<String, Object?>>(
        '/forecast.json',
      );

      expect(result.valueOrNull, <String, Object?>{'ok': true});
      expect(fetchCount(), 2);
    });

    test('getJson gives up after maxAttempts and returns it', () async {
      answerWith('{}', 500);

      final result = await clientUnder().getJson<Map<String, Object?>>(
        '/forecast.json',
      );

      expect(result.failureOrNull, const ServerError());
      expect(fetchCount(), NetworkClient.defaultMaxAttempts);
    });

    test('getJson retries a timeout', () async {
      throwOnFetch(
        DioException.receiveTimeout(
          timeout: const Duration(seconds: 15),
          requestOptions: RequestOptions(path: '/forecast.json'),
        ),
      );

      final result = await clientUnder(
        maxAttempts: 2,
      ).getJson<Map<String, Object?>>('/forecast.json');

      expect(result.failureOrNull, const Timeout());
      expect(fetchCount(), 2);
    });

    // Retrying it would delay the cached fallback for a request that is not
    // going to succeed.
    test('getJson does not retry NoConnection', () async {
      throwOnFetch(
        DioException.connectionError(
          requestOptions: RequestOptions(path: '/forecast.json'),
          reason: 'offline',
        ),
      );

      await clientUnder().getJson<Map<String, Object?>>('/forecast.json');

      expect(fetchCount(), 1);
    });

    test('getJson does not retry an authorization failure', () async {
      answerWith('{}', 401);
      await clientUnder().getJson<Map<String, Object?>>('/forecast.json');
      expect(fetchCount(), 1);
    });

    test('getJson sends once when maxAttempts is one', () async {
      answerWith('{}', 500);
      await clientUnder(maxAttempts: 1).getJson<Map<String, Object?>>('/f');
      expect(fetchCount(), 1);
    });
  });

  group('logging', () {
    test('getJson logs the request and response without the key', () async {
      answerWith('{}', 200);
      final lines = <String>[];

      await clientUnder(
        onLog: lines.add,
      ).getJson<Map<String, Object?>>('/forecast.json', query: {'q': 'Cairo'});

      expect(lines, hasLength(2));
      expect(lines.join('\n'), contains('q=Cairo'));
      expect(lines.join('\n'), isNot(contains(_key)));
    });

    test('getJson logs a failure without the key', () async {
      answerWith('{}', 500);
      final lines = <String>[];

      await clientUnder(
        maxAttempts: 1,
        onLog: lines.add,
      ).getJson<Map<String, Object?>>('/forecast.json');

      expect(lines.join('\n'), contains('badResponse'));
      expect(lines.join('\n'), isNot(contains(_key)));
    });

    test('getJson stays silent when no sink is given', () async {
      answerWith('{}', 200);
      final result = await clientUnder().getJson<Map<String, Object?>>('/f');
      expect(result.isOk, isTrue);
    });
  });
}
