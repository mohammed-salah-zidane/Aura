import 'package:aura_domain/aura_domain.dart';
import 'package:aura_providers/src/ports.dart';
import 'package:riverpod/riverpod.dart';

/// Which place every screen is currently showing.
///
/// Kept here rather than in a route path: a [LocationRef] is a query and a
/// display name, not a slug, and search and saved cities both set it while
/// home and the four detail screens read it.
final activeLocationProvider = NotifierProvider<ActiveLocation, LocationRef>(
  ActiveLocation.new,
);

/// Holds the place the app is showing.
final class ActiveLocation extends Notifier<LocationRef> {
  /// Starts on the device's approximate position, which needs no permission.
  @override
  LocationRef build() => const LocationRef.currentByIp();

  /// The place on screen.
  LocationRef get location => state;

  /// Shows this place from now on.
  set location(LocationRef location) => state = location;
}

/// The device's precise position, once a fix has landed.
///
/// Held apart from [activeLocationProvider] on purpose. "Current location" is
/// one identity across the app: the pager's first page, the saved list's
/// first row and the active place all name the same symbolic reference, and
/// the fix only changes what that reference resolves to. Making the fix a
/// different place broke that: pages stopped matching rows the moment the
/// coordinates arrived.
final devicePositionProvider = NotifierProvider<DevicePosition, LocationRef?>(
  DevicePosition.new,
);

/// Holds the fix the current-location pages resolve to. Null until one lands.
final class DevicePosition extends Notifier<LocationRef?> {
  @override
  LocationRef? build() => null;

  /// The fix, or null while none has landed.
  LocationRef? get position => state;

  /// Records a fix.
  set position(LocationRef position) => state = position;
}

/// The language every request carries as `lang`.
///
/// WeatherAPI returns `condition.text` already translated, so the language is
/// part of what a reading *is*: changing it has to fetch again rather than
/// re-render. Defaults to English until the composition root reports what
/// `Localizations` resolved, which happens before any screen asks for weather.
final languageProvider = NotifierProvider<ActiveLanguage, String>(
  ActiveLanguage.new,
);

/// Holds the language tag requests are made in.
final class ActiveLanguage extends Notifier<String> {
  @override
  String build() => 'en';

  /// The language tag requests carry.
  String get tag => state;

  /// Makes this the language of every request from now on.
  set tag(String tag) => state = tag;
}

/// The units the whole app renders in.
final unitPreferencesProvider =
    AsyncNotifierProvider<UnitPreferencesController, UnitPreferences>(
      UnitPreferencesController.new,
    );

/// Reads and writes the stored units.
final class UnitPreferencesController extends AsyncNotifier<UnitPreferences> {
  @override
  Future<UnitPreferences> build() async {
    final stored = await ref.watch(settingsPortProvider).readUnits();
    // Storage that cannot be read is not a reason to refuse to draw a
    // temperature. The defaults are the ones a first run gets.
    return stored.fold((units) => units, (_) => const UnitPreferences());
  }

  /// Stores [units] and applies them everywhere at once.
  ///
  /// The screen updates before the write lands. Units are the user's own
  /// choice rather than a fact about the world, so echoing the tap is honest,
  /// and a rejected write costs them the choice next launch and nothing now.
  Future<void> select(UnitPreferences units) async {
    state = AsyncData<UnitPreferences>(units);
    await ref.read(settingsPortProvider).writeUnits(units);
  }
}

/// Which notifications the user has switched on.
final notificationPreferencesProvider =
    AsyncNotifierProvider<
      NotificationPreferencesController,
      NotificationPreferences
    >(NotificationPreferencesController.new);

/// Reads and writes the stored notification choices.
final class NotificationPreferencesController
    extends AsyncNotifier<NotificationPreferences> {
  @override
  Future<NotificationPreferences> build() async {
    final stored = await ref.watch(settingsPortProvider).readNotifications();
    return stored.fold(
      (preferences) => preferences,
      (_) => const NotificationPreferences(),
    );
  }

  /// Stores [preferences].
  Future<void> select(NotificationPreferences preferences) async {
    state = AsyncData<NotificationPreferences>(preferences);
    await ref.read(settingsPortProvider).writeNotifications(preferences);
  }
}

/// The cities the user has kept, oldest first.
///
/// Search adds to this list and the saved cities screen reads and removes from
/// it, so it is app-wide state rather than either feature's own.
final savedCitiesProvider =
    AsyncNotifierProvider<SavedCitiesController, List<SavedCity>>(
      SavedCitiesController.new,
    );

/// Reads and edits the kept cities.
final class SavedCitiesController extends AsyncNotifier<List<SavedCity>> {
  @override
  Future<List<SavedCity>> build() async {
    final stored = await ref.watch(savedCitiesPortProvider).readAll();
    return stored.fold((cities) => cities, (_) => const <SavedCity>[]);
  }

  /// Keeps [city]. Adding one that is already saved changes nothing.
  Future<void> add(SavedCity city) async {
    final result = await ref.read(savedCitiesPortProvider).add(city);
    if (result.isOk) ref.invalidateSelf();
  }

  /// Forgets whatever is saved for [location].
  Future<void> remove(LocationRef location) async {
    final result = await ref.read(savedCitiesPortProvider).remove(location);
    if (result.isOk) ref.invalidateSelf();
  }
}
