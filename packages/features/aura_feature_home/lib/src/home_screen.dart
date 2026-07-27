import 'package:aura_design/aura_design.dart';
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
/// It knows no route paths. Every way out is a callback the composition root
/// fills in, which is also what lets the screen be tested without a router.
class HomeScreen extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    // The previous reading is kept through a refresh, so pulling to refresh
    // does not blank the screen it was pulled on.
    final state = ref.watch(homeViewModelProvider).value;
    final location = ref.watch(activeLocationProvider);

    return AuraSky(
      kind: state is HomeReady
          ? AuraConditionVisuals.sky(state.snapshot.current.condition)
          : AuraSkyKind.systemBrand,
      child: switch (state) {
        null => HomeLoading(placeName: location.displayName ?? ''),
        HomeUnavailable(:final failure) => HomeFailure(
          failure: failure,
          onTryAgain: () => _refresh(ref),
        ),
        HomeStale() => _Offline(state: state, ref: ref),
        HomeReady() => HomeRefresh(
          onRefresh: () => _refresh(ref),
          child: HomeContent(
            state: state,
            isCurrentLocation: location.isCurrentLocation,
            onOpenSettings: onOpenSettings,
            onOpenSearch: onOpenSearch,
            onOpenSavedCities: onOpenSavedCities,
            onOpenForecast: onOpenForecast,
            onOpenAirQuality: onOpenAirQuality,
            onOpenAlert: onOpenAlert,
            onOpenSunAndMoon: onOpenSunAndMoon,
          ),
        ),
      },
    );
  }

  static Future<void> _refresh(WidgetRef ref) =>
      ref.read(homeViewModelProvider.notifier).refresh();
}

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
      onTryAgain: () => HomeScreen._refresh(ref),
      onUseStoredReading: () =>
          ref.read(homeViewModelProvider.notifier).useStoredReading(),
    );
  }
}
