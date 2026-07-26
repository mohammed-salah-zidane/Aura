import 'package:aura_core/aura_core.dart';
import 'package:aura_design/aura_design.dart';
import 'package:aura_feature_details/src/details_view_model.dart';
import 'package:aura_feature_details/src/widgets/detail_scaffold.dart';
import 'package:aura_l10n/aura_l10n.dart';
import 'package:aura_ui/aura_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Builds a detail screen once the shared reading is in hand.
///
/// Every detail screen waits on the same feed, so the waiting, the failure and
/// the frame are written once and each screen supplies only its own cards.
class DetailHost extends ConsumerWidget {
  /// Creates a detail host.
  const DetailHost({
    required this.title,
    required this.sky,
    required this.onBack,
    required this.builder,
    super.key,
  });

  /// The screen's own title.
  final String title;

  /// Which sky it sits on, given the reading.
  final AuraSkyKind Function(DetailsUiState state) sky;

  /// Goes back.
  final VoidCallback onBack;

  /// The screen's cards.
  final List<Widget> Function(BuildContext context, DetailsUiState state)
  builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(detailsViewModelProvider).value;

    return switch (result) {
      null => const AuraSky(
        kind: AuraSkyKind.systemBrand,
        child: Center(child: AuraSkeleton.line(width: 160)),
      ),
      Err<DetailsUiState, AppFailure>(:final failure) => _Unavailable(
        failure: failure,
        title: title,
        onBack: onBack,
      ),
      Ok<DetailsUiState, AppFailure>(:final value) => DetailScaffold(
        sky: sky(value),
        place: value.place,
        title: title,
        onBack: onBack,
        children: builder(context, value),
      ),
    };
  }
}

/// The frame with a line where the cards would be.
class _Unavailable extends StatelessWidget {
  const _Unavailable({
    required this.failure,
    required this.title,
    required this.onBack,
  });

  final AppFailure failure;
  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final copy = AuraFailureCopy.of(context.l10n, failure);
    return DetailScaffold(
      sky: AuraSkyKind.systemBrand,
      place: copy.title,
      title: title,
      onBack: onBack,
      children: <Widget>[
        DetailCard(
          children: <Widget>[
            Text(
              copy.body,
              style: AuraText.bodySmall.copyWith(
                color: AuraColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
