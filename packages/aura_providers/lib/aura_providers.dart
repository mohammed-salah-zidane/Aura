/// The injection seams and the app-wide state every Aura feature shares.
///
/// A feature package cannot import the composition root, so the providers that
/// more than one feature needs cannot live there. Each port below is declared
/// here as a seam and implemented at the root, which is dependency inversion
/// expressed in the container: a feature only ever sees the domain interface.
///
/// Pure Dart. Nothing here touches a widget.
library;

export 'src/app_state.dart';
export 'src/location_refiner.dart';
export 'src/ports.dart';
export 'src/weather_feed.dart';
