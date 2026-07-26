import 'package:aura_design/aura_design.dart';
import 'package:aura_feature_search/src/search_view_model.dart';
import 'package:aura_feature_search/src/widgets/search_results.dart';
import 'package:aura_l10n/aura_l10n.dart';
import 'package:aura_providers/aura_providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Finds a place to show the weather for.
///
/// Built from the `State · Search` frame. Picking a match makes it the active
/// place and keeps it in the saved list, so a place the user looked up once is
/// there the next time without a second search.
class SearchScreen extends ConsumerWidget {
  /// Creates the search screen.
  const SearchScreen({required this.onDone, super.key});

  /// Leaves the screen, whether a place was picked or not.
  final VoidCallback onDone;

  /// The pen's `Content` padding on this frame.
  static const EdgeInsets _padding = EdgeInsets.fromLTRB(
    AuraSpacing.xl,
    AuraSpacing.sm,
    AuraSpacing.xl,
    AuraSpacing.xxl,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(searchViewModelProvider);
    final viewModel = ref.read(searchViewModelProvider.notifier);

    return AuraSky(
      kind: AuraSkyKind.systemBrand,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: _padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AuraSpacing.lg,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    l10n.searchTitle,
                    style: AuraText.titleState.copyWith(
                      color: AuraColors.textPrimary,
                    ),
                  ),
                  AuraCircleButton(
                    icon: AuraIcons.close,
                    semanticLabel: l10n.searchClose,
                    onPressed: onDone,
                  ),
                ],
              ),
              AuraSearchField(
                variant: AuraSearchFieldVariant.active,
                placeholder: l10n.searchPlaceholder,
                clearSemanticLabel: l10n.searchClear,
                autofocus: true,
                onChanged: viewModel.query,
              ),
              _UseCurrentLocation(
                onTap: () async {
                  await viewModel.useCurrentLocation();
                  onDone();
                },
              ),
              if (state.hasQuery) ...<Widget>[
                Text(
                  l10n.searchResultsLabel.toUpperCase(),
                  style: AuraText.sectionLabel
                      .forScript(context)
                      .copyWith(color: AuraColors.textTertiary),
                ),
                Expanded(
                  child: SearchResults(
                    state: state,
                    onSelect: (suggestion) async {
                      ref.read(activeLocationProvider.notifier).location =
                          suggestion.location;
                      await viewModel.save(suggestion);
                      onDone();
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The row that reads the weather for wherever the device is.
class _UseCurrentLocation extends StatelessWidget {
  const _UseCurrentLocation({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: AuraGlass.flat(
          radius: AuraRadii.button,
          padding: const EdgeInsets.symmetric(
            vertical: AuraSpacing.mdPlus,
            horizontal: AuraSpacing.lg,
          ),
          child: Row(
            spacing: AuraSpacing.md,
            children: <Widget>[
              const Icon(
                AuraIcons.locateFixed,
                size: AuraSizes.iconUi,
                color: AuraColors.accent,
              ),
              Expanded(
                child: Text(
                  context.l10n.searchUseCurrentLocation,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AuraText.rowLabel.copyWith(
                    color: AuraColors.textPrimary,
                  ),
                ),
              ),
              const Icon(
                AuraIcons.chevronRight,
                size: AuraSizes.iconSmall,
                color: AuraColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
