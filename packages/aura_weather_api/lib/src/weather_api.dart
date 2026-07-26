import 'package:aura_core/aura_core.dart';
import 'package:aura_network/aura_network.dart';
import 'package:aura_weather_api/src/dto/current_response_dto.dart';
import 'package:aura_weather_api/src/dto/forecast_response_dto.dart';
import 'package:aura_weather_api/src/dto/search_result_dto.dart';
import 'package:aura_weather_api/src/weather_api_failure.dart';

/// The WeatherAPI.com endpoints Aura uses. Returns DTOs, never entities.
///
/// Deliberately not `final`: this is the seam the repository is tested against,
/// and a fake has to be able to implement it.
class WeatherApi {
  /// Wraps an already-configured network client.
  ///
  /// Use [WeatherApi.withKey] unless you are supplying a stub in a test.
  const WeatherApi(this._client);

  /// Builds the client WeatherAPI needs and wraps it.
  ///
  /// The credential travels as a query parameter on every request, so it is
  /// registered for redaction in the same breath as it is set.
  factory WeatherApi.withKey({
    required String apiKey,
    String baseUrl = defaultBaseUrl,
    LogSink? onLog,
  }) => WeatherApi(
    NetworkClient(
      baseUrl: baseUrl,
      defaultQuery: {_keyParameter: apiKey},
      redactedKeys: const {_keyParameter},
      mapApiError: weatherApiFailure,
      onLog: onLog,
    ),
  );

  /// The public API root.
  static const String defaultBaseUrl = 'https://api.weatherapi.com/v1';

  /// How many forecast days the free tier returns.
  ///
  /// Not a parameter on purpose. Asking for more returns three anyway, with
  /// HTTP 200 and no indication of the truncation, so a caller that passed 14
  /// would silently believe it had 14.
  static const int forecastDays = 3;

  static const String _keyParameter = 'key';

  final NetworkClient _client;

  /// The single call that feeds the home screen.
  ///
  /// [query] accepts a city name, `lat,lon`, a postcode, an IATA code, or
  /// `auto:ip` for an approximate location with no location permission.
  /// [lang] should be the active app locale, so `condition.text` arrives
  /// already translated instead of being translated locally.
  Future<Result<ForecastResponseDto, AppFailure>> forecast({
    required String query,
    String? lang,
  }) async {
    final response = await _client.getJson<Map<String, Object?>>(
      '/forecast.json',
      query: <String, Object?>{
        'q': query,
        'days': forecastDays,
        'aqi': 'yes',
        'alerts': 'yes',
        'lang': ?lang,
      },
    );
    return response.fold(
      (json) => _decode(json, ForecastResponseDto.fromJson),
      Err<ForecastResponseDto, AppFailure>.new,
    );
  }

  /// City autocomplete for the search screen.
  Future<Result<List<SearchResultDto>, AppFailure>> search(
    String prefix,
  ) async {
    final response = await _client.getJson<List<Object?>>(
      '/search.json',
      query: <String, Object?>{'q': prefix},
    );
    return response.fold(
      (json) => _decodeList(json, SearchResultDto.fromJson),
      Err<List<SearchResultDto>, AppFailure>.new,
    );
  }

  /// The reading for one place, without a forecast.
  ///
  /// Used for the temperature beside a search result and for each saved city,
  /// where pulling a full forecast would spend quota on data nothing shows.
  Future<Result<CurrentResponseDto, AppFailure>> current({
    required String query,
    String? lang,
  }) async {
    final response = await _client.getJson<Map<String, Object?>>(
      '/current.json',
      query: <String, Object?>{
        'q': query,
        'lang': ?lang,
      },
    );
    return response.fold(
      (json) => _decode(json, CurrentResponseDto.fromJson),
      Err<CurrentResponseDto, AppFailure>.new,
    );
  }
}

/// Decoding is the last place an exception could escape this layer.
///
/// A field WeatherAPI renames or drops would otherwise throw a cast error out
/// of a DTO constructor and past every `Result` in the call chain.
Result<T, AppFailure> _decode<T>(
  Map<String, Object?> json,
  T Function(Map<String, dynamic> json) fromJson,
) {
  try {
    return Ok<T, AppFailure>(fromJson(json));
  } on Object catch (error) {
    return Err<T, AppFailure>(Unknown(cause: error));
  }
}

Result<List<T>, AppFailure> _decodeList<T>(
  List<Object?> json,
  T Function(Map<String, dynamic> json) fromJson,
) {
  try {
    final decoded = <T>[];
    for (final entry in json) {
      if (entry is! Map<String, dynamic>) {
        return const Err<Never, AppFailure>(
          Unknown(cause: 'a list entry was not a JSON object'),
        );
      }
      decoded.add(fromJson(entry));
    }
    return Ok<List<T>, AppFailure>(decoded);
  } on Object catch (error) {
    return Err<List<T>, AppFailure>(Unknown(cause: error));
  }
}
