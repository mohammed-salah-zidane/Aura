import 'package:aura_domain/src/entities/location_ref.dart';
import 'package:meta/meta.dart';

/// A place the user has kept.
///
/// Carries only what the saved list needs to exist. The reading beside each
/// row is fetched separately, so removing a city never depends on its weather
/// having loaded.
@immutable
final class SavedCity {
  /// Creates a saved city.
  const SavedCity({
    required this.location,
    required this.name,
    required this.country,
    required this.addedAt,
  });

  /// How to ask the service about it.
  final LocationRef location;

  /// Its name, as the user saw it when they added it.
  final String name;

  /// Its country.
  final String country;

  /// When it was added. Orders the list.
  final DateTime addedAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SavedCity && other.location == location);

  @override
  int get hashCode => location.hashCode;

  @override
  String toString() => 'SavedCity($name)';
}
