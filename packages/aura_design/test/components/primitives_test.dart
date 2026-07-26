import 'dart:typed_data';

import 'package:aura_design/aura_design.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/load_aura_fonts.dart';

/// Wraps a component in the minimum needed to pump it, with no Material.
Widget _host(Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: MediaQuery(
    data: const MediaQueryData(size: Size(393, 852)),
    child: Align(child: child),
  ),
);

/// Hosts a sky behind a repaint boundary, filling the surface.
///
/// The boundary is what lets the sky tests rasterise a frame. The surface
/// itself is pinned to the design canvas by [_useDesignCanvas], so one sampled
/// pixel is one design point and the starfield lands where the pen put it.
Widget _skyHost(Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: RepaintBoundary(key: _skyBoundary, child: child),
);

/// Resizes the test surface to the 393 by 852 design canvas at a pixel ratio of
/// 1, and restores it afterwards.
void _useDesignCanvas(WidgetTester tester) {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = const Size(
      AuraSizes.referenceWidth,
      AuraSizes.referenceHeight,
    );
  addTearDown(tester.view.reset);
}

BoxDecoration _decorationOf(WidgetTester tester, Finder finder) =>
    tester.widget<Container>(finder).decoration! as BoxDecoration;

/// Key on the repaint boundary the sky tests rasterise.
const _skyBoundary = ValueKey<String>('sky-boundary');

/// A rasterised frame, addressable by pixel.
///
/// The sky is the one component whose whole job is what it paints, and a fill
/// layer can go missing without changing a single widget in the tree. Sampling
/// the raster is the only assertion that notices.
class _Pixels {
  const _Pixels(this._bytes, this._width);

  final ByteData _bytes;
  final int _width;

  /// The colour at a logical point, which is a device pixel at a ratio of 1.
  Color at(int x, int y) {
    final offset = (y * _width + x) * 4;
    return Color.fromARGB(
      _bytes.getUint8(offset + 3),
      _bytes.getUint8(offset),
      _bytes.getUint8(offset + 1),
      _bytes.getUint8(offset + 2),
    );
  }
}

/// Rasterises whatever is currently pumped.
Future<_Pixels> _capture(WidgetTester tester) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_skyBoundary),
  );
  final bytes = await tester.runAsync(() async {
    final image = await boundary.toImage();
    try {
      return await image.toByteData();
    } finally {
      image.dispose();
    }
  });
  return _Pixels(bytes!, boundary.size.width.round());
}

/// Pumps one sky at the design canvas size and rasterises it.
Future<_Pixels> _renderSky(WidgetTester tester, AuraSkyKind kind) async {
  _useDesignCanvas(tester);
  await tester.pumpWidget(
    _skyHost(AuraSky(kind: kind, child: const SizedBox())),
  );
  await tester.pumpAndSettle();
  return _capture(tester);
}

/// The colour of a gradient token at a fraction of its run, with no bloom over
/// it. Derived from the token rather than from the painter, so a painter that
/// drops a layer cannot make this agree with it.
Color _gradientAt(AuraGradient gradient, double t) {
  for (var i = 1; i < gradient.stops.length; i++) {
    if (t > gradient.stops[i]) continue;
    final span = gradient.stops[i] - gradient.stops[i - 1];
    final local = span == 0 ? 0.0 : (t - gradient.stops[i - 1]) / span;
    return Color.lerp(gradient.colors[i - 1], gradient.colors[i], local)!;
  }
  return gradient.colors.last;
}

double _luminanceDistance(Color a, Color b) =>
    (a.computeLuminance() - b.computeLuminance()).abs();

/// Allows one step of 8-bit rounding per channel.
Matcher _closeToColor(Color expected) => predicate<Color>(
  (actual) =>
      ((actual.r - expected.r) * 255).abs() <= 1 &&
      ((actual.g - expected.g) * 255).abs() <= 1 &&
      ((actual.b - expected.b) * 255).abs() <= 1,
  'within one 8-bit step of $expected',
);

