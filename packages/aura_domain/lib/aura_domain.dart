/// The domain.
///
/// Entities, the ports the outside world implements, and the derived values
/// the screens render. Pure Dart: no Flutter, no HTTP, no database.
///
/// The derived values are the highest-value surface here. Each one is a
/// published scale or a piece of arithmetic over a field WeatherAPI returns,
/// with no authored prose anywhere.
library;

export 'src/derived/air_quality_scales.dart';
export 'src/derived/aura_condition.dart';
export 'src/derived/hourly_window.dart';
export 'src/derived/moon_phase.dart';
export 'src/derived/range_bar_geometry.dart';
export 'src/derived/sun_geometry.dart';
export 'src/derived/uv_band.dart';
export 'src/entities/air_quality.dart';
export 'src/entities/astro_info.dart';
export 'src/entities/current_conditions.dart';
export 'src/entities/forecast_day.dart';
export 'src/entities/hourly_point.dart';
export 'src/entities/location_ref.dart';
export 'src/entities/saved_city.dart';
export 'src/entities/unit_preferences.dart';
export 'src/entities/weather_alert.dart';
export 'src/entities/weather_snapshot.dart';
export 'src/ports/location_port.dart';
export 'src/ports/notification_port.dart';
export 'src/ports/saved_cities_port.dart';
export 'src/ports/settings_port.dart';
export 'src/ports/weather_cache_port.dart';
export 'src/ports/weather_repository.dart';
