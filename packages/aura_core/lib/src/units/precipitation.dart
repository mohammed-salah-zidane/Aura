import 'package:meta/meta.dart';

/// The precipitation units Aura can display.
enum PrecipitationUnit {
  /// Millimetres. The default, and the unit the app stores.
  millimeters,

  /// Inches.
  inches,
}

/// Millimetres in one inch, by definition.
const double _millimetersPerInch = 25.4;

/// A depth of precipitation, stored in millimetres and converted on read.
@immutable
final class Precipitation {
  /// A depth of [millimeters] mm.
  const Precipitation.millimeters(this.millimeters);

  /// A depth of [value] inches.
  const Precipitation.inches(double value)
    : millimeters = value * _millimetersPerInch;

  /// Millimetres.
  final double millimeters;

  /// Inches.
  double get inches => millimeters / _millimetersPerInch;

  /// This depth expressed in [unit].
  double inUnit(PrecipitationUnit unit) => switch (unit) {
    PrecipitationUnit.millimeters => millimeters,
    PrecipitationUnit.inches => inches,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Precipitation && other.millimeters == millimeters);

  @override
  int get hashCode => millimeters.hashCode;

  @override
  String toString() => 'Precipitation.millimeters($millimeters)';
}
