import 'package:aura_core/aura_core.dart';

/// Runs [action] and turns anything it throws into a failure.
///
/// Storage is the last layer that can still throw: a full disk, a revoked
/// keychain entry, a database locked by another isolate. None of them are
/// something the user did, so they all carry the generic variant, with the
/// cause kept for the log and never for the screen.
Future<Result<T, AppFailure>> guarded<T>(Future<T> Function() action) async {
  try {
    return Ok<T, AppFailure>(await action());
  } on Object catch (error) {
    return Err<T, AppFailure>(Unknown(cause: error));
  }
}
