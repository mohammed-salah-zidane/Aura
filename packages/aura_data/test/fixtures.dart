import 'dart:convert';
import 'dart:io';

/// Loads a captured WeatherAPI response from the SDK package's fixtures.
///
/// Read from there rather than copied here. These are live captures, and a
/// second copy is a second chance for the mapper's input to drift away from
/// what the decoder is tested against.
///
/// Every call decodes afresh, so a test is free to change one field in the
/// result to reach a branch the live capture does not contain.
Map<String, dynamic> loadJsonObject(String name) =>
    jsonDecode(_read(name)) as Map<String, dynamic>;

/// Loads a captured response whose top level is an array.
List<dynamic> loadJsonArray(String name) =>
    jsonDecode(_read(name)) as List<dynamic>;

String _read(String name) =>
    File('../aura_weather_api/test/fixtures/$name.json').readAsStringSync();
