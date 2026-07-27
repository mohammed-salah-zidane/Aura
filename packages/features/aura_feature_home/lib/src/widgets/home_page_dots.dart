import 'dart:async';

import 'package:aura_design/aura_design.dart';
import 'package:aura_l10n/aura_l10n.dart';
import 'package:flutter/widgets.dart';

/// The centre of the bar: the page markers, and the mark that breathes there
/// while a refresh is in flight.
class HomePages extends StatefulWidget {
  /// Creates the centre of the bar.
  const HomePages({
    required this.count,
    required this.index,
    required this.leadsWithCurrentLocation,
    required this.isRefreshing,
    super.key,
  });

  /// How many places there are.
  final int count;

  /// Which one is showing.
  final int index;

  /// Whether the first marker is the device's position, drawn as an arrow.
  final bool leadsWithCurrentLocation;

  /// Whether a refresh is in flight, worn by the mark beside the markers.
  final bool isRefreshing;

  @override
  State<HomePages> createState() => _HomePagesState();
}

class _HomePagesState extends State<HomePages>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: AuraMotion.breath,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncBreath();
  }

  @override
  void didUpdateWidget(HomePages oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncBreath();
  }

  void _syncBreath() {
    final run = widget.isRefreshing && !context.prefersReducedMotion;
    if (run == _breath.isAnimating) return;
    if (run) {
      unawaited(_breath.repeat());
    } else {
      _breath
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  /// How far the mark's glow swells while the request is out.
  static const double _glowBreath = 0.22;

  /// Zero at rest, one at the midpoint, zero again at the end.
  static double _swell(double t) =>
      AuraMotion.breathCurve.transform(1 - (2 * t - 1).abs());

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: AuraSpacing.sm,
      children: <Widget>[
        AnimatedSwitcher(
          duration: AuraMotion.control,
          switchInCurve: AuraMotion.controlCurve,
          switchOutCurve: AuraMotion.controlCurve,
          child: !widget.isRefreshing
              ? const SizedBox.shrink()
              : Semantics(
                  label: context.l10n.homeUpdating,
                  child: AnimatedBuilder(
                    animation: _breath,
                    builder: (context, _) => AuraMark(
                      size: AuraMarkSize.hero,
                      glow: 1 + _glowBreath * _swell(_breath.value),
                    ),
                  ),
                ),
        ),
        HomePageDots(
          count: widget.count,
          index: widget.index,
          leadsWithCurrentLocation: widget.leadsWithCurrentLocation,
        ),
      ],
    );
  }
}

/// One marker per place: the pen's arrow for the device's own page, a dot for
/// every saved city, with the current page lit and the rest faded.
///
/// They are the only thing on screen that says how many places there are to
/// move between, which is what makes the swipe discoverable at all.
class HomePageDots extends StatelessWidget {
  /// Creates the row of markers.
  const HomePageDots({
    required this.count,
    required this.index,
    required this.leadsWithCurrentLocation,
    super.key,
  });

  /// How many places there are.
  final int count;

  /// Which one is showing.
  final int index;

  /// Whether the first marker is the device's position, drawn as an arrow.
  final bool leadsWithCurrentLocation;

  /// The showing page wears the brand gold, so which place is on screen reads
  /// at a glance even when the set is only the arrow; the rest keep the pen's
  /// white at 59 per cent.
  Color _tint(int i) => i == index
      ? AuraColors.accent
      : AuraColors.textPrimary.withValues(alpha: _restingAlpha);

  /// The pen fills a resting marker with white at 59 per cent.
  static const double _restingAlpha = 0.59;

  @override
  Widget build(BuildContext context) {
    // A lone dot for an unsaved place says nothing; the lone arrow still says
    // the reading is for wherever the device is, so it stays.
    if (count < 2 && !leadsWithCurrentLocation) return const SizedBox.shrink();

    return Semantics(
      label: context.l10n.homePlaceOfPlaces(index + 1, count),
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: AuraSpacing.sm,
        children: <Widget>[
          for (var i = 0; i < count; i++)
            if (i == 0 && leadsWithCurrentLocation)
              Icon(
                AuraIcons.navigation,
                size: AuraSizes.pagerCurrent,
                color: _tint(i),
              )
            else
              AnimatedContainer(
                duration: AuraMotion.control,
                curve: AuraMotion.controlCurve,
                width: AuraSizes.pagerDot,
                height: AuraSizes.pagerDot,
                decoration: BoxDecoration(
                  color: _tint(i),
                  borderRadius: BorderRadius.circular(AuraRadii.pill),
                ),
              ),
        ],
      ),
    );
  }
}
