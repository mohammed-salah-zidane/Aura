import 'package:meta/meta.dart';

/// Which place a screen is showing.
///
/// Carries equality because it identifies a provider and a cache row. Two
/// references to the same place must be the same key, or every screen fetches
/// its own copy.
@immutable
final class LocationRef {
  /// A reference to a named place.
  const LocationRef({required this.query, this.displayName});

  /// The device's approximate location, resolved by the service from the
  /// request's own address. Needs no location permission.
  const LocationRef.currentByIp() : query = 'auto:ip', displayName = null;

  /// A reference to a fixed pair of coordinates.
  factory LocationRef.coordinates({
    required double latitude,
    required double longitude,
    String? displayName,
  }) => LocationRef(
    query: '$latitude,$longitude',
    displayName: displayName,
  );

  /// What is sent as `q`. A city name, `lat,lon`, a postcode, an IATA code,
  /// or `auto:ip`.
  final String query;

  /// What to show while the real name is still loading. Null when unknown.
  final String? displayName;

  /// Whether this resolves the device's own location.
  bool get isCurrentLocation => query == 'auto:ip';

  /// Identity is the place asked for, never the label it wears.
  ///
  /// The same city arrives with a name from a search suggestion and without
  /// one from the saved list, and treating those as different places split
  /// the pager and refetched readings it already had.
  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is LocationRef && other.query == query);

  @override
  int get hashCode => query.hashCode;

  @override
  String toString() => 'LocationRef($query)';
}
