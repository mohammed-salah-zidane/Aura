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
export 'src/result.dart';
