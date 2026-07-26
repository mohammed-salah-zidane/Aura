/// The widget-test harness every Aura feature shares.
///
/// Loading five font families and pumping at the design canvas is the same
/// work in every feature's suite, and a copy per package is a copy per package
/// to keep in step. It lives here so there is one.
library;

export 'src/pump_screen.dart';
