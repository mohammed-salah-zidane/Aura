import 'package:aura_feature_details/aura_feature_details.dart';
import 'package:aura_feature_home/aura_feature_home.dart';
import 'package:aura_feature_onboarding/aura_feature_onboarding.dart';
import 'package:aura_feature_saved_cities/aura_feature_saved_cities.dart';
import 'package:aura_feature_search/aura_feature_search.dart';
import 'package:aura_feature_settings/aura_feature_settings.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Every path in the app.
///
/// Paths live at the composition root and nowhere else. A feature takes plain
/// callbacks and knows nothing about routing, which is also what lets each
/// screen be tested without a router above it.
abstract final class AuraRoutes {
  /// The splash, which decides where the app opens.
  static const String splash = '/';

  /// The permission screen, when there is nothing to open on yet.
  static const String permission = '/permission';

  /// The weather.
  static const String home = '/weather';

  /// Search.
  static const String search = '/search';

  /// The kept places.
  static const String savedCities = '/cities';

  /// Settings.
  static const String settings = '/settings';

  /// The full forecast.
  static const String forecast = '/weather/forecast';

  /// Air quality.
  static const String airQuality = '/weather/air-quality';

  /// The active alert.
  static const String alert = '/weather/alert';

  /// Sun and moon.
  static const String sunAndMoon = '/weather/sun-and-moon';
}

/// Builds the router.
///
/// [version] is the build the About row reports, read from the package at the
/// root rather than hard-coded in the feature.
GoRouter auraRouter({required String version, String? initialLocation}) {
  void back(BuildContext context) =>
      context.canPop() ? context.pop() : context.go(AuraRoutes.home);

  return GoRouter(
    initialLocation: initialLocation ?? AuraRoutes.splash,
    routes: <RouteBase>[
      GoRoute(
        path: AuraRoutes.splash,
        builder: (context, state) => SplashScreen(
          onReady: (destination) => context.go(
            switch (destination) {
              SplashDestination.weather => AuraRoutes.home,
              SplashDestination.permission => AuraRoutes.permission,
            },
          ),
        ),
      ),
      GoRoute(
        path: AuraRoutes.permission,
        builder: (context, state) => PermissionScreen(
          onAllow: () => context.go(AuraRoutes.home),
          onEnterManually: () => context.go(AuraRoutes.search),
        ),
      ),
      GoRoute(
        path: AuraRoutes.home,
        builder: (context, state) => HomeScreen(
          onOpenSettings: () => context.push(AuraRoutes.settings),
          onOpenSearch: () => context.push(AuraRoutes.search),
          onOpenSavedCities: () => context.push(AuraRoutes.savedCities),
          onOpenForecast: () => context.push(AuraRoutes.forecast),
          onOpenAirQuality: () => context.push(AuraRoutes.airQuality),
          onOpenAlert: () => context.push(AuraRoutes.alert),
          onOpenSunAndMoon: () => context.push(AuraRoutes.sunAndMoon),
        ),
        routes: <RouteBase>[
          GoRoute(
            path: 'forecast',
            builder: (context, state) =>
                ForecastScreen(onBack: () => back(context)),
          ),
          GoRoute(
            path: 'air-quality',
            builder: (context, state) =>
                AirQualityScreen(onBack: () => back(context)),
          ),
          GoRoute(
            path: 'alert',
            builder: (context, state) =>
                WeatherAlertScreen(onBack: () => back(context)),
          ),
          GoRoute(
            path: 'sun-and-moon',
            builder: (context, state) =>
                SunAndMoonScreen(onBack: () => back(context)),
          ),
        ],
      ),
      GoRoute(
        path: AuraRoutes.search,
        builder: (context, state) => SearchScreen(onDone: () => back(context)),
      ),
      GoRoute(
        path: AuraRoutes.savedCities,
        builder: (context, state) => SavedCitiesScreen(
          onOpenSearch: () => context.push(AuraRoutes.search),
          onSelect: () => back(context),
        ),
      ),
      GoRoute(
        path: AuraRoutes.settings,
        builder: (context, state) =>
            SettingsScreen(onDone: () => back(context), version: version),
      ),
    ],
  );
}
