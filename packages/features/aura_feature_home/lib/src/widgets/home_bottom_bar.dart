import 'package:aura_design/aura_design.dart';
import 'package:aura_feature_home/src/widgets/home_page_dots.dart';
import 'package:aura_l10n/aura_l10n.dart';
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/widgets.dart';

/// The navigation at the foot of the page, drawn the way the pen draws it.
///
/// The pen's `Bottom Bar` is three loose pieces on the sky, with no panel
/// behind them: search on one side, the saved list on the other, and a
/// `Pages` group in the middle carrying a location arrow for the device's own
/// page and a dot for every saved place. The scrim underneath is what keeps
/// them legible; wrapping them in glass put a stroked pill across the sky
/// that the design never drew.
///
/// Settings joins the list on the trailing side because the top bar that used
/// to hold it is gone.
class HomeBottomBar extends StatelessWidget {
  /// Creates the floating bar.
  const HomeBottomBar({
    required this.isVisible,
    required this.placeCount,
    required this.placeIndex,
    required this.leadsWithCurrentLocation,
    required this.isRefreshing,
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

  /// Whether the first page is the device's own position, which the pen marks
  /// with an arrow rather than a dot.
  final bool leadsWithCurrentLocation;

  /// Whether a refresh is in flight, which the mark beside the dots wears.
  final bool isRefreshing;

  /// Opens search.
  final VoidCallback onOpenSearch;

  /// Opens the saved list.
  final VoidCallback onOpenSavedCities;

  /// Opens settings.
  final VoidCallback onOpenSettings;

  /// How far the bar drops as it leaves.
  static const double _travel = 120;

  /// How tall the scrim under the bar is.
  static const double scrimHeight = 168;

  /// The band the bar's row occupies above the safe area, which a screen
  /// pinning its own actions at the foot has to stay clear of.
  static const double clearance =
      AuraSizes.iconBottomBar + 2 * AuraSpacing.mdPlus + AuraSpacing.sm;

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
          leadsWithCurrentLocation: leadsWithCurrentLocation,
          isRefreshing: isRefreshing,
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
/// With no panel behind the buttons, this wash is the only thing keeping them
/// legible, so it runs deeper than it is tall: a long quiet ramp and a firm
/// foot rather than a hard band.
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
                  AuraColors.ink2.withValues(alpha: 0.18),
                  AuraColors.ink2.withValues(alpha: 0.52),
                  AuraColors.ink2.withValues(alpha: 0.86),
                ],
                stops: const <double>[0, 0.35, 0.68, 1],
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
    required this.leadsWithCurrentLocation,
    required this.isRefreshing,
    required this.onOpenSearch,
    required this.onOpenSavedCities,
    required this.onOpenSettings,
  });

  final int placeCount;
  final int placeIndex;
  final bool leadsWithCurrentLocation;
  final bool isRefreshing;
  final VoidCallback onOpenSearch;
  final VoidCallback onOpenSavedCities;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // The pen insets the glyphs 30 points from the screen edge: 16 here plus
    // the 14 each pressable carries as its touch target.
    return Padding(
      padding: EdgeInsets.only(
        left: AuraSpacing.lg,
        right: AuraSpacing.lg,
        bottom: MediaQuery.paddingOf(context).bottom + AuraSpacing.sm,
      ),
      child: Row(
        children: <Widget>[
          _BarButton(
            icon: AuraIcons.search,
            semanticLabel: l10n.homeSearch,
            onPressed: onOpenSearch,
          ),
          Expanded(
            child: Center(
              child: HomePages(
                count: placeCount,
                index: placeIndex,
                leadsWithCurrentLocation: leadsWithCurrentLocation,
                isRefreshing: isRefreshing,
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _BarButton(
                icon: AuraIcons.list,
                semanticLabel: l10n.homeSavedCities,
                onPressed: onOpenSavedCities,
              ),
              _BarButton(
                icon: AuraIcons.settings,
                semanticLabel: l10n.homeSettings,
                onPressed: onOpenSettings,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A bare glyph with the touch target the pen does not have to draw.
class _BarButton extends StatelessWidget {
  const _BarButton({
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return AuraPressable.child(
      onPressed: onPressed,
      semanticLabel: semanticLabel,
      haptic: true,
      child: Padding(
        padding: const EdgeInsets.all(AuraSpacing.mdPlus),
        child: Icon(
          icon,
          size: AuraSizes.iconBottomBar,
          color: AuraColors.textSecondary,
        ),
      ),
    );
  }
}
