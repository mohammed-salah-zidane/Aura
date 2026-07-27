import 'package:aura_design/aura_design.dart';
import 'package:aura_domain/aura_domain.dart';
import 'package:aura_feature_home/src/widgets/home_hero.dart';
import 'package:aura_ui/aura_ui.dart';
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/widgets.dart';

/// The hero, giving way to the condensed bar as the page scrolls.
///
/// At rest it is the pen's hero exactly: the kicker, the city, the display
/// temperature, the condition and the range, sitting under the band of sky
/// the sun crosses. Scrolling consumes that composition the way the native
/// weather apps do: the hero compresses and dissolves, and the sliver stays
/// pinned at the height of the condensed bar plus the strip of sky the cards
/// dissolve into on their way under it.
///
/// The condensed bar itself is not in here. It floats above the scroll view,
/// outside the dissolve, so nothing passing beneath can collide with it. This
/// sliver only reserves its space and retires the expanded hero.
///
/// The collapse is driven by the scroll offset, so it tracks the finger and
/// runs backwards on the way up. Under reduced motion the screen swaps this
/// sliver for a static hero that scrolls with the page.
class HomeCollapsingHero extends StatelessWidget {
  /// Creates the collapsing hero sliver.
  const HomeCollapsingHero({
    required this.offset,
    required this.snapshot,
    required this.isCurrentLocation,
    required this.format,
    required this.leadIn,
    super.key,
  });

  /// How far the page has been scrolled.
  final ValueListenable<double> offset;

  /// The reading on screen.
  final WeatherSnapshot snapshot;

  /// Whether this place is wherever the device is.
  final bool isCurrentLocation;

  /// Turns the reading into copy.
  final AuraFormat format;

  /// Held before the hero's entrance, while the sun sweeps its arc.
  final Duration leadIn;

  /// How much sky is kept clear above the hero, for the sun to cross.
  static const double skyBand = 120;

  /// The band the condensed bar floats in once the collapse completes.
  static const double condensedExtent = 72;

  /// The strip of sky below that band, where the cards dissolve away.
  static const double dissolveGap = 44;

  @override
  Widget build(BuildContext context) {
    final hero = Padding(
      padding: const EdgeInsets.only(
        left: AuraSpacing.xl,
        right: AuraSpacing.xl,
        bottom: AuraSpacing.xl,
      ),
      child: HomeHero(
        snapshot: snapshot,
        isCurrentLocation: isCurrentLocation,
        format: format,
      ),
    );

    return SliverResizingHeader(
      minExtentPrototype: const SizedBox(
        height: condensedExtent + dissolveGap,
      ),
      maxExtentPrototype: Padding(
        padding: const EdgeInsets.only(top: skyBand),
        child: ExcludeSemantics(child: hero),
      ),
      child: ValueListenableBuilder<double>(
        valueListenable: offset,
        builder: (context, value, child) => _HeroTransition(
          progress: (value / AuraMotion.heroCondenseRange).clamp(0.0, 1.0),
          child: child!,
        ),
        child: AuraEntrance(index: 0, leadIn: leadIn, child: hero),
      ),
    );
  }
}

/// One frame of the collapse, [progress] of the way through.
class _HeroTransition extends StatelessWidget {
  const _HeroTransition({required this.progress, required this.child});

  final double progress;
  final Widget child;

  /// Where the hero's fade begins and ends along the collapse.
  static const double _fadeFrom = 0.1;
  static const double _fadeUntil = 0.65;

  /// How far the hero shrinks by the time it is gone.
  static const double _shrink = 0.16;

  @override
  Widget build(BuildContext context) {
    final fadeOut = (1 - (progress - _fadeFrom) / (_fadeUntil - _fadeFrom))
        .clamp(0.0, 1.0);

    return Stack(
      children: <Widget>[
        Positioned(
          top: HomeCollapsingHero.skyBand * (1 - progress),
          left: 0,
          right: 0,
          child: ExcludeSemantics(
            excluding: fadeOut == 0,
            child: Opacity(
              opacity: fadeOut,
              child: Transform.scale(
                scale: 1 - _shrink * progress,
                alignment: Alignment.topCenter,
                child: child,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
