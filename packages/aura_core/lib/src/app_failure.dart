import 'package:meta/meta.dart';

/// Why an operation failed.
///
/// Sealed, so a `switch` that maps a failure to a localized message and a
/// recovery action is exhaustive and the analyzer catches a missing branch.
/// Failures are produced in one place, at the `aura_network` boundary, and
/// travel unchanged from there to the screen.
///
/// Two failures of the same variant are equal regardless of their [cause]:
/// the variant is the identity, and [cause] is diagnostic only.
@immutable
sealed class AppFailure {
  /// Const base constructor for every variant.
  const AppFailure({this.cause});

  /// The underlying error, kept so it can be logged.
  ///
  /// Never rendered. User-facing text comes from the variant, through the
  /// app's localizations.
  final Object? cause;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other.runtimeType == runtimeType;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    final name = switch (this) {
      NoConnection() => 'NoConnection',
      Timeout() => 'Timeout',
      InvalidCity() => 'InvalidCity',
      Unauthorized() => 'Unauthorized',
      RateLimited() => 'RateLimited',
      ServerError() => 'ServerError',
      CacheMiss() => 'CacheMiss',
      Unknown() => 'Unknown',
    };
    return cause == null ? name : '$name(cause: $cause)';
  }
}

/// The request never reached the server.
///
/// Derived from the request failing rather than from a connectivity API, which
/// reports "online" behind a captive portal. This is the failure that triggers
/// the cached fallback.
final class NoConnection extends AppFailure {
  /// Creates a [NoConnection] failure.
  const NoConnection({super.cause});
}

/// The request reached the server but no response arrived in time.
final class Timeout extends AppFailure {
  /// Creates a [Timeout] failure.
  const Timeout({super.cause});
}

/// The query matched no location. WeatherAPI code `1006`.
///
/// Arrives as HTTP 400, not 404, so the response body has to be parsed before
/// the status code is trusted.
final class InvalidCity extends AppFailure {
  /// Creates an [InvalidCity] failure.
  const InvalidCity({super.cause});
}

/// The API key is missing, invalid or disabled. WeatherAPI codes `1002`,
/// `2006` and `2008`.
final class Unauthorized extends AppFailure {
  /// Creates an [Unauthorized] failure.
  const Unauthorized({super.cause});
}

/// The monthly request quota is spent. WeatherAPI code `2007`.
final class RateLimited extends AppFailure {
  /// Creates a [RateLimited] failure.
  const RateLimited({super.cause});
}

/// The server answered with an error of its own. WeatherAPI code `9999`, or
/// any 5xx status.
final class ServerError extends AppFailure {
  /// Creates a [ServerError] failure.
  const ServerError({super.cause});
}

/// Nothing was cached for the requested location.
final class CacheMiss extends AppFailure {
  /// Creates a [CacheMiss] failure.
  const CacheMiss({super.cause});
}

/// A failure that does not fit any other variant, including the WeatherAPI
/// codes that signal a programming error rather than a user-visible one
/// (`1003` missing `q`, `1005` invalid URL).
final class Unknown extends AppFailure {
  /// Creates an [Unknown] failure.
  const Unknown({super.cause});
}
