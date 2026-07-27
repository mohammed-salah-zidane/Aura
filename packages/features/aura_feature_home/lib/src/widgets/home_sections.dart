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
          Icon(
            AuraChevron.forward(context),
            size: AuraSizes.iconSmall,
            color: AuraColors.textTertiary,
          ),
      ],
    );
  }
}

/// A card's title as a sliver: pinned, it holds at the top of its section
/// while the card passes beneath, then gives way to the next section's title,
/// wearing a wash only while content is actually under it. Unpinned, for
/// reduced motion, it simply scrolls with the page.
class HomeSectionTitle extends StatelessWidget {
  /// Creates the title sliver.
  const HomeSectionTitle({
    required this.title,
    required this.onOpen,
    required this.pinned,
    required this.entranceIndex,
    required this.leadIn,
    super.key,
  });

  /// The heading, already in the caps the design sets it in.
  final String title;

  /// Opens the detail screen behind this section.
  final VoidCallback? onOpen;

  /// Whether the title holds at the top of its section while it scrolls.
  final bool pinned;

  /// The section's place in the entrance cascade.
  final int entranceIndex;

  /// Held before the cascade starts, while the sun sweeps its arc.
  final Duration leadIn;

  /// The title row's line box: the kicker's type with its ascent margin,
  /// never smaller than the chevron beside it.
  static const double _line = 17;

  /// How tall the pinned row is, at the current text size.
  static double _extent(BuildContext context) =>
      MediaQuery.textScalerOf(context).scale(_line) +
      AuraSpacing.xs +
      AuraSpacing.sm;

  @override
  Widget build(BuildContext context) {
    final row = AuraEntrance(
      index: entranceIndex,
      leadIn: leadIn,
      child: AuraPressable.child(
        onPressed: onOpen,
        haptic: true,
        child: Padding(
          padding: const EdgeInsets.only(
            left: AuraSpacing.lg,
            right: AuraSpacing.lg,
            top: AuraSpacing.xs,
            bottom: AuraSpacing.sm,
          ),
          child: HomeSectionHeader(title: title, onTap: onOpen),
        ),
      ),
    );
    if (!pinned) return SliverToBoxAdapter(child: row);
    return SliverPersistentHeader(
      pinned: true,
      delegate: _TitleDelegate(extent: _extent(context), child: row),
    );
  }
}

/// Pins a section title at its fixed height and backs it with a wash only
/// while content is actually passing beneath it.
class _TitleDelegate extends SliverPersistentHeaderDelegate {
  const _TitleDelegate({required this.extent, required this.child});

  final double extent;
  final Widget child;

  @override
  double get minExtent => extent;

  @override
  double get maxExtent => extent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        AnimatedOpacity(
          opacity: overlapsContent ? 1 : 0,
          duration: AuraMotion.control,
          curve: AuraMotion.controlCurve,
          child: const _TitleWash(),
        ),
        child,
      ],
    );
  }

  @override
  bool shouldRebuild(_TitleDelegate oldDelegate) =>
      oldDelegate.extent != extent || oldDelegate.child != child;
}

/// The wash a stuck title wears so the card sliding under stays quiet.
class _TitleWash extends StatelessWidget {
  const _TitleWash();

  static const double _strength = 0.45;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            AuraColors.ink2.withValues(alpha: _strength),
            AuraColors.ink2.withValues(alpha: _strength),
            AuraColors.ink2.withValues(alpha: 0),
          ],
          stops: const <double>[0, 0.6, 1],
        ),
      ),
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
    return AuraPressable.child(onPressed: onTap, haptic: true, child: card);
  }
}
