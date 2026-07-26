/// The WeatherAPI.com SDK.
///
/// Endpoints and DTOs only. It returns the wire shape and never an entity,
/// which keeps the mapping into the domain an explicit, testable step
/// somewhere else.
library;

export 'src/dto/air_quality_dto.dart';
export 'src/dto/alert_dto.dart';
export 'src/dto/astro_dto.dart';
export 'src/dto/condition_dto.dart';
export 'src/dto/current_dto.dart';
export 'src/dto/current_response_dto.dart';
export 'src/dto/day_dto.dart';
export 'src/dto/forecast_day_dto.dart';
export 'src/dto/forecast_response_dto.dart';
export 'src/dto/hour_dto.dart';
export 'src/dto/location_dto.dart';
export 'src/dto/search_result_dto.dart';
export 'src/weather_api.dart';
export 'src/weather_api_failure.dart';
