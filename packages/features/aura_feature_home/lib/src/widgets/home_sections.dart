import 'package:aura_design/aura_design.dart';
import 'package:flutter/widgets.dart';

/// The heading a home card carries, with the chevron that opens its detail.
///
/// Three cards share it: the forecast preview, air quality, and the alert
/// detail's own sections. The chevron is absent when there is nothing to open.
class HomeSectionHeader extends StatelessWidget {
  /// Creates a card heading.
  const HomeSectionHeader({required this.title, this.onTap, super.key});

  /// The heading, already in the caps the design sets it in.
  final String title;

  /// Opens the detail screen behind this card.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Flexible(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AuraText.kicker
                .forScript(context)
                .copyWith(color: AuraColors.textTertiary),
          ),
        ),
        if (onTap != null)
          const Icon(
            AuraIcons.chevronRight,
            size: AuraSizes.iconSmall,
            color: AuraColors.textTertiary,
          ),
      ],
    );
  }
}

/// A glass panel, as every section of the home screen is drawn.
class HomeCard extends StatelessWidget {
  /// Creates a home card.
  const HomeCard({
    required this.children,
    this.onTap,
    this.gap = AuraSpacing.md,
    this.radius = AuraRadii.card,
    this.padding = cardPadding,
    super.key,
  });

  /// Stacked contents.
  final List<Widget> children;

  /// Opens the detail screen behind this card.
  final VoidCallback? onTap;

  /// Space between [children].
  final double gap;

  /// Corner radius.
  final double radius;

  /// Inner padding.
  final EdgeInsets padding;

  /// The padding the pen sets on every card that carries a heading.
  static const EdgeInsets cardPadding = EdgeInsets.fromLTRB(
    AuraSpacing.lg,
    AuraSpacing.mdPlus,
    AuraSpacing.lg,
    AuraSpacing.lg,
  );

  @override
  Widget build(BuildContext context) {
    final card = AuraGlass(
      radius: radius,
      shadow: AuraShadows.panel,
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: gap,
        children: children,
      ),
    );
    if (onTap == null) return card;
    return Semantics(
      button: true,
      child: GestureDetector(onTap: onTap, child: card),
    );
  }
}
