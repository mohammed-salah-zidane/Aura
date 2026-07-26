import 'package:aura_core/aura_core.dart';
import 'package:aura_domain/aura_domain.dart';
// Geolocator publishes a LocationPermission of its own, which would shadow the
// domain's.
import 'package:geolocator/geolocator.dart' as geo;

/// Reads the device's position through Geolocator.
///
/// A platform adapter rather than storage, so it lives beside the providers in
/// the composition root and is injected into the port every feature sees.
final class DeviceLocation implements LocationPort {
  /// Creates the adapter.
  const DeviceLocation();

  /// How long to wait for a fix before giving up.
  ///
  /// A first fix indoors can take a long time, and the app has a working
  /// alternative in `q=auto:ip`, so it is better to fall back than to hold the
  /// screen.
  static const Duration _timeLimit = Duration(seconds: 12);

  /// Geolocator does not distinguish "never asked" from "asked and refused":
  /// both arrive as `denied`. Before asking, that means the prompt has not been
  /// answered yet, which is [LocationPermission.notDetermined].
  @override
  Future<LocationPermission> permission() async =>
      switch (await geo.Geolocator.checkPermission()) {
        geo.LocationPermission.always ||
        geo.LocationPermission.whileInUse => LocationPermission.granted,
        geo.LocationPermission.deniedForever =>
          LocationPermission.permanentlyDenied,
        geo.LocationPermission.denied ||
        geo.LocationPermission.unableToDetermine =>
          LocationPermission.notDetermined,
      };

  /// After the prompt has been answered, the same `denied` means the user has
  /// just refused.
  @override
  Future<LocationPermission> request() async =>
      switch (await geo.Geolocator.requestPermission()) {
        geo.LocationPermission.always ||
        geo.LocationPermission.whileInUse => LocationPermission.granted,
        geo.LocationPermission.deniedForever =>
          LocationPermission.permanentlyDenied,
        geo.LocationPermission.denied => LocationPermission.denied,
        geo.LocationPermission.unableToDetermine =>
          LocationPermission.notDetermined,
      };

  @override
  Future<Result<LocationRef, AppFailure>> currentPosition() async {
    try {
      if (!await geo.Geolocator.isLocationServiceEnabled()) {
        return const Err<LocationRef, AppFailure>(Unknown());
      }
      final position = await geo.Geolocator.getCurrentPosition(
        locationSettings: const geo.LocationSettings(
          // The forecast is for a place, not a street corner. Medium accuracy
          // answers faster and costs less battery, and the service resolves
          // the reading to a named place either way.
          accuracy: geo.LocationAccuracy.medium,
          timeLimit: _timeLimit,
        ),
      );
      return Ok<LocationRef, AppFailure>(
        LocationRef.coordinates(
          latitude: position.latitude,
          longitude: position.longitude,
        ),
      );
    } on Object catch (error) {
      // Geolocator throws for a refused permission, a disabled service and a
      // timed-out fix alike. None of them is recoverable here, and all of them
      // leave `q=auto:ip` as the way forward.
      return Err<LocationRef, AppFailure>(Unknown(cause: error));
    }
  }
}
