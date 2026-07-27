import 'package:aura_design/aura_design.dart';
import 'package:aura_domain/aura_domain.dart';
import 'package:aura_feature_home/src/home_ui_state.dart';
import 'package:aura_feature_home/src/widgets/home_air_quality_card.dart';
import 'package:aura_feature_home/src/widgets/home_collapsing_hero.dart';
import 'package:aura_feature_home/src/widgets/home_forecast_preview.dart';
import 'package:aura_feature_home/src/widgets/home_hero.dart';
import 'package:aura_feature_home/src/widgets/home_hourly_strip.dart';
import 'package:aura_feature_home/src/widgets/home_metric_grid.dart';
import 'package:aura_feature_home/src/widgets/home_sections.dart';
import 'package:aura_feature_home/src/widgets/home_sky_dissolve.dart';
import 'package:aura_feature_home/src/widgets/home_sun_and_moon_card.dart';
import 'package:aura_l10n/aura_l10n.dart';
import 'package:aura_ui/aura_ui.dart';
import 'package:flutter/widgets.dart';

/// What the home screen shows once it has a reading.
///
/// Every section is drawn from the one `forecast.json` call. The alert banner
/// and the air quality card appear only when that call returned something for
/// them, because an empty `alerts.alert[]` means no alert is active rather
/// than that alerts are unsupported.
///
/// The page scrolls the way the native weather apps do. The hero dissolves
/// into the sky, a condensed line floats where it stood, the cards melt into
/// the sky at both edges of the page rather than hitting a hard clip, and
/// each headed card's title holds at the top of its section until the next
/// section pushes it away. Under reduced motion the whole page is one static
/// column that scrolls together.
///
/// Sections arrive staggered rather than all at once, and when the sun is
/// riding the sky they wait for it to finish its arc first. The stagger runs
/// once, on the first reading: this screen deliberately keeps the previous one
/// through a refresh, and replaying the entrance on every fetch would undo the
/// thing that protects.
class HomeContent extends StatefulWidget {
  /// Creates the home content.
  const HomeContent({
    required this.state,
    required this.isCurrentLocation,
    required this.skyLeadIn,
    required this.navVisible,
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

  /// Held before the entrance while the sun sweeps its arc, and zero once
  /// that moment has been spent.
  final Duration skyLeadIn;

  /// Whether the screen's floating bar should be up, driven from this page's
  /// scroll and owned by the screen so the bar outlives a swipe.
  final ValueNotifier<bool> navVisible;

  /// Opens the full forecast.
  final VoidCallback onOpenForecast;

  /// Opens the air quality detail.
  final VoidCallback onOpenAirQuality;

  /// Opens the alert detail.
  final VoidCallback onOpenAlert;

  /// Opens the sun and moon detail.
  final VoidCallback onOpenSunAndMoon;

  /// Room the last card keeps so it can scroll clear of the floating bar.
  static const double bottomInset = 168;

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

  double _lastOffset = 0;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  void _onScroll() {
    final offset = _scroll.offset;
    _offset.value = offset < 0 ? 0 : offset;

    final delta = offset - _lastOffset;
    if (delta.abs() < _scrollNoise) return;
    _lastOffset = offset;
    widget.navVisible.value = delta < 0 || offset < _alwaysShownAbove;
  }

  /// A drag smaller than this is a finger resting, not a decision.
  static const double _scrollNoise = 6;

  /// Near the top the bar is always up, so the screen never opens without it.
  static const double _alwaysShownAbove = 80;

  @override
  void dispose() {
    _scroll
      ..removeListener(_onScroll)
      ..dispose();
    _offset.dispose();
    super.dispose();
  }

  /// A section body: entrance-wrapped, with the gap that follows it.
  Widget _boxed(int index, Widget child) => SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.only(bottom: AuraSpacing.xl),
      child: AuraEntrance(
        index: index,
        leadIn: widget.skyLeadIn,
        child: child,
      ),
    ),
  );

