import 'package:aura_design/aura_design.dart';
import 'package:aura_domain/aura_domain.dart';
import 'package:aura_feature_home/src/home_ui_state.dart';
import 'package:aura_feature_home/src/home_view_model.dart';
import 'package:aura_feature_home/src/widgets/home_content.dart';
import 'package:aura_feature_home/src/widgets/home_loading.dart';
import 'package:aura_feature_home/src/widgets/home_refresh.dart';
import 'package:aura_feature_home/src/widgets/home_state_screens.dart';
import 'package:aura_l10n/aura_l10n.dart';
import 'package:aura_providers/aura_providers.dart';
import 'package:aura_ui/aura_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The weather for the active place.
///
/// One screen for all eight condition variants in the pen: the sky, the glyphs
/// and their tints all follow `condition.code`, so there is one composition
/// rather than eight.
///
/// The kept places are pages, swiped between, with the device's own position
/// first. Only the place on screen has been asked for: the app makes one
/// request for the active location rather than one per saved city, so a page
/// that has just been swiped to shows its loading state until its reading
/// lands. That is the honest picture, and it is what stops a swipe from
/// showing the previous city's numbers under a new city's name.
///
/// It knows no route paths. Every way out is a callback the composition root
/// fills in, which is also what lets the screen be tested without a router.
class HomeScreen extends ConsumerStatefulWidget {
  /// Creates the home screen.
  const HomeScreen({
    required this.onOpenSettings,
    required this.onOpenSearch,
    required this.onOpenSavedCities,
    required this.onOpenForecast,
    required this.onOpenAirQuality,
    required this.onOpenAlert,
    required this.onOpenSunAndMoon,
    super.key,
  });

  /// Opens settings.
  final VoidCallback onOpenSettings;

  /// Opens search.
  final VoidCallback onOpenSearch;

  /// Opens the saved list.
  final VoidCallback onOpenSavedCities;

  /// Opens the full forecast.
  final VoidCallback onOpenForecast;

  /// Opens the air quality detail.
  final VoidCallback onOpenAirQuality;

  /// Opens the alert detail.
  final VoidCallback onOpenAlert;

  /// Opens the sun and moon detail.
  final VoidCallback onOpenSunAndMoon;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  PageController? _pages;
  int _index = 0;

  @override
  void dispose() {
    _pages?.dispose();
    super.dispose();
  }

  /// Everywhere the user can swipe to, with the device's position first.
  ///
  /// A place reached from search that has not been saved is not part of the
  /// set, so it stands alone and the dots stay away.
  List<LocationRef> _places(List<SavedCity> saved, LocationRef active) {
    final pageable = <LocationRef>[
      const LocationRef.currentByIp(),
      for (final city in saved) city.location,
    ];
    return pageable.contains(active) ? pageable : <LocationRef>[active];
  }

  void _onPageChanged(List<LocationRef> places, int page) {
    if (page < 0 || page >= places.length) return;
    setState(() => _index = page);
    ref.read(activeLocationProvider.notifier).location = places[page];
  }

  @override
  Widget build(BuildContext context) {
    // The previous reading is kept through a refresh, so pulling to refresh
    // does not blank the screen it was pulled on.
    final state = ref.watch(homeViewModelProvider).value;
    final active = ref.watch(activeLocationProvider);
    final saved = ref.watch(savedCitiesProvider).value ?? const <SavedCity>[];

    final places = _places(saved, active);
    final index = places.indexOf(active).clamp(0, places.length - 1);
    if (index != _index) _index = index;
    _pages ??= PageController(initialPage: index);

    return AuraSky(
      kind: state is HomeReady
          ? AuraConditionVisuals.sky(state.snapshot.current.condition)
          : AuraSkyKind.systemBrand,
      // Only a live reading knows where the sun is, and only a clear sky shows
      // it at all.
      celestial: state is HomeReady ? skyBodyFor(state.snapshot) : null,
      child: PageView.builder(
        controller: _pages,
        itemCount: places.length,
        // One place is not a set to page through.
        physics: places.length < 2
            ? const NeverScrollableScrollPhysics()
            : null,
        onPageChanged: (page) => _onPageChanged(places, page),
        itemBuilder: (context, page) => _Page(
          // Only the place on screen has a reading; the rest are still coming.
          state: page == index ? state : null,
          place: places[page],
          placeCount: places.length,
          placeIndex: page,
          screen: widget,
          ref: ref,
        ),
      ),
    );
  }
}

/// One place's page.
class _Page extends StatelessWidget {
  const _Page({
    required this.state,
    required this.place,
    required this.placeCount,
    required this.placeIndex,
    required this.screen,
    required this.ref,
  });

  final HomeUiState? state;
  final LocationRef place;
  final int placeCount;
  final int placeIndex;
  final HomeScreen screen;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      null => HomeLoading(placeName: place.displayName ?? ''),
      HomeUnavailable(:final failure) => HomeFailure(
        failure: failure,
        onTryAgain: () => _refresh(ref),
      ),
      final HomeStale stale => _Offline(state: stale, ref: ref),
      final HomeReady ready => HomeRefresh(
        onRefresh: () => _refresh(ref),
        child: HomeContent(
          state: ready,
          isCurrentLocation: place.isCurrentLocation,
          placeCount: placeCount,
          placeIndex: placeIndex,
          onOpenSettings: screen.onOpenSettings,
          onOpenSearch: screen.onOpenSearch,
          onOpenSavedCities: screen.onOpenSavedCities,
          onOpenForecast: screen.onOpenForecast,
          onOpenAirQuality: screen.onOpenAirQuality,
          onOpenAlert: screen.onOpenAlert,
          onOpenSunAndMoon: screen.onOpenSunAndMoon,
        ),
      ),
    };
  }
}

Future<void> _refresh(WidgetRef ref) =>
    ref.read(homeViewModelProvider.notifier).refresh();

/// The offline screen, with the stored reading it can fall back to.
class _Offline extends StatelessWidget {
  const _Offline({required this.state, required this.ref});

  final HomeStale state;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final format = AuraFormat(l10n: context.l10n, units: state.units);
    return HomeOffline(
      age: format.age(state.age),
      placeName: state.feed.snapshot.placeName,
      temperature: format.temperature(state.feed.snapshot.current.temperature),
      onTryAgain: () => _refresh(ref),
      onUseStoredReading: () =>
          ref.read(homeViewModelProvider.notifier).useStoredReading(),
    );
  }
}
