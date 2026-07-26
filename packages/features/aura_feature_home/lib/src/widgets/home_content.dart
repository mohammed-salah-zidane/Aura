import 'package:aura_design/aura_design.dart';
import 'package:aura_domain/aura_domain.dart';
import 'package:aura_feature_home/src/home_ui_state.dart';
import 'package:aura_feature_home/src/widgets/home_air_quality_card.dart';
import 'package:aura_feature_home/src/widgets/home_forecast_preview.dart';
import 'package:aura_feature_home/src/widgets/home_hero.dart';
import 'package:aura_feature_home/src/widgets/home_hourly_strip.dart';
import 'package:aura_feature_home/src/widgets/home_metric_grid.dart';
import 'package:aura_feature_home/src/widgets/home_sun_and_moon_card.dart';
import 'package:aura_feature_home/src/widgets/home_top_bar.dart';
import 'package:aura_l10n/aura_l10n.dart';
import 'package:aura_ui/aura_ui.dart';
import 'package:flutter/widgets.dart';

/// What the home screen shows once it has a reading.
///
/// Every section is drawn from the one `forecast.json` call. The alert banner
/// and the air quality card appear only when that call returned something for
/// them, because an empty `alerts.alert[]` means no alert is active rather
/// than that alerts are unsupported.
class HomeContent extends StatelessWidget {
  /// Creates the home content.
  const HomeContent({
    required this.state,
    required this.isCurrentLocation,
    required this.onOpenSettings,
    required this.onOpenSearch,
    required this.onOpenSavedCities,
    required this.onOpenForecast,
    required this.onOpenAirQuality,
    required this.onOpenAlert,
    required this.onOpenSunAndMoon,
    super.key,
  });

  /// The reading and the units to draw it in.
  final HomeReady state;

  /// Whether the place is wherever the device is.
  final bool isCurrentLocation;

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

  /// The pen's `Content` padding on every weather frame.
  static const EdgeInsets _padding = EdgeInsets.fromLTRB(
    AuraSpacing.xl,
    AuraSpacing.sm,
    AuraSpacing.xl,
    AuraSpacing.xxl,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final format = AuraFormat(l10n: l10n, units: state.units);
    final snapshot = state.snapshot;
    final alert = snapshot.headlineAlert;
    final airQuality = snapshot.airQuality;
    final expires = alert?.expires;

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: _padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AuraSpacing.xl,
          children: <Widget>[
            HomeTopBar(
              onOpenSearch: onOpenSearch,
              onOpenSavedCities: onOpenSavedCities,
              onOpenSettings: onOpenSettings,
            ),
            if (alert != null)
              AuraAlertBanner(
                title: alert.event,
                subtitle: expires == null
                    ? l10n.alertTapForDetails
                    : l10n.alertInEffectUntil(format.timeOfDay(expires)),
                onTap: onOpenAlert,
              ),
            HomeHero(
              snapshot: snapshot,
              isCurrentLocation: isCurrentLocation,
              format: format,
            ),
            HomeHourlyStrip(
              hours: upcomingHours(
                snapshot.days,
                from: snapshot.localTime,
              ),
              sunset: snapshot.today.astro.sunset,
              format: format,
            ),
            HomeMetricGrid(current: snapshot.current, format: format),
            HomeForecastPreview(
              days: snapshot.days,
              format: format,
              onOpen: onOpenForecast,
            ),
            if (airQuality != null)
              HomeAirQualityCard(
                airQuality: airQuality,
                format: format,
                onOpen: onOpenAirQuality,
              ),
            HomeSunAndMoonCard(
              astro: snapshot.today.astro,
              format: format,
              onOpen: onOpenSunAndMoon,
            ),
          ],
        ),
      ),
    );
  }
}
