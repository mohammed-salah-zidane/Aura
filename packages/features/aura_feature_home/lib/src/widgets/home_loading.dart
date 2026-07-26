import 'package:aura_design/aura_design.dart';
import 'package:aura_l10n/aura_l10n.dart';
import 'package:flutter/widgets.dart';

/// The screen while the first reading is on its way.
///
/// Built from the `State · Loading` frame: the place's name with a spinner
/// beside it, then a shimmering stand-in for every block that is coming.
class HomeLoading extends StatelessWidget {
  /// Creates the loading screen.
  const HomeLoading({required this.placeName, super.key});

  /// What to call the place before its reading arrives. Empty when the app
  /// does not know yet, which is what a first run from the device's own
  /// position looks like.
  final String placeName;

  /// The pen's `Content` padding on this frame.
  static const EdgeInsets _padding = EdgeInsets.fromLTRB(
    AuraSpacing.xl,
    AuraSpacing.sm,
    AuraSpacing.xl,
    AuraSpacing.xl,
  );

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: _padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AuraSpacing.lgPlus,
          children: <Widget>[
            _Heading(placeName: placeName),
            const _HeroPlaceholder(),
            const AuraSkeleton(
              width: double.infinity,
              height: AuraSizes.skeletonHourly,
              radius: AuraRadii.panel,
            ),
            const _GridPlaceholder(),
          ],
        ),
      ),
    );
  }
}

/// The place's name, and the spinner marking the request as in flight.
class _Heading extends StatelessWidget {
  const _Heading({required this.placeName});

  final String placeName;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AuraSpacing.xxs,
            children: <Widget>[
              if (placeName.isNotEmpty)
                Text(
                  placeName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AuraText.titleScreen.copyWith(
                    color: AuraColors.textPrimary,
                  ),
                ),
              Text(
                context.l10n.homeLoadingStatus,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AuraText.chip.copyWith(
                  color: AuraColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
        const _Spinner(),
      ],
    );
  }
}

/// The gold ring, turning while the request is out.
///
/// A spinner is right here and a shimmer is not: the shimmer stands for
/// content that is arriving, and this stands for the request itself.
class _Spinner extends StatefulWidget {
  const _Spinner();

  @override
  State<_Spinner> createState() => _SpinnerState();
}

class _SpinnerState extends State<_Spinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AuraMotion.shimmer,
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: const Icon(
        AuraIcons.loader,
        size: AuraSizes.iconSpinner,
        color: AuraColors.accent,
      ),
    );
  }
}

/// Stand-ins for the kicker, the temperature and the condition.
class _HeroPlaceholder extends StatelessWidget {
  const _HeroPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AuraSpacing.xxlPlus),
      child: Column(
        spacing: AuraSpacing.mdPlus,
        children: <Widget>[
          AuraSkeleton(
            width: AuraSizes.skeletonKickerWidth,
            height: AuraSizes.skeletonKickerHeight,
            radius: AuraRadii.pill,
          ),
          AuraSkeleton(
            width: AuraSizes.skeletonHeroWidth,
            height: AuraSizes.skeletonHeroHeight,
            radius: AuraRadii.button,
          ),
          AuraSkeleton(
            width: AuraSizes.skeletonConditionWidth,
            height: AuraSizes.skeletonConditionHeight,
            radius: AuraRadii.pill,
          ),
        ],
      ),
    );
  }
}

/// Stand-ins for the six metric cards.
class _GridPlaceholder extends StatelessWidget {
  const _GridPlaceholder();

  static const int _rows = 3;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AuraSpacing.md,
      children: <Widget>[
        for (var row = 0; row < _rows; row++)
          const Row(
            spacing: AuraSpacing.md,
            children: <Widget>[
              Expanded(child: _Tile()),
              Expanded(child: _Tile()),
            ],
          ),
      ],
    );
  }
}

/// One card-shaped placeholder.
class _Tile extends StatelessWidget {
  const _Tile();

  @override
  Widget build(BuildContext context) {
    return const AuraSkeleton(
      width: double.infinity,
      height: AuraSizes.skeletonMetric,
      radius: AuraRadii.card,
    );
  }
}
