import 'package:meta/meta.dart';

/// The atmospheric pressure units Aura can display.
///
/// The pressure card shows both at once, so this drives which one leads.
enum PressureUnit {
  /// Millibars, numerically identical to hectopascals. The unit the app stores.
  millibars,

  /// Inches of mercury.
  inchesOfMercury,
}

/// Hectopascals in one inch of mercury. 1 inHg is 3386.389 Pa by convention.
const double _millibarsPerInchOfMercury = 33.86389;

/// An atmospheric pressure, stored in millibars and converted on read.
@immutable
final class Pressure {
  /// A pressure of [millibars] mb.
  const Pressure.millibars(this.millibars);

  /// A pressure of [value] inHg.
  const Pressure.inchesOfMercury(double value)
    : millibars = value * _millibarsPerInchOfMercury;

  /// Millibars, the same number as hectopascals.
  final double millibars;

  /// Inches of mercury.
  double get inchesOfMercury => millibars / _millibarsPerInchOfMercury;

  /// This pressure expressed in [unit].
  double inUnit(PressureUnit unit) => switch (unit) {
    PressureUnit.millibars => millibars,
    PressureUnit.inchesOfMercury => inchesOfMercury,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Pressure && other.millibars == millibars);

  @override
  int get hashCode => millibars.hashCode;

  @override
  String toString() => 'Pressure.millibars($millibars)';
}
