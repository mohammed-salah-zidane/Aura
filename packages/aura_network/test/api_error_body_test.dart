import 'package:aura_network/aura_network.dart';
import 'package:test/test.dart';

void main() {
  group('tryParse on a decoded map', () {
    test('tryParse reads the code and message out of the envelope', () {
      final body = ApiErrorBody.tryParse(<String, Object?>{
        'error': <String, Object?>{
          'code': 1006,
          'message': 'No matching location found.',
        },
      });
      expect(body?.code, 1006);
      expect(body?.message, 'No matching location found.');
    });

    test('tryParse ignores sibling keys alongside the envelope', () {
      final body = ApiErrorBody.tryParse(<String, Object?>{
        'error': <String, Object?>{'code': 2007, 'message': 'quota'},
        'location': <String, Object?>{'name': 'Cairo'},
      });
      expect(body?.code, 2007);
    });
  });

  group('tryParse on a raw string', () {
    test('tryParse decodes a body the server sent without a JSON type', () {
      final body = ApiErrorBody.tryParse(
        '{"error":{"code":2006,"message":"API key is invalid."}}',
      );
      expect(body?.code, 2006);
      expect(body?.message, 'API key is invalid.');
    });

    test('tryParse returns null for a string that is not JSON', () {
      expect(ApiErrorBody.tryParse('<html>502 Bad Gateway</html>'), isNull);
    });

    test('tryParse returns null for truncated JSON', () {
      expect(ApiErrorBody.tryParse('{"error":{"code":1006,'), isNull);
    });
  });

  group('tryParse on a body that is not an envelope', () {
    test('tryParse returns null for null', () {
      expect(ApiErrorBody.tryParse(null), isNull);
    });

    test('tryParse returns null for a successful payload', () {
      expect(
        ApiErrorBody.tryParse(<String, Object?>{
          'location': <String, Object?>{'name': 'Cairo'},
        }),
        isNull,
      );
    });

    test('tryParse returns null when error is not a map', () {
      expect(
        ApiErrorBody.tryParse(<String, Object?>{'error': 'went wrong'}),
        isNull,
      );
    });

    test('tryParse returns null when the code is not an integer', () {
      expect(
        ApiErrorBody.tryParse(<String, Object?>{
          'error': <String, Object?>{'code': '1006', 'message': 'nope'},
        }),
        isNull,
      );
    });

    test('tryParse returns null when the message is missing', () {
      expect(
        ApiErrorBody.tryParse(<String, Object?>{
          'error': <String, Object?>{'code': 1006},
        }),
        isNull,
      );
    });

    test('tryParse returns null for a JSON array', () {
      expect(ApiErrorBody.tryParse(<Object?>[]), isNull);
    });
  });

  group('value semantics', () {
    test('== is true for the same code and message', () {
      expect(
        const ApiErrorBody(code: 1006, message: 'no match'),
        const ApiErrorBody(code: 1006, message: 'no match'),
      );
      expect(
        const ApiErrorBody(code: 1006, message: 'no match').hashCode,
        const ApiErrorBody(code: 1006, message: 'no match').hashCode,
      );
    });

    test('== is false for a different code', () {
      expect(
        const ApiErrorBody(code: 1006, message: 'no match'),
        isNot(const ApiErrorBody(code: 1005, message: 'no match')),
      );
    });

    test('toString names the code and the message', () {
      expect(
        const ApiErrorBody(code: 1006, message: 'no match').toString(),
        'ApiErrorBody(1006, no match)',
      );
    });
  });
}
