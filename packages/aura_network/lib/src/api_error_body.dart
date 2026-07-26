import 'dart:convert';

import 'package:aura_core/aura_core.dart';
import 'package:meta/meta.dart';

/// A parsed `{"error": {"code": …, "message": …}}` response body.
///
/// The shape is common enough to belong to the transport layer. What the
/// codes *mean* is not: this module never interprets one. An API-specific
/// module supplies that reading through an [ApiErrorMapper].
@immutable
final class ApiErrorBody {
  /// Creates a body with the given [code] and [message].
  const ApiErrorBody({required this.code, required this.message});

  /// The service's own error code.
  final int code;

  /// The service's own message. Diagnostic, never shown to a user.
  final String message;

  /// Reads [body] as an error envelope, or returns null if it is not one.
  ///
  /// Accepts a decoded map or the raw string, because a server that answers
  /// an error without a JSON content type leaves the body undecoded.
  static ApiErrorBody? tryParse(Object? body) {
    final decoded = body is String ? _tryDecode(body) : body;
    if (decoded is! Map<Object?, Object?>) return null;

    final error = decoded['error'];
    if (error is! Map<Object?, Object?>) return null;

    final code = error['code'];
    final message = error['message'];
    if (code is! int || message is! String) return null;

    return ApiErrorBody(code: code, message: message);
  }

  static Object? _tryDecode(String body) {
    try {
      return jsonDecode(body);
    } on FormatException {
      return null;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ApiErrorBody && other.code == code && other.message == message);

  @override
  int get hashCode => Object.hash(code, message);

  @override
  String toString() => 'ApiErrorBody($code, $message)';
}

/// Turns a service's own error code into an [AppFailure].
///
/// Supplied by the module that knows the service. Returning null means "no
/// opinion", and the transport falls back to reading the HTTP status.
typedef ApiErrorMapper = AppFailure? Function(ApiErrorBody body);
