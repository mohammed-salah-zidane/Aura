import 'dart:convert';
import 'dart:typed_data';

import 'package:aura_network/aura_network.dart';
import 'package:dio/dio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockAdapter extends Mock implements HttpClientAdapter {}

class _FakeRequestOptions extends Fake implements RequestOptions {}

const String _key = 'test-key-not-a-real-credential';

Uri _uri(String query) =>
    Uri.parse('https://api.example.test/v1/f.json?$query');

void main() {
  group('redactQuery', () {
    test('redactQuery replaces the value of a named key', () {
      final redacted = redactQuery(_uri('key=$_key&q=Cairo'), {'key'});
      expect(redacted, contains('key=$redactedValue'));
      expect(redacted, isNot(contains(_key)));
    });

    test('redactQuery keeps every other parameter intact', () {
      final redacted = redactQuery(
        _uri('key=$_key&q=Cairo&days=3&aqi=yes'),
        {'key'},
      );
      expect(redacted, contains('q=Cairo'));
      expect(redacted, contains('days=3'));
      expect(redacted, contains('aqi=yes'));
    });

    test('redactQuery redacts every named key', () {
      final redacted = redactQuery(
        _uri('key=$_key&token=abc&q=Cairo'),
        {'key', 'token'},
      );
      expect(redacted, isNot(contains(_key)));
      expect(redacted, isNot(contains('abc')));
    });

    test('redactQuery leaves a uri without the key untouched', () {
      final uri = _uri('q=Cairo');
      expect(redactQuery(uri, {'key'}), uri.toString());
    });

    test('redactQuery leaves a uri with no query untouched', () {
      final uri = Uri.parse('https://api.example.test/v1/f.json');
      expect(redactQuery(uri, {'key'}), uri.toString());
    });

    test('redactQuery returns the uri unchanged when no keys are named', () {
      final uri = _uri('key=$_key');
      expect(redactQuery(uri, const {}), uri.toString());
    });
  });

  // The hooks are driven through a real Dio rather than called directly:
  // ErrorInterceptorHandler.next signals by throwing an InterceptorState, so a
  // bare handler outside a pipeline cannot stand in for one inside it.
  group('RedactingLogInterceptor in a pipeline', () {
    late _MockAdapter adapter;
    late List<String> lines;
    late Dio dio;

    setUpAll(() => registerFallbackValue(_FakeRequestOptions()));

    setUp(() {
      adapter = _MockAdapter();
      lines = <String>[];
      dio =
          Dio(
              BaseOptions(
                baseUrl: 'https://api.example.test/v1',
                queryParameters: <String, Object?>{'key': _key},
              ),
            )
            ..httpClientAdapter = adapter
            ..interceptors.add(
              RedactingLogInterceptor(
                log: lines.add,
                redactedKeys: const {'key'},
              ),
            );
    });

    void answer(int status) {
      when(() => adapter.fetch(any(), any(), any())).thenAnswer(
        (_) async => ResponseBody(
          Stream<Uint8List>.value(Uint8List.fromList(utf8.encode('{}'))),
          status,
          headers: <String, List<String>>{
            Headers.contentTypeHeader: <String>[Headers.jsonContentType],
          },
        ),
      );
    }

    test('a successful call logs the request and the response', () async {
      answer(200);

      await dio.get<Object?>(
        '/forecast.json',
        queryParameters: <String, Object?>{'q': 'Cairo'},
      );

      expect(lines, hasLength(2));
      expect(lines.first, startsWith('→ GET'));
      expect(lines.last, startsWith('← 200'));
    });

    test('a successful call keeps the key out of both lines', () async {
      answer(200);

      await dio.get<Object?>('/forecast.json');

      expect(lines.join('\n'), isNot(contains(_key)));
      expect(lines.join('\n'), contains('key=$redactedValue'));
    });

    test('a request logs the query parameters that are not secret', () async {
      answer(200);

      await dio.get<Object?>(
        '/forecast.json',
        queryParameters: <String, Object?>{'q': 'Cairo', 'days': 3},
      );

      expect(lines.first, contains('q=Cairo'));
      expect(lines.first, contains('days=3'));
    });

    test('a failing call logs the failure type without the key', () async {
      when(() => adapter.fetch(any(), any(), any())).thenThrow(
        DioException.connectionError(
          requestOptions: RequestOptions(path: '/forecast.json'),
          reason: 'no route',
        ),
      );

      await expectLater(
        dio.get<Object?>('/forecast.json'),
        throwsA(isA<DioException>()),
      );

      expect(lines.last, startsWith('✗ connectionError'));
      expect(lines.join('\n'), isNot(contains(_key)));
    });
  });
}
