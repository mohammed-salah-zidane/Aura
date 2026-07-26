import 'package:aura_core/aura_core.dart';
import 'package:aura_network/src/api_error_body.dart';
import 'package:dio/dio.dart';

const int _unauthorized = 401;
const int _forbidden = 403;
const int _tooManyRequests = 429;
const int _lowestServerError = 500;

/// Maps a [DioException] onto the sealed [AppFailure] family.
///
/// The response body is read **before** the status code. A service can report
/// a specific, user-meaningful condition through its own error code while
/// answering with a generic 400, and the status alone cannot tell that apart
/// from a malformed request. [mapApiError] is what supplies that reading;
/// without it, or when it has no opinion, the status decides.
AppFailure failureFromDio(
  DioException error, {
  ApiErrorMapper? mapApiError,
}) {
  if (mapApiError != null) {
    final body = ApiErrorBody.tryParse(error.response?.data);
    if (body != null) {
      final mapped = mapApiError(body);
      if (mapped != null) return mapped;
    }
  }

  return switch (error.type) {
    DioExceptionType.connectionError => NoConnection(cause: error),
    // The handshake never completed, so nothing was fetched. Reporting it as
    // a lost connection is what lets the repository fall through to cache,
    // which is the only useful outcome available to the user.
    DioExceptionType.badCertificate => NoConnection(cause: error),
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout ||
    DioExceptionType.transformTimeout => Timeout(cause: error),
    DioExceptionType.badResponse => _fromStatus(error),
    DioExceptionType.cancel ||
    DioExceptionType.unknown => Unknown(cause: error),
  };
}

AppFailure _fromStatus(DioException error) {
  final status = error.response?.statusCode;
  return switch (status) {
    null => Unknown(cause: error),
    _unauthorized || _forbidden => Unauthorized(cause: error),
    _tooManyRequests => RateLimited(cause: error),
    >= _lowestServerError => ServerError(cause: error),
    _ => Unknown(cause: error),
  };
}
