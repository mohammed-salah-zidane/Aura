import 'package:aura_design/src/tokens/aura_colors.dart';
import 'package:aura_design/src/tokens/aura_metrics.dart';
import 'package:aura_design/src/tokens/aura_shadows.dart';
import 'package:flutter/widgets.dart';

/// How much the sky shows through a glass surface.
enum AuraGlassLevel {
  /// Resting surface. Cards, rows, panels.
  resting(AuraColors.glass),

  /// Pressed or selected surface.
  elevated(AuraColors.glass2);

  const AuraGlassLevel(this.fill);

  /// Fill colour for this level.
  final Color fill;
}

/// The glass surface every Aura container is built from.
///
/// The recipe is a translucent fill, a one-pixel inner stroke and an optional
/// drop shadow. It deliberately does not use `BackdropFilter`: the design is
/// flat translucency, and a blur behind every card would cost a full-screen
/// read-back per frame on scrolling lists.
class AuraGlass extends StatelessWidget {
  /// Creates a glass surface.
  const AuraGlass({
    this.child,
    this.level = AuraGlassLevel.resting,
    this.radius = AuraRadii.card,
    this.shadow = AuraShadows.tile,
    this.padding,
    this.width,
    this.height,
    this.borderColor = AuraColors.border,
    super.key,
  });

  /// A surface with no shadow, for rows and pills that sit inside a panel.
  const AuraGlass.flat({
    Widget? child,
    AuraGlassLevel level = AuraGlassLevel.resting,
    double radius = AuraRadii.row,
    EdgeInsetsGeometry? padding,
    double? width,
    double? height,
    Key? key,
  }) : this(
         child: child,
         level: level,
         radius: radius,
         shadow: const <BoxShadow>[],
         padding: padding,
         width: width,
         height: height,
         key: key,
       );

  /// Content drawn inside the surface.
  final Widget? child;

  /// How much the sky shows through.
  final AuraGlassLevel level;

  /// Corner radius.
  final double radius;

  /// Drop shadow. Pass an empty list for a flat surface.
  final List<BoxShadow> shadow;

  /// Inner padding.
  final EdgeInsetsGeometry? padding;

  /// Fixed width, when the design specifies one.
  final double? width;

  /// Fixed height, when the design specifies one.
  final double? height;

  /// Stroke colour. Only the alert banner overrides this.
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: level.fill,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor),
        boxShadow: shadow,
      ),
      child: child,
    );
  }
}