void main() {
  setUpAll(loadAuraFonts);

  group('AuraSky', () {
    testWidgets('paints its gradient top to bottom below the bloom', (
      tester,
    ) async {
      // Every bloom sits in the upper half of the frame, so the lower half is
      // the only place the bare gradient is observable.
      final pixels = await _renderSky(tester, AuraSkyKind.rain);
      for (final y in const <int>[600, 720, 850]) {
        expect(
          pixels.at(196, y),
          _closeToColor(_gradientAt(AuraSkies.rain, y / 852)),
          reason: 'the gradient is wrong at y=$y',
        );
      }
      expect(
        pixels.at(196, 850),
        _closeToColor(AuraSkies.rain.colors.last),
        reason: 'the gradient does not finish on its last stop',
      );
    });

    testWidgets('paints the bloom over the gradient', (tester) async {
      // Every frame in aura.pen carries a second radial fill. Reading only the
      // first one drops the light source out of all 20 screens, and nothing
      // short of sampling the painted output notices.
      for (final kind in AuraSkyKind.values) {
        final pixels = await _renderSky(tester, kind);
        final bloom = kind.bloom;
        final x = (bloom.centerX * 393).round().clamp(1, 391);
        final y = (bloom.centerY * 852).round().clamp(1, 850);

        final painted = pixels.at(x, y);
        final gradientOnly = _gradientAt(kind.gradient, y / 852);
        expect(
          _luminanceDistance(painted, gradientOnly),
          greaterThan(0.002),
          reason:
              '${kind.name} matched its bare gradient at the bloom centre, so '
              'the second fill is not being painted',
        );
      }
    });

    testWidgets('the bloom sits where the design centres it', (tester) async {
      // Clear night is the one sky whose bloom is offset horizontally, so a
      // centred implementation passes every other sky and fails this one.
      final pixels = await _renderSky(tester, AuraSkyKind.clearNight);
      final bloom = AuraSkyKind.clearNight.bloom;
      final y = (bloom.centerY * 852).round();
      final atCentre = pixels.at((bloom.centerX * 393).round(), y);
      final mirrored = pixels.at(((1 - bloom.centerX) * 393).round(), y);
      expect(
        atCentre.computeLuminance(),
        greaterThan(mirrored.computeLuminance()),
        reason: 'the clear-night bloom is not offset to the right',
      );
    });

    testWidgets('only clear night carries a starfield', (tester) async {
      // The first star is a 3pt disc at (30, 120). Sampling its centre against
      // clear sky 30pt to its right at the same height isolates it from both
      // fills, which vary far too gently over 30pt to explain the difference.
      for (final kind in AuraSkyKind.values) {
        final pixels = await _renderSky(tester, kind);
        final onStar = pixels.at(31, 121).computeLuminance();
        final offStar = pixels.at(61, 121).computeLuminance();
        expect(
          onStar > offStar + 0.01,
          kind == AuraSkyKind.clearNight,
          reason: '${kind.name} has the wrong starfield state',
        );
      }
    });

    testWidgets('crossfades rather than cutting between skies', (tester) async {
      _useDesignCanvas(tester);
      await tester.pumpWidget(
        _skyHost(const AuraSky(kind: AuraSkyKind.clearDay, child: SizedBox())),
      );
      await tester.pumpWidget(
        _skyHost(const AuraSky(kind: AuraSkyKind.rain, child: SizedBox())),
      );
      await tester.pump(AuraMotion.sky ~/ 2);

      // Sampled below both blooms, so only the gradient is in play.
      const y = 700;
      final mid = (await _capture(tester)).at(196, y);
      expect(
        mid,
        isNot(_closeToColor(_gradientAt(AuraSkies.clearDay, y / 852))),
        reason: 'the sky never left the old gradient',
      );
      expect(
        mid,
        isNot(_closeToColor(_gradientAt(AuraSkies.rain, y / 852))),
        reason: 'the sky cut straight to the new gradient',
      );

      await tester.pumpAndSettle();
      expect(
        (await _capture(tester)).at(196, y),
        _closeToColor(_gradientAt(AuraSkies.rain, y / 852)),
        reason: 'the sky did not finish on the new gradient',
      );
    });

    test('every bloom has two stops, transparent at the outer one', () {
      // The sky transition interpolates blooms pairwise, which is only correct
      // while every bloom in the set has the same shape.
      for (final kind in AuraSkyKind.values) {
        final bloom = kind.bloom;
        expect(bloom.colors, hasLength(2), reason: kind.name);
        expect(bloom.stops, hasLength(2), reason: kind.name);
        expect(bloom.stops.first, 0, reason: kind.name);
        expect(
          bloom.colors.last.a,
          0,
          reason: '${kind.name} outer stop is lit',
        );
        expect(
          bloom.opacity,
          inInclusiveRange(0, 1),
          reason: '${kind.name} opacity is out of range',
        );
        expect(
          bloom.widthFactor,
          greaterThan(0),
          reason: '${kind.name} has no width',
        );
        expect(
          bloom.heightFactor,
          greaterThan(0),
          reason: '${kind.name} has no height',
        );
      }
    });

    testWidgets('every kind carries at least two stops', (tester) async {
      for (final kind in AuraSkyKind.values) {
        expect(
          kind.gradient.colors.length,
          greaterThanOrEqualTo(2),
          reason: '${kind.name} has too few colours',
        );
        expect(
          kind.gradient.stops.length,
          kind.gradient.colors.length,
          reason: '${kind.name} stop and colour counts differ',
        );
      }
    });

    testWidgets('stops ascend from 0 to 1', (tester) async {
      for (final kind in AuraSkyKind.values) {
        final stops = kind.gradient.stops;
        expect(stops.first, 0, reason: '${kind.name} does not start at 0');
        expect(stops.last, 1, reason: '${kind.name} does not end at 1');
        for (var i = 1; i < stops.length; i++) {
          expect(
            stops[i],
            greaterThan(stops[i - 1]),
            reason: '${kind.name} stop $i is out of order',
          );
        }
      }
    });
  });

  group('AuraGlass', () {
    testWidgets('applies the fill, stroke and radius from the recipe', (
      tester,
    ) async {
      await tester.pumpWidget(_host(const AuraGlass(child: SizedBox())));
      final decoration = _decorationOf(tester, find.byType(Container));
      expect(decoration.color, AuraColors.glass);
      expect(decoration.border!.bottom.color, AuraColors.border);
      expect(decoration.border!.bottom.width, 1);
      expect(
        decoration.borderRadius,
        BorderRadius.circular(AuraRadii.card),
      );
      expect(decoration.boxShadow, AuraShadows.tile);
    });

    testWidgets('the elevated level lets more sky through', (tester) async {
      await tester.pumpWidget(
        _host(
          const AuraGlass(
            level: AuraGlassLevel.elevated,
            child: SizedBox(),
          ),
        ),
      );
      expect(
        _decorationOf(tester, find.byType(Container)).color,
        AuraColors.glass2,
      );
      expect(AuraColors.glass2.a, greaterThan(AuraColors.glass.a));
    });

    testWidgets('the flat variant carries no shadow', (tester) async {
      await tester.pumpWidget(_host(const AuraGlass.flat(child: SizedBox())));
      expect(
        _decorationOf(tester, find.byType(Container)).boxShadow,
        isEmpty,
      );
    });
  });

  group('AuraToggle', () {
    testWidgets('sits right when on and left when off', (tester) async {
      for (final value in <bool>[true, false]) {
        await tester.pumpWidget(
          _host(AuraToggle(value: value, onChanged: (_) {})),
        );
        await tester.pumpAndSettle();
        expect(
          tester.widget<AnimatedAlign>(find.byType(AnimatedAlign)).alignment,
          value ? Alignment.centerRight : Alignment.centerLeft,
        );
      }
    });

    testWidgets('is gold when on and bordered glass when off', (tester) async {
      await tester.pumpWidget(
        _host(AuraToggle(value: true, onChanged: (_) {})),
      );
      var decoration =
          tester
                  .widget<AnimatedContainer>(find.byType(AnimatedContainer))
                  .decoration!
              as BoxDecoration;
      expect(decoration.color, AuraColors.accent);
      expect(decoration.border, isNull);

      await tester.pumpWidget(
        _host(AuraToggle(value: false, onChanged: (_) {})),
      );
      decoration =
          tester
                  .widget<AnimatedContainer>(find.byType(AnimatedContainer))
                  .decoration!
              as BoxDecoration;
      expect(decoration.color, AuraColors.toggleTrackOff);
      expect(decoration.border, isNotNull);
    });

    testWidgets('reports the opposite value on tap', (tester) async {
      bool? received;
      await tester.pumpWidget(
        _host(AuraToggle(value: false, onChanged: (v) => received = v)),
      );
      await tester.tap(find.byType(AuraToggle));
      expect(received, isTrue);
    });

    testWidgets('a null handler makes it inert', (tester) async {
      await tester.pumpWidget(
        _host(const AuraToggle(value: false, onChanged: null)),
      );
      await tester.tap(find.byType(AuraToggle));
      expect(tester.takeException(), isNull);
    });

    testWidgets('matches the size in the design', (tester) async {
      await tester.pumpWidget(
        _host(AuraToggle(value: true, onChanged: (_) {})),
      );
      expect(
        tester.getSize(find.byType(AnimatedContainer)),
        const Size(46, 28),
      );
    });
  });

  group('AuraButtonPrimary', () {
    testWidgets('shows its label and optional icon', (tester) async {
      await tester.pumpWidget(
        _host(
          AuraButtonPrimary(
            label: 'Try Again',
            icon: AuraIcons.refresh,
            onPressed: () {},
          ),
        ),
      );
      expect(find.text('Try Again'), findsOneWidget);
      expect(find.byIcon(AuraIcons.refresh), findsOneWidget);
    });

    testWidgets('omits the icon slot when none is given', (tester) async {
      await tester.pumpWidget(
        _host(AuraButtonPrimary(label: 'Done', onPressed: () {})),
      );
      expect(find.byType(Icon), findsNothing);
    });

    testWidgets('fires once per tap', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(AuraButtonPrimary(label: 'Done', onPressed: () => taps++)),
      );
      await tester.tap(find.byType(AuraButtonPrimary));
      expect(taps, 1);
    });

    testWidgets('a null handler reads as disabled to assistive tech', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(const AuraButtonPrimary(label: 'Done', onPressed: null)),
      );
      expect(
        tester.getSemantics(find.byType(AuraButtonPrimary)),
        matchesSemantics(isButton: true, hasEnabledState: true),
      );

      await tester.pumpWidget(
        _host(AuraButtonPrimary(label: 'Done', onPressed: () {})),
      );
      expect(
        tester.getSemantics(find.byType(AuraButtonPrimary)),
        matchesSemantics(
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
        ),
      );
      // Must be disposed inline: addTearDown runs after the framework's
      // end-of-test semantics verification.
      handle.dispose();
    });

    testWidgets('a null handler does not fire', (tester) async {
      await tester.pumpWidget(
        _host(const AuraButtonPrimary(label: 'Done', onPressed: null)),
      );
      await tester.tap(find.byType(AuraButtonPrimary));
      expect(tester.takeException(), isNull);
    });
  });

  group('AuraSearchField', () {
    testWidgets('shows the placeholder only while empty', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 360,
            child: AuraSearchField(
              placeholder: 'Search for a city or airport',
              controller: controller,
            ),
          ),
        ),
      );
      expect(find.text('Search for a city or airport'), findsOneWidget);

      controller.text = 'Cair';
      await tester.pump();
      expect(find.text('Search for a city or airport'), findsNothing);
    });

    testWidgets('reveals a clear action once there is text', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 360,
            child: AuraSearchField(
              placeholder: 'Search',
              controller: controller,
            ),
          ),
        ),
      );
      expect(find.byIcon(AuraIcons.close), findsNothing);

      controller.text = 'Cair';
      await tester.pump();
      expect(find.byIcon(AuraIcons.close), findsOneWidget);

      await tester.tap(find.byIcon(AuraIcons.close));
      await tester.pump();
      expect(controller.text, isEmpty);
    });
  });

  group('AuraMark', () {
    testWidgets('is square at the requested size', (tester) async {
      await tester.pumpWidget(_host(const AuraMark(size: AuraMarkSize.splash)));
      expect(tester.getSize(find.byType(AuraMark)), const Size(132, 132));
    });

    testWidgets('defaults to the size the design specifies', (tester) async {
      await tester.pumpWidget(_host(const AuraMark()));
      expect(
        tester.getSize(find.byType(AuraMark)),
        Size(
          AuraMarkSize.reference.diameter,
          AuraMarkSize.reference.diameter,
        ),
      );
    });

    testWidgets('draws every size the design authors', (tester) async {
      for (final size in AuraMarkSize.values) {
        await tester.pumpWidget(_host(AuraMark(size: size)));
        expect(
          tester.getSize(find.byType(AuraMark)),
          Size(size.diameter, size.diameter),
          reason: 'AuraMarkSize.${size.name}',
        );
      }
    });

    test('carries the ring stroke aura.pen authors at each size', () {
      expect(
        <AuraMarkSize, double>{
          for (final size in AuraMarkSize.values) size: size.ringStroke,
        },
        const <AuraMarkSize, double>{
          AuraMarkSize.hero: 1,
          AuraMarkSize.brandBar: 1,
          AuraMarkSize.reference: 1.8,
          AuraMarkSize.splash: 2.64,
        },
      );
    });
  });

  group('AuraSkeleton', () {
    testWidgets('holds the size it is asked for and keeps animating', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(const AuraSkeleton(width: 120, height: 16)),
      );
      expect(tester.getSize(find.byType(AuraSkeleton)), const Size(120, 16));
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull);
    });

    testWidgets('the circle variant is square in both dimensions', (
      tester,
    ) async {
      await tester.pumpWidget(_host(const AuraSkeleton.circle(diameter: 26)));
      expect(tester.getSize(find.byType(AuraSkeleton)), const Size(26, 26));
    });
  });
}
