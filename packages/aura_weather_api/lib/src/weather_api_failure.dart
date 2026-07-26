import 'package:aura_core/aura_core.dart';
import 'package:aura_network/aura_network.dart';

/// WeatherAPI's own error codes, verified against the live service.
///
/// Only this package knows them. The transport asks for a reading and falls
/// back to the HTTP status when there is none, which keeps `aura_network` a
/// general client.
abstract final class WeatherApiErrorCode {
  /// API key not provided. Arrives as HTTP 401.
  static const int keyMissing = 1002;

  /// The `q` parameter is missing. Arrives as HTTP 400.
  static const int queryMissing = 1003;

  /// The request URL is invalid. Arrives as HTTP 400.
  static const int invalidUrl = 1005;

  /// No location matched `q`. Arrives as HTTP **400**, not 404.
  static const int noMatchingLocation = 1006;

  /// The API key is not valid. Arrives as HTTP 401.
  static const int keyInvalid = 2006;

  /// The monthly quota is spent. Arrives as HTTP 403.
  static const int quotaExceeded = 2007;

  /// The API key has been disabled. Arrives as HTTP 403.
  static const int keyDisabled = 2008;

  /// An internal error at WeatherAPI. Arrives as HTTP 400.
  static const int internalError = 9999;
}

/// Reads a WeatherAPI error code as an [AppFailure].
///
/// Returns null for a code this table does not know, which leaves the HTTP
/// status to decide rather than mislabelling something new.
AppFailure? weatherApiFailure(ApiErrorBody body) => switch (body.code) {
  WeatherApiErrorCode.noMatchingLocation => InvalidCity(cause: body),
  WeatherApiErrorCode.keyMissing ||
  WeatherApiErrorCode.keyInvalid ||
  WeatherApiErrorCode.keyDisabled => Unauthorized(cause: body),
  WeatherApiErrorCode.quotaExceeded => RateLimited(cause: body),
  WeatherApiErrorCode.internalError => ServerError(cause: body),
  // A missing q or a malformed URL is a bug in this app, not something the
  // user did. It gets the generic failure, never "city not found".
  WeatherApiErrorCode.queryMissing ||
  WeatherApiErrorCode.invalidUrl => Unknown(cause: body),
  _ => null,
};
