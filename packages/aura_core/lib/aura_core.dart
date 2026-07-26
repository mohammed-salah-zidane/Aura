/// The shared kernel.
///
/// Types every layer needs and no layer owns: the `Result` returned across
/// every boundary, the sealed `AppFailure` it carries, the `Clock` that makes
/// time injectable, `Stale` for a cached read, and the unit value objects that
/// keep a Celsius reading from being rendered as Fahrenheit.
///
/// Pure Dart. No Flutter, no infrastructure.
library;

export 'src/app_failure.dart';
export 'src/clock.dart';
export 'src/result.dart';
export 'src/stale.dart';
export 'src/units/distance.dart';
export 'src/units/precipitation.dart';
export 'src/units/pressure.dart';
export 'src/units/speed.dart';
export 'src/units/temperature.dart';