  /// A card title that holds at the top of its section while the card passes,
  /// then gives way to the next one. Under reduced motion it simply scrolls.
  Widget _title(
    int index,
    String title,
    VoidCallback? onOpen, {
    required bool pinned,
  }) => HomeSectionTitle(
    title: title,
    onOpen: onOpen,
    pinned: pinned,
    entranceIndex: index,
    leadIn: widget.skyLeadIn,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final format = AuraFormat(l10n: l10n, units: widget.state.units);
    final snapshot = widget.state.snapshot;
    final alert = snapshot.headlineAlert;
    final airQuality = snapshot.airQuality;
    final expires = alert?.expires;
    final still = context.prefersReducedMotion;

    var index = 0;
    final content = <Widget>[
      if (alert != null)
        _boxed(
          ++index,
          AuraAlertBanner(
            title: alert.event,
            subtitle: expires == null
                ? l10n.alertTapForDetails
                : l10n.alertInEffectUntil(format.timeOfDay(expires)),
            onTap: widget.onOpenAlert,
          ),
        ),
      _boxed(
        ++index,
        HomeHourlyStrip(
          hours: upcomingHours(snapshot.days, from: snapshot.localTime),
          sunset: snapshot.today.astro.sunset,
          format: format,
        ),
      ),
      _boxed(
        ++index,
        HomeMetricGrid(current: snapshot.current, format: format),
      ),
      _title(
        ++index,
        l10n.sectionForecast.toUpperCase(),
        widget.onOpenForecast,
        pinned: !still,
      ),
      _boxed(
        index,
        HomeForecastPreview(
          days: snapshot.days,
          format: format,
          onOpen: widget.onOpenForecast,
        ),
      ),
      if (airQuality != null) ...<Widget>[
        _title(
          ++index,
          l10n.sectionAirQuality.toUpperCase(),
          widget.onOpenAirQuality,
          pinned: !still,
        ),
        _boxed(
          index,
          HomeAirQualityCard(
            airQuality: airQuality,
            format: format,
            onOpen: widget.onOpenAirQuality,
          ),
        ),
      ],
      _title(
        ++index,
        l10n.sectionSunAndMoon.toUpperCase(),
        widget.onOpenSunAndMoon,
        pinned: !still,
      ),
      _boxed(
        index,
        HomeSunAndMoonCard(
          astro: snapshot.today.astro,
          format: format,
          onOpen: widget.onOpenSunAndMoon,
        ),
      ),
    ];

    final hero = still
        ? SliverToBoxAdapter(
            child: AuraEntrance(
              index: 0,
              leadIn: widget.skyLeadIn,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AuraSpacing.xl,
                  HomeCollapsingHero.skyBand,
                  AuraSpacing.xl,
                  AuraSpacing.xl,
                ),
                child: HomeHero(
                  snapshot: snapshot,
                  isCurrentLocation: widget.isCurrentLocation,
                  format: format,
                ),
              ),
            ),
          )
        : HomeCollapsingHero(
            offset: _offset,
            snapshot: snapshot,
            isCurrentLocation: widget.isCurrentLocation,
            format: format,
            leadIn: widget.skyLeadIn,
          );

    final page = CustomScrollView(
      controller: _scroll,
      slivers: <Widget>[
        hero,
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AuraSpacing.xl,
            0,
            AuraSpacing.xl,
            HomeContent.bottomInset,
          ),
          sliver: SliverMainAxisGroup(slivers: content),
        ),
      ],
    );

    if (still) return SafeArea(bottom: false, child: page);

    // The overlay sits outside the safe area on purpose: its wash runs to the
    // very top of the screen, so the status bar shares the bar's backing
    // instead of sitting on a visibly different strip of sky.
    return Stack(
      children: <Widget>[
        SafeArea(
          bottom: false,
          child: HomeSkyDissolve(
            bottomInset: HomeContent.bottomInset,
            child: page,
          ),
        ),
        HomeCondensedOverlay(
          offset: _offset,
          snapshot: snapshot,
          format: format,
        ),
      ],
    );
  }
}
