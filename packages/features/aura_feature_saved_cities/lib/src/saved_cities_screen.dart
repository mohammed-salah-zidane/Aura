import 'package:aura_design/aura_design.dart';
import 'package:aura_domain/aura_domain.dart';
import 'package:aura_feature_saved_cities/src/saved_cities_view_model.dart';
import 'package:aura_l10n/aura_l10n.dart';
import 'package:aura_providers/aura_providers.dart';
import 'package:aura_ui/aura_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The places the user keeps, with the device's own position at the top.
///
/// Built from the `State · Saved Cities` frame. Tapping a card makes that
/// place the one home shows.
class SavedCitiesScreen extends ConsumerStatefulWidget {
  /// Creates the saved cities screen.
  const SavedCitiesScreen({
    required this.onOpenSearch,
    required this.onSelect,
    required this.onBack,
    super.key,
  });

  /// Opens search.
  final VoidCallback onOpenSearch;

  /// Leaves the screen once a place has been picked.
  final VoidCallback onSelect;

  /// Leaves the screen with nothing picked.
  ///
  /// The design draws this screen with an overflow button and no way back,
  /// which works on a canvas and strands a user on a device.
  final VoidCallback onBack;

  @override
  ConsumerState<SavedCitiesScreen> createState() => _SavedCitiesScreenState();
}

class _SavedCitiesScreenState extends ConsumerState<SavedCitiesScreen> {
  /// Whether the remove controls are showing.
  ///
  /// The overflow button in the design has no menu drawn behind it, and the
  /// list needs a way to forget a place, so it turns this on instead. The
  /// button only appears when there is a place that can be forgotten: the
  /// device's own position cannot, so on a list holding nothing else the
  /// button would change its own glyph and nothing more.
  bool _isEditing = false;

  /// The pen's `Content` padding on this frame.
  static const EdgeInsets _padding = EdgeInsets.fromLTRB(
    AuraSpacing.xl,
    AuraSpacing.xs,
    AuraSpacing.xl,
    AuraSpacing.xxl,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final rows = ref.watch(savedCitiesViewModelProvider).value;
    final units =
        ref.watch(unitPreferencesProvider).value ?? const UnitPreferences();
    final format = AuraFormat(l10n: l10n, units: units);
    final canEdit =
        rows?.any((row) => !row.isCurrentLocation && row.snapshot != null) ??
        false;
    final isEditing = _isEditing && canEdit;

    return AuraSky(
      kind: AuraSkyKind.systemBrand,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: _padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AuraSpacing.mdPlus,
            children: <Widget>[
              Row(
                children: <Widget>[
                  AuraCircleButton(
                    icon: AuraChevron.back(context),
                    size: AuraCircleButtonSize.back,
                    semanticLabel: l10n.commonBack,
                    onPressed: widget.onBack,
                  ),
                  const SizedBox(width: AuraSpacing.md),
                  Expanded(
                    child: Text(
                      l10n.savedCitiesTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AuraText.titleLarge.copyWith(
                        color: AuraColors.textPrimary,
                      ),
                    ),
                  ),
                  if (canEdit)
                    AuraCircleButton(
                      icon: isEditing ? AuraIcons.close : AuraIcons.more,
                      semanticLabel: isEditing
                          ? l10n.savedCitiesDone
                          : l10n.savedCitiesEdit,
                      onPressed: () => setState(() => _isEditing = !_isEditing),
                    ),
                ],
              ),
              AuraSearchField(
                placeholder: l10n.searchPlaceholder,
                onTap: widget.onOpenSearch,
              ),
              Expanded(
                child: rows == null
                    ? const _Placeholders()
                    : _CityList(
                        rows: rows,
                        format: format,
                        isEditing: isEditing,
                        onSelect: _select,
                        onRemove: (location) => ref
                            .read(savedCitiesViewModelProvider.notifier)
                            .remove(location),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _select(SavedCityRow row) {
    ref.read(activeLocationProvider.notifier).location = row.location;
    widget.onSelect();
  }
}

/// The cards, or the line that says there are none.
class _CityList extends StatelessWidget {
  const _CityList({
    required this.rows,
    required this.format,
    required this.isEditing,
    required this.onSelect,
    required this.onRemove,
  });

  final List<SavedCityRow> rows;
  final AuraFormat format;
  final bool isEditing;
  final ValueChanged<SavedCityRow> onSelect;
  final ValueChanged<LocationRef> onRemove;

  @override
  Widget build(BuildContext context) {
    if (rows.length <= 1 && rows.every((row) => row.snapshot == null)) {
      return Align(
        alignment: AlignmentDirectional.topStart,
        child: Text(
          context.l10n.savedCitiesEmpty,
          style: AuraText.caption.copyWith(color: AuraColors.textSecondary),
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: rows.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AuraSpacing.mdPlus),
      itemBuilder: (context, index) => _Card(
        row: rows[index],
        format: format,
        // The device's own position is not a kept place, so there is nothing
        // to forget about it.
        isEditing: isEditing && !rows[index].isCurrentLocation,
        onSelect: () => onSelect(rows[index]),
        onRemove: () => onRemove(rows[index].location),
      ),
    );
  }
}

/// One place's card, or a shimmer while its reading is on its way.
class _Card extends StatelessWidget {
  const _Card({
    required this.row,
    required this.format,
    required this.isEditing,
    required this.onSelect,
    required this.onRemove,
  });

  final SavedCityRow row;
  final AuraFormat format;
  final bool isEditing;
  final VoidCallback onSelect;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final snapshot = row.snapshot;
    if (snapshot == null) {
      return const AuraSkeleton(
        width: double.infinity,
        height: AuraSizes.cityCardHeight,
        radius: AuraRadii.card,
      );
    }

    final today = snapshot.today;
    return AuraCityCard(
      city: snapshot.placeName,
      localTime: row.isCurrentLocation
          ? l10n.savedCityCurrentTime(format.timeOfDay(snapshot.localTime))
          : format.timeOfDay(snapshot.localTime),
      condition: snapshot.current.conditionText,
      temperature: format.temperature(snapshot.current.temperature),
      highLow: format.highLow(today.high, today.low),
      sky: AuraConditionVisuals.sky(snapshot.current.condition),
      onTap: onSelect,
      onRemove: isEditing ? onRemove : null,
      removeSemanticLabel: l10n.savedCitiesRemove(snapshot.placeName),
    );
  }
}

/// Shimmering stand-ins while the first readings are on their way.
class _Placeholders extends StatelessWidget {
  const _Placeholders();

  static const int _rows = 3;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AuraSpacing.mdPlus,
      children: <Widget>[
        for (var row = 0; row < _rows; row++)
          const AuraSkeleton(
            width: double.infinity,
            height: AuraSizes.cityCardHeight,
            radius: AuraRadii.card,
          ),
      ],
    );
  }
}
