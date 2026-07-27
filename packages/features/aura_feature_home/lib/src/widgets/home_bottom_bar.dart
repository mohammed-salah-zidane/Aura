import 'package:aura_design/aura_design.dart';
import 'package:aura_l10n/aura_l10n.dart';
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/widgets.dart';

/// The floating navigation, and the dots saying which place is showing.
///
/// The pen draws navigation twice: the brand and settings at the top, and
/// search, the saved list and a row of page dots at the foot of a page that
/// runs to about 1500 points. An earlier pass merged both into one top bar,
/// which put the buttons exactly where the sky is brightest and where the sun
/// now sits.
///
/// This is the pen's own second bar, restored and floated. The content runs
/// underneath it rather than stopping short, and a scrim fades the cards out
/// as they pass behind so nothing collides with a glyph.
class HomeBottomBar extends StatelessWidget {
  /// Creates the floating bar.
  const HomeBottomBar({
    required this.isVisible,
    required this.placeCount,
    required this.placeIndex,
    required this.onOpenSearch,
    required this.onOpenSavedCities,
    required this.onOpenSettings,
    super.key,
  });

  /// Whether the bar is currently on screen.
  final ValueListenable<bool> isVisible;

  /// How many places can be paged through, including the current location.
  final int placeCount;

  /// Which of them is showing.
  final int placeIndex;

  /// Opens search.
  final VoidCallback onOpenSearch;

  /// Opens the saved list.
  final VoidCallback onOpenSavedCities;

  /// Opens settings.
  final VoidCallback onOpenSettings;

  /// How far the bar drops as it leaves.
  static const double _travel = 120;

  /// How tall the scrim under the bar is.
  static const double scrimHeight = 148;

  @override
  Widget build(BuildContext context) {
    // Positioned rather than Align: a non-positioned Stack child is given
    // loose constraints, and a decorated box under them grows to fill the
    // whole screen rather than wrapping its row.
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: ValueListenableBuilder<bool>(
        valueListenable: isVisible,
        builder: (context, visible, child) => IgnorePointer(
          ignoring: !visible,
          child: AnimatedSlide(
            offset: Offset(0, visible ? 0 : _travel / scrimHeight),
            duration: AuraMotion.content,
            curve: AuraMotion.skyCurve,
            child: AnimatedOpacity(
              opacity: visible ? 1 : 0,
              duration: AuraMotion.content,
              curve: AuraMotion.controlCurve,
              child: child,
            ),
          ),
        ),
        child: _Bar(
          placeCount: placeCount,
          placeIndex: placeIndex,
          onOpenSearch: onOpenSearch,
          onOpenSavedCities: onOpenSavedCities,
          onOpenSettings: onOpenSettings,
        ),
      ),
    );
  }
}

/// Fades the content out under the bar, so a card never meets a glyph.
///
/// This is the piece that makes a floating bar work at all. Without it the
/// cards run under the glass and the two read as one crowded surface, which is
/// what sent the navigation to the top in the first place.
class HomeBottomScrim extends StatelessWidget {
  /// Creates the scrim.
  const HomeBottomScrim({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: IgnorePointer(
        child: SizedBox(
          height: HomeBottomBar.scrimHeight,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  AuraColors.ink2.withValues(alpha: 0),
                  AuraColors.ink2.withValues(alpha: 0.42),
                  AuraColors.ink2.withValues(alpha: 0.82),
                ],
                stops: const <double>[0, 0.5, 1],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.placeCount,
    required this.placeIndex,
    required this.onOpenSearch,
    required this.onOpenSavedCities,
    required this.onOpenSettings,
  });

  final int placeCount;
  final int placeIndex;
  final VoidCallback onOpenSearch;
  final VoidCallback onOpenSavedCities;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: EdgeInsets.only(
        left: AuraSpacing.xl,
        right: AuraSpacing.xl,
        bottom: MediaQuery.paddingOf(context).bottom + AuraSpacing.md,
      ),
      child: AuraGlass(
        radius: AuraRadii.pill,
        level: AuraGlassLevel.elevated,
        shadow: AuraShadows.panel,
        padding: const EdgeInsets.symmetric(
          horizontal: AuraSpacing.lg,
          vertical: AuraSpacing.md,
        ),
        // Search on one side, the two list actions together on the other, and
        // the dots holding the middle. With one place there are no dots, and
        // the middle collapses to space rather than leaving a gap where
        // something used to be.
        child: Row(
          children: <Widget>[
            AuraCircleButton(
              icon: AuraIcons.search,
              semanticLabel: l10n.homeSearch,
              onPressed: onOpenSearch,
            ),
            Expanded(
              child: Center(
                child: HomePageDots(count: placeCount, index: placeIndex),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              spacing: AuraSpacing.sm,
              children: <Widget>[
                AuraCircleButton(
                  icon: AuraIcons.list,
                  semanticLabel: l10n.homeSavedCities,
                  onPressed: onOpenSavedCities,
                ),
                AuraCircleButton(
                  icon: AuraIcons.settings,
                  semanticLabel: l10n.homeSettings,
                  onPressed: onOpenSettings,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// One dot per place, with the current one drawn as a pill.
///
/// The pen draws these at the foot of the weather page. They are the only
/// thing on screen that says how many places there are to move between, which
/// is what makes the swipe discoverable at all.
class HomePageDots extends StatelessWidget {
  /// Creates the row of dots.
  const HomePageDots({required this.count, required this.index, super.key});

  /// How many places there are.
  final int count;

  /// Which one is showing.
  final int index;

  @override
  Widget build(BuildContext context) {
    // One place is not a set to page through, so the row says nothing.
    if (count < 2) return const SizedBox.shrink();

    return Semantics(
      label: context.l10n.homePlaceOfPlaces(index + 1, count),
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: AuraSpacing.xs,
        children: <Widget>[
          for (var i = 0; i < count; i++)
            AnimatedContainer(
              duration: AuraMotion.control,
              curve: AuraMotion.controlCurve,
              width: i == index ? AuraSizes.pagerCurrent : AuraSizes.pagerDot,
              height: AuraSizes.pagerDot,
              decoration: BoxDecoration(
                color: AuraColors.textPrimary.withValues(
                  alpha: i == index ? 1 : 0.35,
                ),
                borderRadius: BorderRadius.circular(AuraRadii.pill),
              ),
            ),
        ],
      ),
    );
  }
}
