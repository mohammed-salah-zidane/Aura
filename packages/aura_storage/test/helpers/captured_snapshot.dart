import 'dart:convert';
import 'dart:io';

import 'package:aura_data/aura_data.dart';
import 'package:aura_domain/aura_domain.dart';
import 'package:aura_weather_api/aura_weather_api.dart';

/// Builds a snapshot the way the app really builds one.
///
/// The cache exists to store what the mapper produces, so the round trip is
/// tested against exactly that: a live capture, decoded and mapped, with all
/// three days, 72 hours, air quality and any alerts intact. A hand-built entity
/// would only prove the codec agrees with whatever this file imagined.
///
/// [patch] edits the decoded response first, which is how a test reaches a
/// branch the capture does not contain: a polar day, a place with no alerts.
WeatherSnapshot capturedSnapshot(
  String fixture, {
  void Function(Map<String, dynamic> json)? patch,
}) {
  final json =
      jsonDecode(
            File(
              '../aura_weather_api/test/fixtures/$fixture.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>;
  patch?.call(json);
  return snapshotFromDto(ForecastResponseDto.fromJson(json));
}
