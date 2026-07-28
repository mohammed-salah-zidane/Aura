import 'package:aura_design/aura_design.dart';
import 'package:aura_domain/aura_domain.dart';
import 'package:aura_feature_home/src/home_ui_state.dart';
import 'package:aura_feature_home/src/home_view_model.dart';
import 'package:aura_feature_home/src/widgets/home_bottom_bar.dart';
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

  /// Whether the first reading has already been shown.
  ///
  /// The sun's arrival sweep, and the entrance held back for it, are spent on
  /// the first reading only; a swipe to another place must not replay them.
  bool _skyArrived = false;

  /// Whether the opening page's neighbours have been warmed yet.
  bool _warmed = false;

  /// Whether the floating bar is up.
  ///
  /// Owned here rather than by a page, so the bar rides above the pager and
  /// survives a swipe: the page being left scrolls its own content, the page
  /// arriving may still be loading, and the bar belongs to neither.
  final ValueNotifier<bool> _navVisible = ValueNotifier<bool>(true);

  @override
  void dispose() {
    _pages?.dispose();
    _navVisible.dispose();
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
    _navVisible.value = true;
    ref.read(activeLocationProvider.notifier).location = places[page];
    _warmNeighbours(places, page);
  }

  /// Starts the fetches for the pages either side of [page].
  ///
  /// The feeds are held per place, so by the time a swipe lands the reading
  /// is usually already there and the page never shows its loading face.
  void _warmNeighbours(List<LocationRef> places, int page) {
    for (final neighbour in <int>[page - 1, page + 1]) {
      if (neighbour < 0 || neighbour >= places.length) continue;
      ref.read(placeFeedProvider(places[neighbour]));
    }
  }

  @override
  Widget build(BuildContext context) {
    // The previous reading is kept through a refresh, so pulling to refresh
    // does not blank the screen it was pulled on.
    final reading = ref.watch(homeViewModelProvider);
    final state = reading.value;
    final active = ref.watch(activeLocationProvider);
    final saved = ref.watch(savedCitiesProvider).value ?? const <SavedCity>[];

    final places = _places(saved, active);
    final index = places.indexOf(active).clamp(0, places.length - 1);
    if (index != _index) {
      // The active place changed somewhere else: a search result was picked,
      // or a city was chosen from the saved list. The pager has to move
      // under it, or the screen sits on a page whose reading is never the
      // one arriving.
      _index = index;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final pages = _pages;
        if (!mounted || pages == null || !pages.hasClients) return;
        if (pages.page?.round() != _index) pages.jumpToPage(_index);
      });
    }
    _pages ??= PageController(initialPage: index);

    // The first frame warms the pages beside the opening one, so the very
    // first swipe is as ready as every later one.
    if (!_warmed && places.length > 1) {
      _warmed = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _warmNeighbours(places, index);
      });
    }

    // A reading fetched for the page just left must not dress the page just
    // arrived at, so a state whose feed names another place is withheld and
    // the new page shows its loading face until its own reading lands.
    final matchesActive = switch (state) {
      HomeReady(:final feed) ||
      HomeStale(:final feed) => feed.location == active,
      _ => true,
    };
    final shown = matchesActive ? state : null;

    // Only a live reading knows where the sun is, and only a clear sky shows
    // it at all.
    final celestial = shown is HomeReady ? skyBodyFor(shown.snapshot) : null;
    final skyLeadIn = !_skyArrived && celestial != null
        ? AuraMotion.celestialArrival
        : Duration.zero;
    if (shown is HomeReady) _skyArrived = true;

    return AuraSky(
      kind: shown is HomeReady
          ? AuraConditionVisuals.sky(shown.snapshot.current.condition)
          : AuraSkyKind.systemBrand,
      celestial: celestial,
      child: Stack(
        children: <Widget>[
          PageView.builder(
            controller: _pages,
            itemCount: places.length,
            // One place is not a set to page through.
            physics: places.length < 2
                ? const NeverScrollableScrollPhysics()
                : null,
            onPageChanged: (page) => _onPageChanged(places, page),
            itemBuilder: (context, page) => _Page(
              // Only the place on screen has a reading; the rest are still
              // coming.
              state: page == index ? shown : null,
              skyLeadIn: skyLeadIn,
              place: places[page],
              navVisible: _navVisible,
              screen: widget,
              ref: ref,
            ),
          ),
          const HomeBottomScrim(),
          HomeBottomBar(
            isVisible: _navVisible,
            placeCount: places.length,
            placeIndex: index,
            leadsWithCurrentLocation: places.first.isCurrentLocation,
            isRefreshing: reading.isLoading && shown != null,
            onOpenSearch: widget.onOpenSearch,
            onOpenSavedCities: widget.onOpenSavedCities,
            onOpenSettings: widget.onOpenSettings,
          ),
        ],
      ),
    );
  }
}

/// One place's page.
class _Page extends StatelessWidget {
  const _Page({
    required this.state,
    required this.skyLeadIn,
    required this.place,
    required this.navVisible,
    required this.screen,
    required this.ref,
  });

  final HomeUiState? state;
  final Duration skyLeadIn;
  final LocationRef place;
  final ValueNotifier<bool> navVisible;
  final HomeScreen screen;
  final WidgetRef ref;

  /// Keeps a full-screen state's pinned actions above the floating bar.
  Widget _clearOfBar(BuildContext context, Widget child) => Padding(
    padding: EdgeInsets.only(
      bottom: MediaQuery.paddingOf(context).bottom + HomeBottomBar.clearance,
    ),
    child: child,
  );

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      null => HomeLoading(placeName: place.displayName ?? ''),
      HomeUnavailable(:final failure) => _clearOfBar(
        context,
        HomeFailure(failure: failure, onTryAgain: () => _refresh(ref)),
      ),
      final HomeStale stale => _clearOfBar(
        context,
        _Offline(state: stale, ref: ref),
      ),
      final HomeReady ready => HomeRefresh(
        onRefresh: () => _refresh(ref),
        child: HomeContent(
          state: ready,
          isCurrentLocation: place.isCurrentLocation,
          skyLeadIn: skyLeadIn,
          navVisible: navVisible,
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
