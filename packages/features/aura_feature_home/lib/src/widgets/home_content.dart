import 'package:aura_design/aura_design.dart';
import 'package:aura_domain/aura_domain.dart';
import 'package:aura_feature_home/src/home_ui_state.dart';
import 'package:aura_feature_home/src/widgets/home_air_quality_card.dart';
import 'package:aura_feature_home/src/widgets/home_condensed_bar.dart';
import 'package:aura_feature_home/src/widgets/home_forecast_preview.dart';
import 'package:aura_feature_home/src/widgets/home_hero.dart';
import 'package:aura_feature_home/src/widgets/home_hourly_strip.dart';
import 'package:aura_feature_home/src/widgets/home_metric_grid.dart';
import 'package:aura_feature_home/src/widgets/home_sun_and_moon_card.dart';
import 'package:aura_feature_home/src/widgets/home_top_bar.dart';
import 'package:aura_l10n/aura_l10n.dart';
import 'package:aura_ui/aura_ui.dart';
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/widgets.dart';

/// What the home screen shows once it has a reading.
///
/// Every section is drawn from the one `forecast.json` call. The alert banner
/// and the air quality card appear only when that call returned something for
/// them, because an empty `alerts.alert[]` means no alert is active rather
/// than that alerts are unsupported.
///
/// Sections arrive staggered rather than all at once, which lets the eye follow
/// the page down in reading order. The stagger runs once, on the first reading:
/// this screen deliberately keeps the previous one through a refresh, and
/// replaying the entrance on every fetch would undo the thing that protects.
class HomeContent extends StatefulWidget {
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
  static const EdgeInsets padding = EdgeInsets.fromLTRB(
    AuraSpacing.xl,
    AuraSpacing.sm,
    AuraSpacing.xl,
    AuraSpacing.xxl,
  );

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  final ScrollController _scroll = ScrollController();

  /// How far the page has been scrolled, for the pieces that answer to it.
  ///
  /// A notifier rather than `setState`, so a scroll repaints the hero and the
  /// condensed bar without rebuilding the seven sections underneath them.
  final ValueNotifier<double> _offset = ValueNotifier<double>(0);

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  void _onScroll() {
    final offset = _scroll.offset;
    _offset.value = offset < 0 ? 0 : offset;
  }

  @override
  void dispose() {
    _scroll
      ..removeListener(_onScroll)
      ..dispose();
    _offset.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final format = AuraFormat(l10n: l10n, units: widget.state.units);
    final snapshot = widget.state.snapshot;
    final alert = snapshot.headlineAlert;
    final airQuality = snapshot.airQuality;
    final expires = alert?.expires;

    final sections = <Widget>[
      HomeTopBar(
        onOpenSearch: widget.onOpenSearch,
        onOpenSavedCities: widget.onOpenSavedCities,
        onOpenSettings: widget.onOpenSettings,
      ),
      if (alert != null)
        AuraAlertBanner(
          title: alert.event,
          subtitle: expires == null
              ? l10n.alertTapForDetails
              : l10n.alertInEffectUntil(format.timeOfDay(expires)),
          onTap: widget.onOpenAlert,
        ),
      _Parallax(
        offset: _offset,
        child: HomeHero(
          snapshot: snapshot,
          isCurrentLocation: widget.isCurrentLocation,
          format: format,
        ),
      ),
      HomeHourlyStrip(
        hours: upcomingHours(snapshot.days, from: snapshot.localTime),
        sunset: snapshot.today.astro.sunset,
        format: format,
      ),
      HomeMetricGrid(current: snapshot.current, format: format),
      HomeForecastPreview(
        days: snapshot.days,
        format: format,
        onOpen: widget.onOpenForecast,
      ),
      if (airQuality != null)
        HomeAirQualityCard(
          airQuality: airQuality,
          format: format,
          onOpen: widget.onOpenAirQuality,
        ),
      HomeSunAndMoonCard(
        astro: snapshot.today.astro,
        format: format,
        onOpen: widget.onOpenSunAndMoon,
      ),
    ];

    return Stack(
      children: <Widget>[
        SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            controller: _scroll,
            padding: HomeContent.padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AuraSpacing.xl,
              children: <Widget>[
                for (var i = 0; i < sections.length; i++)
                  AuraEntrance(index: i, child: sections[i]),
              ],
            ),
          ),
        ),
        HomeCondensedBar(
          offset: _offset,
          placeName: snapshot.placeName,
          temperature: format.temperature(snapshot.current.temperature),
          onOpenSearch: widget.onOpenSearch,
          onOpenSavedCities: widget.onOpenSavedCities,
          onOpenSettings: widget.onOpenSettings,
        ),
      ],
    );
  }
}

/// Holds the hero back as the page scrolls, and fades it as it leaves.
///
/// The sky behind it does not scroll at all, so the hero moving slower than
/// the cards puts three planes on screen: the sky, the hero, the content. At
/// rest it is an identity transform, which is what keeps the frame the pen's.
class _Parallax extends StatelessWidget {
  const _Parallax({required this.offset, required this.child});

  final ValueListenable<double> offset;
  final Widget child;

  /// Over how many points of scroll the hero fades out completely.
  static const double _fadeOver = 190;

  @override
  Widget build(BuildContext context) {
    if (context.prefersReducedMotion) return child;
    return ValueListenableBuilder<double>(
      valueListenable: offset,
      builder: (context, value, child) => Transform.translate(
        offset: Offset(0, value * AuraMotion.heroParallax),
        child: Opacity(
          opacity: (1 - value / _fadeOver).clamp(0.0, 1.0),
          child: child,
        ),
      ),
      child: child,
    );
  }
}
