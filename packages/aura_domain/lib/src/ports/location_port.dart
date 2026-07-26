import 'package:aura_core/aura_core.dart';
import 'package:aura_domain/src/entities/location_ref.dart';

/// Whether the app may read the device's location.
enum LocationPermission {
  /// Never asked.
  notDetermined,

  /// The user allowed it.
  granted,

  /// The user refused it.
  denied,

  /// Refused and not askable again without a trip to system settings.
  permanentlyDenied,
}

/// Where the device's own position comes from.
///
/// The permission screen can be skipped, because the service resolves an
/// approximate location from the request itself. That path needs no
/// permission at all, which is what makes "Enter City Manually" a real
/// alternative rather than a dead end.
abstract interface class LocationPort {
  /// The current permission state, without asking for anything.
  Future<LocationPermission> permission();

  /// Asks for permission and reports what the user chose.
  Future<LocationPermission> request();

  /// The device's position, or a failure when it cannot be read.
  Future<Result<LocationRef, AppFailure>> currentPosition();
}
