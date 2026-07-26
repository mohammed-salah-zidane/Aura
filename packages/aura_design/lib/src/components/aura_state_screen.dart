import 'package:aura_design/src/foundations/aura_glass.dart';
import 'package:aura_design/src/foundations/aura_script.dart';
import 'package:aura_design/src/tokens/aura_colors.dart';
import 'package:aura_design/src/tokens/aura_metrics.dart';
import 'package:aura_design/src/tokens/aura_typography.dart';
import 'package:flutter/widgets.dart';

/// The layout every full-screen state in `aura.pen` shares.
///
/// The permission and offline frames are the same composition down to the
/// point: content padded 20 above, 24 either side and 30 below, an 88 point
/// glass disc 90 points down, then the heading, then body copy set to a 300
/// point measure, with the actions pushed to the foot of the screen.
///
/// It paints no sky of its own, so a caller decides which sky it sits on.
class AuraStateScreen extends StatelessWidget {
  /// Creates a full-screen state.
  const AuraStateScreen({
    required this.icon,
    required this.title,
    required this.body,
    required this.actions,
    this.note,
    this.iconColor = AuraColors.accent,
    super.key,
  });

  /// Glyph inside the disc.
  final IconData icon;

  /// Heading under the disc.
  final String title;

  /// The reason the user is looking at this screen.
  final String body;

  /// What the user can do about it, primary action first.
  final List<Widget> actions;

  /// An optional chip under the body, naming what the app already has.
  ///
  /// Only the offline frame carries one, where it says how old the cached
  /// reading is. Absent everywhere else.
  final Widget? note;

  /// Tint for [icon]. Gold when the state invites an action, muted when it
  /// reports a problem.
  final Color iconColor;

  /// The `Content` frame's padding. The bottom is measured from the screen
  /// edge; see [AuraSizes.stateBottomInset].
  static const EdgeInsets _contentPadding = EdgeInsets.fromLTRB(
    AuraSpacing.xxl,
    AuraSpacing.xl,
    AuraSpacing.xxl,
    AuraSizes.stateBottomInset,
  );

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: _contentPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // The `Top` frame carries 4 points of its own side padding.
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AuraSpacing.xxs,
              ),
              child: _Explanation(
                icon: icon,
                iconColor: iconColor,
                title: title,
                body: body,
                note: note,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AuraSpacing.md,
              children: actions,
            ),
          ],
        ),
      ),
    );
  }
}

/// The disc, the heading and the body, stacked and centred.
class _Explanation extends StatelessWidget {
  const _Explanation({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
    required this.note,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;
  final Widget? note;

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: AuraSpacing.lg,
      children: <Widget>[
        const SizedBox(height: AuraSizes.stateHeadroom - AuraSpacing.lg),
        AuraGlass(
          width: AuraSizes.stateIconDisc,
          height: AuraSizes.stateIconDisc,
          // The pen writes 44, which is exactly half the disc: a circle.
          radius: AuraSizes.stateIconDisc / 2,
          shadow: const <BoxShadow>[],
          child: Center(
            child: Icon(icon, size: AuraSizes.iconState, color: iconColor),
          ),
        ),
        Text(
          title,
          textAlign: TextAlign.center,
          style: AuraText.titleState.copyWith(color: AuraColors.textPrimary),
        ),
        SizedBox(
          width: AuraSizes.stateBodyMeasure,
          child: Text(
            body,
            textAlign: TextAlign.center,
            style: AuraText.body.copyWith(color: AuraColors.textSecondary),
          ),
        ),
        ?note,
      ],
    );
  }
}

/// The chip a full-screen state uses to name what the app already holds.
class AuraStateNote extends StatelessWidget {
  /// Creates a note chip.
  const AuraStateNote({required this.icon, required this.label, super.key});

  /// Glyph before the text.
  final IconData icon;

  /// What the app already holds.
  final String label;

  @override
  Widget build(BuildContext context) {
    return AuraGlass(
      radius: AuraRadii.note,
      shadow: const <BoxShadow>[],
      padding: const EdgeInsets.symmetric(
        vertical: AuraSpacing.smPlus,
        horizontal: AuraSpacing.mdPlus,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: AuraSpacing.xsPlus,
        children: <Widget>[
          Icon(
            icon,
            size: AuraSizes.iconNote,
            color: AuraColors.textTertiary,
          ),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AuraText.captionTracked
                  .forScript(context)
                  .copyWith(color: AuraColors.textTertiary),
            ),
          ),
        ],
      ),
    );
  }
}
