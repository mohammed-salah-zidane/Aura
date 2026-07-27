import 'package:aura_design/aura_design.dart';
import 'package:aura_domain/aura_domain.dart';
import 'package:aura_feature_home/src/widgets/home_collapsing_hero.dart';
import 'package:aura_feature_home/src/widgets/home_condensed_bar.dart';
import 'package:aura_ui/aura_ui.dart';
import 'package:flutter/widgets.dart';

/// Melts the page into the sky at both ends.
///
/// The mask leaves the middle of the page untouched and fades the content to
/// nothing through the strip below the condensed bar and again behind the
/// floating navigation, so a card leaves the screen by dissolving into sky
/// rather than by hitting an edge. This is what lets both bars float on the
/// sky itself with nothing behind them.
class HomeSkyDissolve extends StatelessWidget {
  /// Wraps the scroll view in the dissolve.
  const HomeSkyDissolve({
    required this.bottomInset,
    required this.child,
    super.key,
  });

  /// Where the foot of the page begins dissolving, from the bottom edge.
  final double bottomInset;

  /// The scroll view being melted.
  final Widget child;

  /// Where the foot has fully gone, from the bottom edge.
  static const double _footUntil = 72;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (bounds) {
        final h = bounds.height;
        const top = HomeCollapsingHero.condensedExtent;
        const settled =
            HomeCollapsingHero.condensedExtent + HomeCollapsingHero.dissolveGap;
        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            AuraColors.textPrimary.withValues(alpha: 0),
            AuraColors.textPrimary.withValues(alpha: 0),
            AuraColors.textPrimary,
            AuraColors.textPrimary,
            AuraColors.textPrimary.withValues(alpha: 0),
          ],
          stops: <double>[
            0,
            top / h,
            settled / h,
            (h - bottomInset) / h,
            (h - _footUntil) / h,
          ],
        ).createShader(bounds);
      },
      child: child,
    );
  }
}

/// The condensed bar, floating over the sky the cards dissolve into.
///
/// Outside the scroll view and the safe area on purpose: nothing scrolling
/// can pass over it, its wash runs to the very top edge so the status bar
/// shares its backing, and the wash only has to quiet the sky and the sun,
/// not the content, which the dissolve has already taken.
class HomeCondensedOverlay extends StatelessWidget {
  /// Creates the overlay.
  const HomeCondensedOverlay({
    required this.offset,
    required this.snapshot,
    required this.format,
    super.key,
  });

  /// How far the page has been scrolled.
  final ValueNotifier<double> offset;

  /// The reading on screen.
  final WeatherSnapshot snapshot;

  /// Turns the reading into copy.
  final AuraFormat format;

  /// Where the bar starts arriving along the collapse.
  static const double _from = 0.7;

  /// How far the bar settles down as it arrives.
  static const double _drop = 8.0;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: ValueListenableBuilder<double>(
          valueListenable: offset,
          builder: (context, value, child) {
            final p = (value / AuraMotion.heroCondenseRange).clamp(0.0, 1.0);
            final fadeIn = ((p - _from) / (1 - _from)).clamp(0.0, 1.0);
            if (fadeIn == 0) return const SizedBox.shrink();
            return Opacity(
              opacity: fadeIn,
              child: Transform.translate(
                offset: Offset(0, (1 - fadeIn) * -_drop),
                child: child,
              ),
            );
          },
          child: SizedBox(
            height:
                topInset +
                HomeCollapsingHero.condensedExtent +
                HomeCollapsingHero.dissolveGap,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                const _CondensedWash(),
                Positioned(
                  top: topInset,
                  left: 0,
                  right: 0,
                  height: HomeCollapsingHero.condensedExtent,
                  child: Center(
                    child: HomeCondensedBar(
                      snapshot: snapshot,
                      format: format,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The wash behind the condensed bar.
///
/// Ink fading downward rather than glass: a glass bar would put a stroke and
/// a fill across the sky, and this only has to steady the type against the
/// sky and the sun behind it, the way the foot of the page steadies the
/// navigation.
class _CondensedWash extends StatelessWidget {
  const _CondensedWash();

  static const double _top = 0.45;
  static const double _middle = 0.2;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            AuraColors.ink2.withValues(alpha: _top),
            AuraColors.ink2.withValues(alpha: _middle),
            AuraColors.ink2.withValues(alpha: 0),
          ],
          stops: const <double>[0, 0.5, 1],
        ),
      ),
    );
  }
}
