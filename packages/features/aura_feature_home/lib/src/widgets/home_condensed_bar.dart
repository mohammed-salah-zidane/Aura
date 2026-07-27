import 'package:aura_design/aura_design.dart';
import 'package:aura_l10n/aura_l10n.dart';
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/widgets.dart';

/// The bar that takes over once the hero has scrolled away.
///
/// The pen draws navigation at the top of the page and repeats it at the foot,
/// about 1500 points down. Both were put in one bar at the top, which left a
/// real problem: scroll past the hero and the app has no navigation and no
/// label saying which place you are looking at.
///
/// This is the answer. It carries the same three destinations as the top bar
/// and the place and temperature the hero was showing, and it is **not built at
/// all** until the page has scrolled. At rest the tree is exactly what it was,
/// so the frame stays the pen's and the goldens hold it to that.
class HomeCondensedBar extends StatelessWidget {
  /// Creates the condensed bar.
  const HomeCondensedBar({
    required this.offset,
    required this.placeName,
    required this.temperature,
    required this.onOpenSearch,
    required this.onOpenSavedCities,
    required this.onOpenSettings,
    super.key,
  });

  /// How far the page has scrolled.
  final ValueListenable<double> offset;

  /// The place the reading is for.
  final String placeName;

  /// The temperature, already formatted in the active units.
  final String temperature;

  /// Opens search.
  final VoidCallback onOpenSearch;

  /// Opens the saved list.
  final VoidCallback onOpenSavedCities;

  /// Opens settings.
  final VoidCallback onOpenSettings;

  /// Where the bar starts appearing, and where it is fully there.
  ///
  /// It begins after the top bar itself has left, so the two are never on
  /// screen together saying the same thing.
  static const double _from = 96;
  static const double _to = 168;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: offset,
      builder: (context, value, _) {
        final shown = ((value - _from) / (_to - _from)).clamp(0.0, 1.0);
        if (shown <= 0) return const SizedBox.shrink();
        return Align(
          alignment: Alignment.topCenter,
          child: Opacity(
            opacity: shown,
            child: _Bar(
              placeName: placeName,
              temperature: temperature,
              onOpenSearch: onOpenSearch,
              onOpenSavedCities: onOpenSavedCities,
              onOpenSettings: onOpenSettings,
            ),
          ),
        );
      },
    );
  }
}

/// The bar itself, on the glass the design system already defines.
class _Bar extends StatelessWidget {
  const _Bar({
    required this.placeName,
    required this.temperature,
    required this.onOpenSearch,
    required this.onOpenSavedCities,
    required this.onOpenSettings,
  });

  final String placeName;
  final String temperature;
  final VoidCallback onOpenSearch;
  final VoidCallback onOpenSavedCities;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: EdgeInsets.only(
        top: MediaQuery.paddingOf(context).top + AuraSpacing.sm,
        left: AuraSpacing.xl,
        right: AuraSpacing.xl,
      ),
      child: AuraGlass(
        radius: AuraRadii.pill,
        padding: const EdgeInsets.symmetric(
          horizontal: AuraSpacing.md,
          vertical: AuraSpacing.sm,
        ),
        child: Row(
          spacing: AuraSpacing.sm,
          children: <Widget>[
            AuraCircleButton(
              icon: AuraIcons.search,
              semanticLabel: l10n.homeSearch,
              onPressed: onOpenSearch,
            ),
            AuraCircleButton(
              icon: AuraIcons.list,
              semanticLabel: l10n.homeSavedCities,
              onPressed: onOpenSavedCities,
            ),
            Expanded(
              child: MergeSemantics(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  spacing: AuraSpacing.sm,
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        placeName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: AuraText.titleScreen.copyWith(
                          color: AuraColors.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      temperature,
                      maxLines: 1,
                      style: AuraText.valueCompact.copyWith(
                        color: AuraColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AuraCircleButton(
              icon: AuraIcons.settings,
              semanticLabel: l10n.homeSettings,
              onPressed: onOpenSettings,
            ),
          ],
        ),
      ),
    );
  }
}
