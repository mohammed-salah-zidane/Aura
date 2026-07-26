/// The data layer.
///
/// Implements the domain's weather port and owns the one translation between
/// the wire shape and the entities: `aura_weather_api` hands back DTOs, this
/// package hands the domain entities, and nothing in between leaks either way.
///
/// Pure Dart. The storage ports it composes are implemented elsewhere and
/// injected, which is what keeps a repository testable with no Flutter binding.
library;

export 'src/mappers/weather_mappers.dart';
export 'src/weather_repository_impl.dart';
