import 'package:aura_design/aura_design.dart';
import 'package:aura_l10n/aura_l10n.dart';
import 'package:flutter/widgets.dart';

/// Everywhere the weather screen can take you, and the wordmark between them.
///
/// The pen splits these across two bars: the brand and settings at the top, and
/// search and the saved list at the foot of a page that runs to about 1500
/// points. On a phone that put half the app's navigation below three screens of
/// scrolling. They are one bar now, at the top, where they are on screen the
/// moment the app opens.
///
/// The wordmark sits between them rather than beside them. Both side slots take
/// the same width, so it is centred on the screen rather than on whatever is
/// left over.
///
/// The pen's page dots are gone with the second bar. Their only job was to say
/// which place was showing, and the kicker under them already says it by name.
class HomeTopBar extends StatelessWidget {
  /// Creates the top bar.
  const HomeTopBar({
    required this.onOpenSearch,
    required this.onOpenSavedCities,
    required this.onOpenSettings,
    super.key,
  });

  /// Opens search.
  final VoidCallback onOpenSearch;

  /// Opens the saved list.
  final VoidCallback onOpenSavedCities;

  /// Opens settings.
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      children: <Widget>[
        Expanded(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: AuraSpacing.sm,
            children: <Widget>[
              _Action(
                icon: AuraIcons.search,
                label: l10n.homeSearch,
                onTap: onOpenSearch,
              ),
              _Action(
                icon: AuraIcons.list,
                label: l10n.homeSavedCities,
                onTap: onOpenSavedCities,
              ),
            ],
          ),
        ),
        const _Wordmark(),
        Expanded(
          child: Align(
            alignment: AlignmentDirectional.centerEnd,
            child: _Action(
              icon: AuraIcons.settings,
              label: l10n.homeSettings,
              onTap: onOpenSettings,
            ),
          ),
        ),
      ],
    );
  }
}

/// The mark and the name, as the splash sets them.
class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: AuraSpacing.sm,
      children: <Widget>[
        const AuraMark(size: AuraMarkSize.brandBar),
        Text(
          AuraBrand.name,
          style: AuraText.wordmarkSmall.copyWith(
            color: AuraColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

/// One glyph on the bar, on the design's round glass.
class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AuraCircleButton(
      icon: icon,
      semanticLabel: label,
      onPressed: onTap,
    );
  }
}
