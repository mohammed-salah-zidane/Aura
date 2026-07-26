// package:test exports its own Timeout, which shadows the AppFailure variant.
import 'package:aura_core/aura_core.dart';
import 'package:aura_network/aura_network.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart' hide Timeout;

final _options = RequestOptions(path: '/forecast.json');

DioException _withStatus(int status, {Object? body}) =>
    DioException.badResponse(
      statusCode: status,
      requestOptions: _options,
      response: Response<Object?>(
        requestOptions: _options,
        statusCode: status,
        data: body,
      ),
    );

void main() {
  group('transport failures', () {
    test('failureFromDio maps connectionError to NoConnection', () {
      final error = DioException.connectionError(
        requestOptions: _options,
        reason: 'no route to host',
      );
      expect(failureFromDio(error), const NoConnection());
    });

    test('failureFromDio maps badCertificate to NoConnection', () {
      final error = DioException.badCertificate(requestOptions: _options);
      expect(failureFromDio(error), const NoConnection());
    });

    test('failureFromDio maps connectionTimeout to Timeout', () {
      final error = DioException.connectionTimeout(
        timeout: const Duration(seconds: 10),
        requestOptions: _options,
      );
      expect(failureFromDio(error), const Timeout());
    });

    test('failureFromDio maps sendTimeout to Timeout', () {
      final error = DioException.sendTimeout(
        timeout: const Duration(seconds: 10),
        requestOptions: _options,
      );
      expect(failureFromDio(error), const Timeout());
    });

    test('failureFromDio maps receiveTimeout to Timeout', () {
      final error = DioException.receiveTimeout(
        timeout: const Duration(seconds: 15),
        requestOptions: _options,
      );
      expect(failureFromDio(error), const Timeout());
    });

    test('failureFromDio maps transformTimeout to Timeout', () {
      final error = DioException.transformTimeout(
        timeout: const Duration(seconds: 15),
        requestOptions: _options,
      );
      expect(failureFromDio(error), const Timeout());
    });

    test('failureFromDio maps a cancelled request to Unknown', () {
      final error = DioException.requestCancelled(
        requestOptions: _options,
        reason: 'user left the screen',
      );
      expect(failureFromDio(error), const Unknown());
    });

    test('failureFromDio keeps the DioException as the cause', () {
      final error = DioException.connectionError(
        requestOptions: _options,
        reason: 'no route to host',
      );
      expect(failureFromDio(error).cause, same(error));
    });
  });

  group('status codes', () {
    test('failureFromDio maps 401 to Unauthorized', () {
      expect(failureFromDio(_withStatus(401)), const Unauthorized());
    });

    test('failureFromDio maps 403 to Unauthorized without a body code', () {
      expect(failureFromDio(_withStatus(403)), const Unauthorized());
    });

    test('failureFromDio maps 429 to RateLimited', () {
      expect(failureFromDio(_withStatus(429)), const RateLimited());
    });

    test('failureFromDio maps 500 to ServerError', () {
      expect(failureFromDio(_withStatus(500)), const ServerError());
    });

    test('failureFromDio maps 503 to ServerError', () {
      expect(failureFromDio(_withStatus(503)), const ServerError());
    });

    test('failureFromDio maps a bare 400 to Unknown', () {
      expect(failureFromDio(_withStatus(400)), const Unknown());
    });

    test('failureFromDio maps 404 to Unknown', () {
      expect(failureFromDio(_withStatus(404)), const Unknown());
    });

    test('failureFromDio maps a badResponse with no status to Unknown', () {
      final error = DioException(
        type: DioExceptionType.badResponse,
        requestOptions: _options,
      );
      expect(failureFromDio(error), const Unknown());
    });
  });

  group('the injected api error mapper', () {
    // The reason the mapper exists: 1006 arrives as HTTP 400, which is
    // indistinguishable from a malformed request by status alone.
    test('failureFromDio prefers the mapper over the status code', () {
      final error = _withStatus(
        400,
        body: <String, Object?>{
          'error': <String, Object?>{'code': 1006, 'message': 'no match'},
        },
      );
      final failure = failureFromDio(
        error,
        mapApiError: (body) => body.code == 1006 ? const InvalidCity() : null,
      );
      expect(failure, const InvalidCity());
    });

    test(
      'failureFromDio falls back to the status when the mapper abstains',
      () {
        final error = _withStatus(
          403,
          body: <String, Object?>{
            'error': <String, Object?>{'code': 9998, 'message': 'unheard of'},
          },
        );
        expect(
          failureFromDio(error, mapApiError: (body) => null),
          const Unauthorized(),
        );
      },
    );

    test('failureFromDio ignores the mapper when there is no envelope', () {
      var mapperRan = false;
      final failure = failureFromDio(
        _withStatus(500, body: 'gateway exploded'),
        mapApiError: (body) {
          mapperRan = true;
          return const InvalidCity();
        },
      );
      expect(mapperRan, isFalse);
      expect(failure, const ServerError());
    });

    test('failureFromDio uses the status when no mapper is given', () {
      final error = _withStatus(
        400,
        body: <String, Object?>{
          'error': <String, Object?>{'code': 1006, 'message': 'no match'},
        },
      );
      expect(failureFromDio(error), const Unknown());
    });
  });
}
