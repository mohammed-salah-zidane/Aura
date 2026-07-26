import 'dart:convert';
import 'dart:io';

/// Loads a captured WeatherAPI response by file name.
///
/// The fixtures were captured from the live service rather than written by
/// hand, so a field the DTOs get wrong shows up here rather than in
/// production.
Map<String, dynamic> loadJsonObject(String name) =>
    jsonDecode(_read(name)) as Map<String, dynamic>;

/// Loads a captured response whose top level is an array.
List<dynamic> loadJsonArray(String name) =>
    jsonDecode(_read(name)) as List<dynamic>;

String _read(String name) =>
    File('test/fixtures/$name.json').readAsStringSync();
