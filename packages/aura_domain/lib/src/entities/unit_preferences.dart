import 'package:aura_core/aura_core.dart';
import 'package:meta/meta.dart';

/// Which units the whole app renders in.
///
/// The settings screen offers exactly these three, which is what the design
/// specifies. Pressure and visibility have no toggle: the design shows
/// pressure in both units at once and visibility in kilometres.
@immutable
final class UnitPreferences {
  /// Creates a set of preferences.
  const UnitPreferences({
    this.temperature = TemperatureUnit.celsius,
    this.speed = SpeedUnit.kilometersPerHour,
    this.precipitation = PrecipitationUnit.millimeters,
  });

  /// The temperature scale.
  final TemperatureUnit temperature;

  /// The wind speed unit.
  final SpeedUnit speed;

  /// The precipitation unit.
  final PrecipitationUnit precipitation;

  /// A copy with the named fields replaced.
  UnitPreferences copyWith({
    TemperatureUnit? temperature,
    SpeedUnit? speed,
    PrecipitationUnit? precipitation,
  }) => UnitPreferences(
    temperature: temperature ?? this.temperature,
    speed: speed ?? this.speed,
    precipitation: precipitation ?? this.precipitation,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UnitPreferences &&
          other.temperature == temperature &&
          other.speed == speed &&
          other.precipitation == precipitation);

  @override
  int get hashCode => Object.hash(temperature, speed, precipitation);
}
