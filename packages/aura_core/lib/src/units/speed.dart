import 'package:meta/meta.dart';

/// The wind speed units Aura can display.
enum SpeedUnit {
  /// Kilometres per hour. The default, and the unit the app stores.
  kilometersPerHour,

  /// Miles per hour.
  milesPerHour,
}

/// Kilometres in one international mile, by definition.
const double _kilometersPerMile = 1.609344;

/// A speed, stored in kilometres per hour and converted on read.
@immutable
final class Speed {
  /// A speed of [kilometersPerHour] km/h.
  const Speed.kilometersPerHour(this.kilometersPerHour);

  /// A speed of [value] mph.
  const Speed.milesPerHour(double value)
    : kilometersPerHour = value * _kilometersPerMile;

  /// Kilometres per hour.
  final double kilometersPerHour;

  /// Miles per hour.
  double get milesPerHour => kilometersPerHour / _kilometersPerMile;

  /// This speed expressed in [unit].
  double inUnit(SpeedUnit unit) => switch (unit) {
    SpeedUnit.kilometersPerHour => kilometersPerHour,
    SpeedUnit.milesPerHour => milesPerHour,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Speed && other.kilometersPerHour == kilometersPerHour);

  @override
  int get hashCode => kilometersPerHour.hashCode;

  @override
  String toString() => 'Speed.kilometersPerHour($kilometersPerHour)';
}
