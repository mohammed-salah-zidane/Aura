import 'package:aura/src/aura_env.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // The test harness runs without --dart-define-from-file, which is exactly
  // the shape of a build somebody forgot to configure. These assertions pin
  // what that build does: it reports itself unconfigured rather than sending
  // an empty credential and getting a confusing 401 back.
  group('a build with no dart-define', () {
    test('weatherApiKey is empty', () {
      expect(AuraEnv.weatherApiKey, isEmpty);
    });

    test('isConfigured is false', () {
      expect(AuraEnv.isConfigured, isFalse);
    });

    test('weatherApiBaseUrl defers to the SDK', () {
      expect(AuraEnv.weatherApiBaseUrl, isNull);
    });
  });
}
