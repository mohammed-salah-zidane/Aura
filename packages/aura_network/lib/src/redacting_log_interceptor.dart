import 'package:dio/dio.dart';

/// Where a log line goes. Injected, so nothing in this package prints.
typedef LogSink = void Function(String message);

/// What a redacted query value is replaced with.
///
/// Letters only: the replacement goes back through URI encoding, and a
/// punctuation marker such as `***` would reach the log as `%2A%2A%2A`.
const String redactedValue = 'REDACTED';

/// Rewrites [uri] with the value of every key in [redactedKeys] replaced.
///
/// Repeated query parameters collapse to their first value, which is fine for
/// a log line and never for a request.
String redactQuery(Uri uri, Set<String> redactedKeys) {
  if (redactedKeys.isEmpty) return uri.toString();

  final parameters = Map<String, String>.of(uri.queryParameters);
  var redactedAny = false;
  for (final key in redactedKeys) {
    if (parameters.containsKey(key)) {
      parameters[key] = redactedValue;
      redactedAny = true;
    }
  }

  if (!redactedAny) return uri.toString();
  return uri.replace(queryParameters: parameters).toString();
}

/// Logs every request, response and error with the API key removed.
///
/// The key travels as a query parameter on every WeatherAPI call, so a naive
/// request log would write it to the device console on every refresh.
final class RedactingLogInterceptor extends Interceptor {
  /// Logs to [log], hiding the value of every key in [redactedKeys].
  RedactingLogInterceptor({required this.log, this.redactedKeys = const {}});

  /// Where log lines go.
  final LogSink log;

  /// Query parameter names whose values must never be logged.
  final Set<String> redactedKeys;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    log('→ ${options.method} ${redactQuery(options.uri, redactedKeys)}');
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    final uri = redactQuery(response.requestOptions.uri, redactedKeys);
    log('← ${response.statusCode} $uri');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final uri = redactQuery(err.requestOptions.uri, redactedKeys);
    log('✗ ${err.type.name} $uri');
    handler.next(err);
  }
}
