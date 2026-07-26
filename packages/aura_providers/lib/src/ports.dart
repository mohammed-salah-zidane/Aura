import 'package:aura_core/aura_core.dart';
import 'package:aura_domain/aura_domain.dart';
import 'package:riverpod/riverpod.dart';

/// Thrown when a port is read from a container that never supplied one.
///
/// Every port below is a declaration, not an implementation: the composition
/// root decides what satisfies it, and a test decides separately. Reaching one
/// with neither in place is a wiring mistake, and this says which.
Never _missing(String port) => throw StateError(
  '$port has no implementation. Override it in the ProviderScope at the '
  'composition root, or in the test that needs it.',
);

/// The source of "now". Nothing anywhere else calls `DateTime.now()`.
///
/// The only port with a default, because the real clock is not infrastructure:
/// it needs no credential, no database and no platform channel.
final clockProvider = Provider<Clock>((ref) => const SystemClock());

/// Where weather comes from, as far as every screen is concerned.
final weatherRepositoryProvider = Provider<WeatherRepository>(
  (ref) => _missing('weatherRepositoryProvider'),
);

/// Where the user's own choices are kept.
final settingsPortProvider = Provider<SettingsPort>(
  (ref) => _missing('settingsPortProvider'),
);

/// Where the user's kept cities are stored.
final savedCitiesPortProvider = Provider<SavedCitiesPort>(
  (ref) => _missing('savedCitiesPortProvider'),
);

/// Where the device's own position comes from.
final locationPortProvider = Provider<LocationPort>(
  (ref) => _missing('locationPortProvider'),
);

/// Where notifications are scheduled.
final notificationPortProvider = Provider<NotificationPort>(
  (ref) => _missing('notificationPortProvider'),
);
