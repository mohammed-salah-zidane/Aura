/// HTTP transport for Aura.
///
/// A general JSON GET client, a redacting log interceptor, and the one place
/// where a transport error becomes an `AppFailure`. It knows nothing about
/// weather: the base URL, the credential and the meaning of any
/// service-specific error code are all injected.
library;

export 'src/api_error_body.dart';
export 'src/network_client.dart';
export 'src/network_failure.dart';
export 'src/redacting_log_interceptor.dart';
