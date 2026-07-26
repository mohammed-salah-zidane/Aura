import 'package:aura_core/aura_core.dart';
import 'package:aura_domain/aura_domain.dart';
import 'package:aura_feature_search/aura_feature_search.dart';
import 'package:aura_providers/aura_providers.dart';
import 'package:aura_test_kit/aura_test_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

/// One match the service could return.
CitySuggestion citySuggestion(
  String name, {
  String region = '',
  String country = 'Egypt',
}) => CitySuggestion(
  location: LocationRef(query: name, displayName: name),
  name: name,
  region: region,
  country: country,
);

/// A reading for the temperature beside a match.
CityReading cityReading(double temperature) => CityReading(
  placeName: 'Cairo',
  region: '',
  country: 'Egypt',
  localTime: fixtureNow,
  current: weatherFixture(temperature: temperature).current,
);

/// Everything the search screen reads, wired to fakes.
final class SearchHarness {
  /// Wires the graph.
  SearchHarness({
    List<CitySuggestion> suggestions = const <CitySuggestion>[],
    CityReading? reading,
    AppFailure? searchFailure,
    LocationPermission permission = LocationPermission.notDetermined,
    LocationRef? position,
  }) : repository = FakeWeatherRepository(
         suggestions: suggestions,
         reading_: reading,
         searchFailure: searchFailure,
       ),
       location = FakeLocation(
         state: permission,
         granted: permission,
         position: position,
       ),
       cities = FakeSavedCities() {
    container = ProviderContainer(
      overrides: <Override>[
        clockProvider.overrideWithValue(FixedClock(fixtureNow)),
        weatherRepositoryProvider.overrideWithValue(repository),
        settingsPortProvider.overrideWithValue(FakeSettings()),
        savedCitiesPortProvider.overrideWithValue(cities),
        locationPortProvider.overrideWithValue(location),
      ],
    );
    addTearDown(container.dispose);
    // The view model disposes itself the moment nothing is listening, and with
    // it the debounce timer. A listener stands in for the screen.
    final subscription = container.listen(
      searchViewModelProvider,
      (previous, next) {},
    );
    addTearDown(subscription.close);
  }

  /// Where matches and readings come from.
  final FakeWeatherRepository repository;

  /// Where the device position comes from.
  final FakeLocation location;

  /// Where kept places are stored.
  final FakeSavedCities cities;

  /// The graph under test.
  late final ProviderContainer container;

  /// The screen's own state.
  SearchViewModel get viewModel =>
      container.read(searchViewModelProvider.notifier);

  /// The screen, wired to this graph.
  Widget screen({VoidCallback? onDone}) => UncontrolledProviderScope(
    container: container,
    child: SearchScreen(onDone: onDone ?? () {}),
  );
}

/// Shorthand for a harness in a test that only names what it changes.
SearchHarness searchHarness({
  List<CitySuggestion> suggestions = const <CitySuggestion>[],
  CityReading? reading,
  AppFailure? searchFailure,
  LocationPermission permission = LocationPermission.notDetermined,
  LocationRef? position,
}) => SearchHarness(
  suggestions: suggestions,
  reading: reading,
  searchFailure: searchFailure,
  permission: permission,
  position: position,
);
