// package:test exports its own Timeout, which shadows the AppFailure variant.
import 'package:aura_core/aura_core.dart';
import 'package:aura_network/aura_network.dart';
import 'package:aura_weather_api/aura_weather_api.dart';
import 'package:test/test.dart' hide Timeout;

ApiErrorBody _body(int code) =>
    ApiErrorBody(code: code, message: 'message for $code');

/// Every row of the error table in docs/WEATHER_API.md.
const List<(int code, String meaning)> _table = <(int, String)>[
  (1002, 'API key not provided'),
  (1003, 'q missing'),
  (1005, 'invalid request url'),
  (1006, 'no matching location'),
  (2006, 'API key invalid'),
  (2007, 'monthly quota exceeded'),
  (2008, 'API key disabled'),
  (9999, 'internal error'),
];

void main() {
  group('the documented error codes', () {
    test('weatherApiFailure maps 1002 to Unauthorized', () {
      expect(weatherApiFailure(_body(1002)), const Unauthorized());
    });

    test('weatherApiFailure maps 1003 to Unknown', () {
      expect(weatherApiFailure(_body(1003)), const Unknown());
    });

    test('weatherApiFailure maps 1005 to Unknown', () {
      expect(weatherApiFailure(_body(1005)), const Unknown());
    });

    test('weatherApiFailure maps 1006 to InvalidCity', () {
      expect(weatherApiFailure(_body(1006)), const InvalidCity());
    });

    test('weatherApiFailure maps 2006 to Unauthorized', () {
      expect(weatherApiFailure(_body(2006)), const Unauthorized());
    });

    test('weatherApiFailure maps 2007 to RateLimited', () {
      expect(weatherApiFailure(_body(2007)), const RateLimited());
    });

    test('weatherApiFailure maps 2008 to Unauthorized', () {
      expect(weatherApiFailure(_body(2008)), const Unauthorized());
    });

    test('weatherApiFailure maps 9999 to ServerError', () {
      expect(weatherApiFailure(_body(9999)), const ServerError());
    });

    test('weatherApiFailure has an answer for every documented code', () {
      for (final (code, meaning) in _table) {
        expect(weatherApiFailure(_body(code)), isNotNull, reason: meaning);
      }
    });
  });

  group('codes outside the table', () {
    // Abstaining leaves the HTTP status to decide, which is safer than
    // guessing a meaning for a code WeatherAPI added after this was written.
    test('weatherApiFailure abstains on an unknown code', () {
      expect(weatherApiFailure(_body(1234)), isNull);
    });

    test('weatherApiFailure abstains on a code near a known one', () {
      expect(weatherApiFailure(_body(1007)), isNull);
      expect(weatherApiFailure(_body(2005)), isNull);
    });
  });

  group('the failure carries its cause', () {
    test('weatherApiFailure keeps the body for logging', () {
      final body = _body(1006);
      expect(weatherApiFailure(body)?.cause, same(body));
    });
  });

  group('the code constants match the documented values', () {
    test('every named code equals the number the service sends', () {
      expect(WeatherApiErrorCode.keyMissing, 1002);
      expect(WeatherApiErrorCode.queryMissing, 1003);
      expect(WeatherApiErrorCode.invalidUrl, 1005);
      expect(WeatherApiErrorCode.noMatchingLocation, 1006);
      expect(WeatherApiErrorCode.keyInvalid, 2006);
      expect(WeatherApiErrorCode.quotaExceeded, 2007);
      expect(WeatherApiErrorCode.keyDisabled, 2008);
      expect(WeatherApiErrorCode.internalError, 9999);
    });
  });
}
