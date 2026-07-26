import 'package:meta/meta.dart';

/// The temperature scales Aura can display.
enum TemperatureUnit {
  /// Degrees Celsius. The default, and the scale the app stores.
  celsius,

  /// Degrees Fahrenheit.
  fahrenheit,
}

/// A temperature, stored in Celsius and converted on read.
///
/// Entities hold one of these rather than a bare `double`, so a Celsius value
/// can never be rendered as if it were Fahrenheit. The conversion lives here
/// and nowhere else.
@immutable
final class Temperature {
  /// A temperature of [celsius] degrees Celsius.
  const Temperature.celsius(this.celsius);

  /// A temperature of [degrees] degrees Fahrenheit.
  const Temperature.fahrenheit(double degrees)
    : celsius = (degrees - 32) * 5 / 9;

  /// Degrees Celsius.
  final double celsius;

  /// Degrees Fahrenheit.
  double get fahrenheit => celsius * 9 / 5 + 32;

  /// This temperature expressed in [unit].
  double inUnit(TemperatureUnit unit) => switch (unit) {
    TemperatureUnit.celsius => celsius,
    TemperatureUnit.fahrenheit => fahrenheit,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Temperature && other.celsius == celsius);

  @override
  int get hashCode => celsius.hashCode;

  @override
  String toString() => 'Temperature.celsius($celsius)';
}
