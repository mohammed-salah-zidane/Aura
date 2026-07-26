import 'package:meta/meta.dart';

/// The distance units Aura can display. Used for visibility.
enum DistanceUnit {
  /// Kilometres. The default, and the unit the app stores.
  kilometers,

  /// Miles.
  miles,
}

/// Kilometres in one international mile, by definition.
const double _kilometersPerMile = 1.609344;

/// A distance, stored in kilometres and converted on read.
@immutable
final class Distance {
  /// A distance of [kilometers] km.
  const Distance.kilometers(this.kilometers);

  /// A distance of [value] miles.
  const Distance.miles(double value) : kilometers = value * _kilometersPerMile;

  /// Kilometres.
  final double kilometers;

  /// Miles.
  double get miles => kilometers / _kilometersPerMile;

  /// This distance expressed in [unit].
  double inUnit(DistanceUnit unit) => switch (unit) {
    DistanceUnit.kilometers => kilometers,
    DistanceUnit.miles => miles,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Distance && other.kilometers == kilometers);

  @override
  int get hashCode => kilometers.hashCode;

  @override
  String toString() => 'Distance.kilometers($kilometers)';
}
