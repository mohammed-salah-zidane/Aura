/// Configuration that arrives at compile time.
///
/// Read with `--dart-define-from-file=env/dev.json`, never from an asset. A
/// runtime `.env` file would ship the credential inside the app package, where
/// anyone who unzips it can read it. `String.fromEnvironment` is const, so the
/// value is baked into the binary and `env/` never has to be shipped at all.
///
/// `env/` is gitignored; `env/example.json` is committed as the shape to copy.
abstract final class AuraEnv {
  /// The WeatherAPI.com credential.
  ///
  /// Empty when nothing was defined, which is what a `flutter run` without the
  /// dart-define looks like. [isConfigured] is the check worth making.
  static const String weatherApiKey = String.fromEnvironment(
    'WEATHER_API_KEY',
  );

  /// The API root, or null to use the SDK's own.
  ///
  /// Only ever set to point a build at a local fake. The public root lives in
  /// `WeatherApi.defaultBaseUrl` and is not repeated here.
  static String? get weatherApiBaseUrl =>
      _weatherApiBaseUrl.isEmpty ? null : _weatherApiBaseUrl;

  /// Whether a credential was defined at build time.
  static bool get isConfigured => weatherApiKey.isNotEmpty;

  static const String _weatherApiBaseUrl = String.fromEnvironment(
    'WEATHER_API_BASE_URL',
  );
}
