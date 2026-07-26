import 'package:aura_design/aura_design.dart';
import 'package:aura_l10n/aura_l10n.dart';
import 'package:flutter/widgets.dart';

/// Search, the page indicator, and the saved list.
///
/// The pen draws the indicator as a filled glyph for the current-location page
/// and a dot for each of the places beside it. It is an indicator rather than a
/// control in the design, so tapping it opens the list that does the switching.
class HomeBottomBar extends StatelessWidget {
  /// Creates the bottom bar.
  const HomeBottomBar({
    required this.savedCityCount,
    required this.activeIndex,
    required this.onOpenSearch,
    required this.onOpenSavedCities,
    super.key,
  });

  /// How many places sit beside the current location.
  final int savedCityCount;

  /// Which page is showing. Zero is the current location.
  final int activeIndex;

  /// Opens search.
  final VoidCallback onOpenSearch;

  /// Opens the saved list.
  final VoidCallback onOpenSavedCities;

  /// The pen's `Bottom Bar` padding.
  static const EdgeInsets _padding = EdgeInsets.fromLTRB(
    AuraSpacing.smPlus,
    AuraSpacing.mdPlus,
    AuraSpacing.smPlus,
    AuraSpacing.hairline,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: _padding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          _BarButton(
            icon: AuraIcons.search,
            label: l10n.homeSearch,
            onTap: onOpenSearch,
          ),
          Semantics(
            button: true,
            label: l10n.homeSavedCities,
            child: GestureDetector(
              onTap: onOpenSavedCities,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: AuraSpacing.sm,
                children: <Widget>[
                  Icon(
                    AuraIcons.navigation,
                    size: AuraSizes.pagerCurrent,
                    color: activeIndex == 0
                        ? AuraColors.textPrimary
                        : AuraColors.textTertiary,
                  ),
                  for (var page = 1; page <= savedCityCount; page++)
                    _PageDot(isActive: page == activeIndex),
                ],
              ),
            ),
          ),
          _BarButton(
            icon: AuraIcons.list,
            label: l10n.homeSavedCities,
            onTap: onOpenSavedCities,
          ),
        ],
      ),
    );
  }
}

/// One place beside the current location.
class _PageDot extends StatelessWidget {
  const _PageDot({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: AuraSizes.pagerDot,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isActive ? AuraColors.textPrimary : AuraColors.textTertiary,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

/// A glyph on the bar, with the label a screen reader hears instead.
class _BarButton extends StatelessWidget {
  const _BarButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Icon(
          icon,
          size: AuraSizes.iconBottomBar,
          color: AuraColors.textSecondary,
        ),
      ),
    );
  }
}
