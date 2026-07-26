import 'package:aura_design/aura_design.dart';
import 'package:aura_l10n/aura_l10n.dart';
import 'package:flutter/widgets.dart';

/// The frame every detail screen shares.
///
/// Back button, the place in small caps above the screen's own title, then the
/// screen's cards down a scroll. All four detail frames in the pen are this
/// composition with different cards inside it.
class DetailScaffold extends StatelessWidget {
  /// Creates a detail screen frame.
  const DetailScaffold({
    required this.sky,
    required this.place,
    required this.title,
    required this.children,
    required this.onBack,
    super.key,
  });

  /// Which sky this screen sits on.
  final AuraSkyKind sky;

  /// The place the screen is about, as the kicker names it.
  final String place;

  /// The screen's own title.
  final String title;

  /// The cards, stacked.
  final List<Widget> children;

  /// Goes back.
  final VoidCallback onBack;

  /// The pen's `Content` padding, shared by all four frames.
  static const EdgeInsets _padding = EdgeInsets.fromLTRB(
    AuraSpacing.xl,
    AuraSpacing.sm,
    AuraSpacing.xl,
    AuraSpacing.xxl,
  );

  @override
  Widget build(BuildContext context) {
    return AuraSky(
      kind: sky,
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: _padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AuraSpacing.lg,
            children: <Widget>[
              Row(
                spacing: AuraSpacing.md,
                children: <Widget>[
                  AuraCircleButton(
                    icon: AuraChevron.back(context),
                    size: AuraCircleButtonSize.back,
                    semanticLabel: context.l10n.commonBack,
                    onPressed: onBack,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: AuraSpacing.micro,
                      children: <Widget>[
                        Text(
                          place.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AuraText.kickerWide
                              .forScript(context)
                              .copyWith(color: AuraColors.textTertiary),
                        ),
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AuraText.titleScreen.copyWith(
                            color: AuraColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

/// A card on a detail screen.
class DetailCard extends StatelessWidget {
  /// Creates a detail card.
  const DetailCard({
    required this.children,
    this.gap = AuraSpacing.smPlus,
    this.radius = AuraRadii.detailPanel,
    this.padding = const EdgeInsets.all(AuraSpacing.lgPlus),
    this.fill = AuraColors.glass,
    this.borderColor = AuraColors.border,
    super.key,
  });

  /// Stacked contents.
  final List<Widget> children;

  /// Space between [children].
  final double gap;

  /// Corner radius.
  final double radius;

  /// Inner padding.
  final EdgeInsets padding;

  /// Surface fill. Only the alert screen's hero overrides it.
  final Color fill;

  /// Stroke colour. Only the alert screen's hero overrides it.
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor),
        boxShadow: AuraShadows.panel,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: gap,
        children: children,
      ),
    );
  }
}

/// A tracked heading above a card.
class DetailSectionLabel extends StatelessWidget {
  /// Creates a section heading.
  const DetailSectionLabel(this.label, {super.key});

  /// The heading, in sentence case. The view sets the caps.
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: AuraText.sectionLabel
          .forScript(context)
          .copyWith(color: AuraColors.textTertiary),
    );
  }
}
