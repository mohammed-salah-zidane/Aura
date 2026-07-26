import 'package:aura_core/aura_core.dart';
import 'package:aura_domain/aura_domain.dart';
import 'package:aura_feature_home/aura_feature_home.dart';
import 'package:aura_providers/aura_providers.dart';
import 'package:aura_test_kit/aura_test_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

/// Everything the home screen reads, wired to fakes.
///
/// The container is built per test so no state leaks between them, and every
/// collaborator is reachable afterwards for the assertions.
final class HomeHarness {
  /// Wires the graph.
  HomeHarness({
    WeatherSnapshot? snapshot,
    AppFailure? failure,
    DateTime? fetchedAt,
    List<SavedCity> saved = const <SavedCity>[],
    DateTime? now,
    Duration delay = Duration.zero,
  }) : clock = FixedClock(now ?? fixtureNow),
       repository = FakeWeatherRepository(
         snapshot: snapshot,
         failure: failure,
         fetchedAt: fetchedAt,
         delay: delay,
       ),
       settings = FakeSettings(),
       cities = FakeSavedCities(saved) {
    container = ProviderContainer(
      overrides: <Override>[
        clockProvider.overrideWithValue(clock),
        weatherRepositoryProvider.overrideWithValue(repository),
        settingsPortProvider.overrideWithValue(settings),
        savedCitiesPortProvider.overrideWithValue(cities),
      ],
    );
    addTearDown(container.dispose);
  }

  /// The clock every time-dependent reading goes through.
  final FixedClock clock;

  /// Where weather comes from.
  final FakeWeatherRepository repository;

  /// Where the units come from.
  final FakeSettings settings;

  /// Where the kept places come from.
  final FakeSavedCities cities;

  /// The graph under test.
  late final ProviderContainer container;

  /// The home screen's state, once it has settled.
  Future<HomeUiState> state() => container.read(homeViewModelProvider.future);

  /// The screen, wired to this graph.
  Widget screen({
    VoidCallback? onOpenSettings,
    VoidCallback? onOpenSearch,
    VoidCallback? onOpenSavedCities,
    VoidCallback? onOpenForecast,
    VoidCallback? onOpenAirQuality,
    VoidCallback? onOpenAlert,
    VoidCallback? onOpenSunAndMoon,
  }) => UncontrolledProviderScope(
    container: container,
    child: HomeScreen(
      onOpenSettings: onOpenSettings ?? () {},
      onOpenSearch: onOpenSearch ?? () {},
      onOpenSavedCities: onOpenSavedCities ?? () {},
      onOpenForecast: onOpenForecast ?? () {},
      onOpenAirQuality: onOpenAirQuality ?? () {},
      onOpenAlert: onOpenAlert ?? () {},
      onOpenSunAndMoon: onOpenSunAndMoon ?? () {},
    ),
  );
}
