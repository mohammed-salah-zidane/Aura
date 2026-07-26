import 'package:aura_core/aura_core.dart';
import 'package:aura_design/aura_design.dart';
import 'package:aura_domain/aura_domain.dart';
import 'package:aura_feature_search/src/search_ui_state.dart';
import 'package:aura_l10n/aura_l10n.dart';
import 'package:aura_providers/aura_providers.dart';
import 'package:aura_ui/aura_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The panel of matches, hairlined between rows.
///
/// The design draws matches and nothing else, so the loading and empty states
/// are the design system's own: a shimmer while the request is out, and a line
/// of copy when the service matched nothing.
class SearchResults extends ConsumerWidget {
  /// Creates the results panel.
  const SearchResults({
    required this.state,
    required this.onSelect,
    super.key,
  });

  /// What the search has found so far.
  final SearchUiState state;

  /// Called with the match the user picked.
  final ValueChanged<CitySuggestion> onSelect;

  /// How many placeholder rows stand in while the request is out.
  static const int _placeholderRows = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final units = ref.watch(unitPreferencesProvider).value;
    final format = AuraFormat(
      l10n: context.l10n,
      units: units ?? const UnitPreferences(),
    );

    return AuraGlass.flat(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AuraRadii.row),
        child: switch (state) {
          SearchUiState(isSearching: true, matches: []) =>
            const _Placeholders(),
          SearchUiState(isEmpty: true) => _Message(
            text: context.l10n.searchNoResults,
          ),
          SearchUiState(failure: final failure?) => _Message(
            text: failure is InvalidCity
                ? context.l10n.searchNoResults
                : AuraFailureCopy.of(context.l10n, failure).body,
          ),
          _ => ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: state.matches.length,
            separatorBuilder: (context, index) => const _Divider(),
            itemBuilder: (context, index) => _Row(
              match: state.matches[index],
              format: format,
              onTap: () => onSelect(state.matches[index].suggestion),
            ),
          ),
        },
      ),
    );
  }
}

/// One match: what it is called, where it is, and how warm it is.
class _Row extends StatelessWidget {
  const _Row({
    required this.match,
    required this.format,
    required this.onTap,
  });

  final SearchMatch match;
  final AuraFormat format;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final suggestion = match.suggestion;
    final reading = match.reading;
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          color: AuraColors.transparent,
          padding: const EdgeInsets.symmetric(
            vertical: 15,
            horizontal: AuraSpacing.lg,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: AuraSpacing.hairline,
                  children: <Widget>[
                    Text(
                      suggestion.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AuraText.searchResultCity.copyWith(
                        color: AuraColors.textPrimary,
                      ),
                    ),
                    Text(
                      _place(suggestion),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AuraText.caption.copyWith(
                        color: AuraColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              if (reading != null)
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                    start: AuraSpacing.md,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: AuraSpacing.smPlus,
                    children: <Widget>[
                      Icon(
                        AuraConditionVisuals.icon(reading.current.condition),
                        size: AuraSizes.iconMedium,
                        color: AuraConditionVisuals.tint(
                          reading.current.condition,
                        ),
                      ),
                      Text(
                        format.temperature(reading.current.temperature),
                        style: AuraText.searchResultTemperature.copyWith(
                          color: AuraColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// The region and the country, or just the country when the service gave no
  /// region, which is what it does for a capital.
  static String _place(CitySuggestion suggestion) => suggestion.region.isEmpty
      ? suggestion.country
      : '${suggestion.region}, ${suggestion.country}';
}

/// The hairline between two matches.
class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: AuraSizes.divider,
      child: ColoredBox(color: AuraColors.glass),
    );
  }
}

/// Shimmering stand-ins while the request is out.
class _Placeholders extends StatelessWidget {
  const _Placeholders();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (var row = 0; row < SearchResults._placeholderRows; row++) ...[
          if (row > 0) const _Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(
              vertical: 15,
              horizontal: AuraSpacing.lg,
            ),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: AuraSkeleton.line(width: 160, height: 18),
            ),
          ),
        ],
      ],
    );
  }
}

/// A single line where the list would be.
class _Message extends StatelessWidget {
  const _Message({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 15,
        horizontal: AuraSpacing.lg,
      ),
      child: Text(
        text,
        style: AuraText.caption.copyWith(color: AuraColors.textSecondary),
      ),
    );
  }
}
