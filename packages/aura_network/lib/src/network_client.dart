import 'package:aura_core/aura_core.dart';
import 'package:aura_network/src/api_error_body.dart';
import 'package:aura_network/src/network_failure.dart';
import 'package:aura_network/src/redacting_log_interceptor.dart';
import 'package:dio/dio.dart';

/// A JSON GET client that returns failures as values.
///
/// Weather-agnostic on purpose: the base URL, the credential and the reading
/// of any service-specific error code all arrive through the constructor, so
/// this module carries no knowledge of the API it happens to be pointed at.
///
/// No exception escapes [getJson]. Every path out is a `Result`.
final class NetworkClient {
  /// Creates a client against [baseUrl].
  ///
  /// [defaultQuery] is sent with every request, which is where a credential
  /// passed as a query parameter belongs. Name that parameter in
  /// [redactedKeys] so it never reaches a log line.
  ///
  /// [dio] exists for tests, which swap in a stub adapter. Production code
  /// leaves it null.
  NetworkClient({
    required String baseUrl,
    Map<String, String> defaultQuery = const {},
    Set<String> redactedKeys = const {},
    Duration connectTimeout = defaultConnectTimeout,
    Duration receiveTimeout = defaultReceiveTimeout,
    this.maxAttempts = defaultMaxAttempts,
    this.retryBackoff = defaultRetryBackoff,
    this.mapApiError,
    LogSink? onLog,
    Dio? dio,
  }) : _dio = dio ?? Dio() {
    _dio.options = BaseOptions(
      baseUrl: baseUrl,
      queryParameters: defaultQuery,
      connectTimeout: connectTimeout,
      receiveTimeout: receiveTimeout,
      sendTimeout: connectTimeout,
    );
    if (onLog != null) {
      _dio.interceptors.add(
        RedactingLogInterceptor(log: onLog, redactedKeys: redactedKeys),
      );
    }
  }

  /// How long to wait for the connection to open.
  static const Duration defaultConnectTimeout = Duration(seconds: 10);

  /// How long to wait for the response once the connection is open.
  static const Duration defaultReceiveTimeout = Duration(seconds: 15);

  /// How many times a request is sent before its failure is returned.
  static const int defaultMaxAttempts = 3;

  /// The base wait before a retry. It grows with the attempt number.
  static const Duration defaultRetryBackoff = Duration(milliseconds: 400);

  /// How many times a request is sent before its failure is returned.
  final int maxAttempts;

  /// The base wait before a retry, multiplied by the attempt number.
  final Duration retryBackoff;

  /// Reads a service's own error code, if this client was given one.
  final ApiErrorMapper? mapApiError;

  final Dio _dio;

  /// GETs [path] and returns the decoded body as [T].
  ///
  /// [T] is the JSON shape the endpoint promises: a `Map<String, Object?>`
  /// for an object, a `List<Object?>` for an array. A body that decodes to
  /// anything else is an `Unknown` failure rather than a cast that throws
  /// somewhere later.
  Future<Result<T, AppFailure>> getJson<T extends Object>(
    String path, {
    Map<String, Object?> query = const {},
  }) async {
    for (var attempt = 1; ; attempt++) {
      try {
        final response = await _dio.get<Object?>(path, queryParameters: query);
        final data = response.data;
        if (data is T) return Ok<T, AppFailure>(data);
        return Err<T, AppFailure>(
          Unknown(cause: 'GET $path returned an unexpected JSON shape'),
        );
      } on DioException catch (error) {
        final failure = failureFromDio(error, mapApiError: mapApiError);
        if (attempt >= maxAttempts || !_isRetryable(failure)) {
          return Err<T, AppFailure>(failure);
        }
        await Future<void>.delayed(retryBackoff * attempt);
      }
    }
  }

  /// Whether sending the same request again could plausibly succeed.
  ///
  /// `NoConnection` is deliberately absent. Retrying it delays the cached
  /// fallback by the whole backoff for a request that is not going to
  /// succeed, and falling back to cache immediately is the better answer.
  static bool _isRetryable(AppFailure failure) => switch (failure) {
    Timeout() || ServerError() => true,
    NoConnection() ||
    InvalidCity() ||
    Unauthorized() ||
    RateLimited() ||
    CacheMiss() ||
    Unknown() => false,
  };
}
