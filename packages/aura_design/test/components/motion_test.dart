import 'dart:typed_data';

import 'package:aura_design/aura_design.dart';
import 'package:flutter/gestures.dart' show kPressTimeout;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/load_aura_fonts.dart';

/// Hosts a component at its own size, with motion either on or off.
Widget _host(Widget child, {required bool animate}) =>
    _fullBleed(Align(child: child), animate: animate);

/// Hosts something that wants the whole surface, such as a sky.
Widget _fullBleed(Widget child, {required bool animate}) => Directionality(
  textDirection: TextDirection.ltr,
  child: MediaQuery(
    data: MediaQueryData(
      size: const Size(AuraSizes.referenceWidth, AuraSizes.referenceHeight),
      disableAnimations: !animate,
    ),
    child: child,
  ),
);

/// Key on the boundary the ambient tests rasterise.
const _boundary = ValueKey<String>('ambient-boundary');

/// A plain box to wrap, sized only so it can be found and pressed.
const Widget _box = SizedBox.square(dimension: _boxSide);
const double _boxSide = 100;

void _useDesignCanvas(WidgetTester tester) {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = const Size(
      AuraSizes.referenceWidth,
      AuraSizes.referenceHeight,
    );
  addTearDown(tester.view.reset);
}

/// Rasterises whatever sits under the boundary key.
///
/// `toImage` goes to the engine, which the test clock does not drive, so it
/// only ever completes inside `runAsync`.
Future<ByteData> _frame(WidgetTester tester) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_boundary),
  );
  final bytes = await tester.runAsync(() async {
    final image = await boundary.toImage();
    try {
      return await image.toByteData();
    } finally {
      image.dispose();
    }
  });
  return bytes!;
}

int _differences(ByteData a, ByteData b) {
  var count = 0;
  for (var i = 0; i < a.lengthInBytes; i += 4) {
    if (a.getUint32(i) != b.getUint32(i)) count++;
  }
  return count;
}

Future<ByteData> _renderSky(
  WidgetTester tester,
  AuraSkyKind kind, {
  required bool animate,
  Duration settle = Duration.zero,
}) async {
  _useDesignCanvas(tester);
  await tester.pumpWidget(
    _fullBleed(
      RepaintBoundary(
        key: _boundary,
        child: AuraSky(kind: kind, child: const SizedBox.expand()),
      ),
      animate: animate,
    ),
  );
  if (settle > Duration.zero) await tester.pump(settle);
  return _frame(tester);
}

void main() {
  setUpAll(loadAuraFonts);

  group('AuraAmbients', () {
    test('every weather sky carries a layer and no other sky does', () {
      const weather = <AuraSkyKind>{
        AuraSkyKind.clearDay,
        AuraSkyKind.clearNight,
        AuraSkyKind.partlyCloudy,
        AuraSkyKind.overcast,
        AuraSkyKind.fog,
        AuraSkyKind.rain,
        AuraSkyKind.snow,
        AuraSkyKind.thunderstorm,
      };
      for (final kind in AuraSkyKind.values) {
        expect(
          kind.ambient.kind != AuraAmbientKind.none,
          weather.contains(kind),
          reason: '${kind.name} has the wrong ambient state',
        );
      }
    });

    test('each condition draws the marks its weather calls for', () {
      const expected = <AuraSkyKind, AuraAmbientKind>{
        AuraSkyKind.clearDay: AuraAmbientKind.breath,
        AuraSkyKind.clearNight: AuraAmbientKind.twinkle,
        AuraSkyKind.partlyCloudy: AuraAmbientKind.drift,
        AuraSkyKind.overcast: AuraAmbientKind.drift,
        AuraSkyKind.fog: AuraAmbientKind.drift,
        AuraSkyKind.rain: AuraAmbientKind.rain,
        AuraSkyKind.snow: AuraAmbientKind.snow,
        AuraSkyKind.thunderstorm: AuraAmbientKind.rain,
      };
      for (final entry in expected.entries) {
        expect(entry.key.ambient.kind, entry.value, reason: entry.key.name);
      }
    });

    test('only the thunderstorm flashes', () {
      for (final kind in AuraSkyKind.values) {
        expect(
          kind.ambient.flash > 0,
          kind == AuraSkyKind.thunderstorm,
          reason: '${kind.name} has the wrong flash state',
        );
      }
    });

    test('no ambient layer introduces a colour the pen does not declare', () {
      // The one rule this layer is held to, since the pen authors no motion to
      // extract it from. Every colour below is read from a frame.
      //
      // `conditionSnowflake` is absent because it is the same white as
      // `starfield`, and a set will not hold it twice.
      final fromPen = <Color>{
        AuraColors.transparent,
        AuraColors.conditionSun,
        AuraColors.starfield,
        AuraColors.conditionCloudSun,
        AuraColors.conditionCloud,
        AuraColors.conditionCloudFog,
        AuraColors.conditionCloudRain,
      };
      for (final kind in AuraSkyKind.values) {
        expect(fromPen, contains(kind.ambient.color), reason: kind.name);
      }
      expect(fromPen.contains(AuraAmbients.flashColor), isFalse);
      expect(AuraAmbients.flashColor, AuraColors.conditionZap);
    });
  });

  group('AuraAmbientField', () {
    test('scatter returns the same value for the same index', () {
      for (var i = 0; i < 60; i++) {
        expect(AuraAmbientField.scatter(i, 7), AuraAmbientField.scatter(i, 7));
      }
    });

    test('scatter stays inside the unit range', () {
      for (var i = 0; i < 200; i++) {
        expect(AuraAmbientField.scatter(i, 13), inInclusiveRange(0, 1));
      }
    });

    test('scatter does not advance by a fixed step', () {
      // This is the bug that shipped rain as a set of straight diagonal lines.
      // A multiply-and-mask hash walks by a constant, so every mark sat the
      // same distance from the last and the field read as a comb rather than
      // as weather. Checking that neighbours are merely far apart does not
      // catch it, because a large constant step passes that easily.
      final steps = <double>{};
      for (var i = 0; i < 200; i++) {
        final delta =
            AuraAmbientField.scatter(i + 1, 3) - AuraAmbientField.scatter(i, 3);
        steps.add((delta * 100).roundToDouble());
      }
      expect(
        steps.length,
        greaterThan(50),
        reason: 'consecutive marks advance by a repeating step',
      );
    });

    test('scatter spreads evenly across the range', () {
      // A field that clusters leaves bald patches of sky and clumps elsewhere.
      final buckets = List<int>.filled(10, 0);
      for (var i = 0; i < 1000; i++) {
        buckets[(AuraAmbientField.scatter(i, 5) * 10).floor().clamp(0, 9)]++;
      }
      for (var i = 0; i < buckets.length; i++) {
        expect(
          buckets[i],
          inInclusiveRange(60, 140),
          reason: 'tenth $i holds ${buckets[i]} of 1000',
        );
      }
    });

    test('scatter separates the same index under different salts', () {
      for (var i = 0; i < 40; i++) {
        expect(
          AuraAmbientField.scatter(i, 3),
          isNot(AuraAmbientField.scatter(i, 29)),
          reason: 'index $i collides across salts',
        );
      }
    });

    test('progress wraps back into the unit range', () {
      for (final phase in const <double>[0, 0.5, 0.99, 1, 2.75, 17.3]) {
        expect(
          AuraAmbientField.progress(5, phase),
          inInclusiveRange(0, 1),
          reason: 'phase $phase escaped the range',
        );
      }
    });

    test('progress returns the same frame for the same phase', () {
      // The property the goldens depend on. Nothing here may reach for a
      // random source, or a frame would differ from itself.
      for (var i = 0; i < 30; i++) {
        expect(
          AuraAmbientField.progress(i, 0.37, salt: 11),
          AuraAmbientField.progress(i, 0.37, salt: 11),
        );
      }
    });

    test('wave stays between minus one and one', () {
      for (var i = 0; i < 30; i++) {
        expect(AuraAmbientField.wave(i, i / 30), inInclusiveRange(-1, 1));
      }
    });
  });

  group('AuraSky ambient layer', () {
    testWidgets('a still sky paints the same frame at any phase', (
      tester,
    ) async {
      final first = await _renderSky(
        tester,
        AuraSkyKind.systemBrand,
        animate: true,
      );
      final later = await _renderSky(
        tester,
        AuraSkyKind.systemBrand,
        animate: true,
        settle: AuraMotion.breath ~/ 3,
      );
      expect(_differences(first, later), 0);
    });

    testWidgets('rain moves between one frame and the next', (tester) async {
      final first = await _renderSky(tester, AuraSkyKind.rain, animate: true);
      final later = await _renderSky(
        tester,
        AuraSkyKind.rain,
        animate: true,
        settle: AuraMotion.breath ~/ 4,
      );
      expect(
        _differences(first, later),
        greaterThan(0),
        reason: 'the rain never fell',
      );
    });

    testWidgets('reduced motion paints the frame the pen draws', (
      tester,
    ) async {
      // The invariant the whole layer rests on: switch motion off anywhere in
      // the app and what is left is the design, not a frozen animation.
      for (final kind in <AuraSkyKind>[
        AuraSkyKind.rain,
        AuraSkyKind.snow,
        AuraSkyKind.thunderstorm,
        AuraSkyKind.overcast,
        AuraSkyKind.clearDay,
      ]) {
        final atRest = await _renderSky(tester, kind, animate: false);
        final later = await _renderSky(
          tester,
          kind,
          animate: false,
          settle: AuraMotion.breath * 2,
        );
        expect(
          _differences(atRest, later),
          0,
          reason: '${kind.name} still moved with motion reduced',
        );
      }
    });

    testWidgets('the starfield survives reduced motion', (tester) async {
      // Stars are the one ambient mark the pen actually draws, so unlike rain
      // they are content and have to stay.
      final night = await _renderSky(
        tester,
        AuraSkyKind.clearNight,
        animate: false,
      );
      final day = await _renderSky(
        tester,
        AuraSkyKind.clearDay,
        animate: false,
      );
      final onStar = night.getUint32((121 * 393 + 31) * 4);
      final offStar = night.getUint32((121 * 393 + 61) * 4);
      expect(onStar, isNot(offStar), reason: 'the starfield is missing');
      expect(day.getUint32((121 * 393 + 31) * 4), isNot(onStar));
    });
  });

  group('AuraEntrance', () {
    testWidgets('renders its final frame at once when motion is reduced', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const AuraEntrance(index: 4, child: _box),
          animate: false,
        ),
      );
      expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 1);
    });

    testWidgets('starts hidden and arrives, later the further down it is', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const Column(
            children: <Widget>[
              AuraEntrance(index: 0, child: _box),
              AuraEntrance(index: 3, child: _box),
            ],
          ),
          animate: true,
        ),
      );
      double opacityAt(int i) =>
          tester.widgetList<Opacity>(find.byType(Opacity)).elementAt(i).opacity;

      expect(opacityAt(0), 0);
      expect(opacityAt(1), 0);

      // The first section starts immediately; the fourth waits four staggers.
      await tester.pump();
      await tester.pump(AuraMotion.entrance);
      expect(opacityAt(0), 1, reason: 'the first section never arrived');
      expect(
        opacityAt(1),
        lessThan(1),
        reason: 'the fourth section did not wait its turn',
      );

      await tester.pump(AuraMotion.entranceStagger * 3 + AuraMotion.entrance);
      expect(opacityAt(1), 1);
    });
  });

  group('AuraPressable', () {
    testWidgets('shrinks under a finger and returns', (tester) async {
      await tester.pumpWidget(
        _host(
          AuraPressable.child(
            onPressed: () {},
            child: _box,
          ),
          animate: true,
        ),
      );
      double scale() => tester
          .widget<AnimatedScale>(
            find.byType(AnimatedScale),
          )
          .scale;

      expect(scale(), 1);
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(SizedBox)),
      );
      // A tap recognizer holds onTapDown back until it wins the arena or the
      // press timeout passes, so a bare pump is too early to see the press.
      await tester.pump(kPressTimeout + AuraMotion.control);
      expect(scale(), AuraMotion.pressScale);

      await gesture.up();
      await tester.pump();
      expect(scale(), 1);
    });

    testWidgets('a null handler does not respond to a press', (tester) async {
      await tester.pumpWidget(
        _host(
          const AuraPressable.child(
            onPressed: null,
            child: _box,
          ),
          animate: true,
        ),
      );
      final gesture = await tester.press(find.byType(SizedBox));
      await tester.pump();
      expect(
        tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale,
        1,
      );
      await gesture.up();
    });

    testWidgets('reports itself as a button to assistive tech', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          AuraPressable.child(
            onPressed: () {},
            semanticLabel: 'Open search',
            child: _box,
          ),
          animate: true,
        ),
      );
      expect(find.bySemanticsLabel('Open search'), findsOneWidget);
      handle.dispose();
    });
  });

  group('AuraMark reveal', () {
    testWidgets('a fully revealed mark is what a plain mark paints', (
      tester,
    ) async {
      // The default has to stay the pen's frame, or every screen that draws
      // the mark would shift the day this parameter landed.
      const plain = AuraMark(size: AuraMarkSize.splash);
      expect(plain.reveal, 1);
      expect(plain.glow, 1);
    });

    testWidgets('paints at every point of the reveal without throwing', (
      tester,
    ) async {
      for (final reveal in const <double>[0, 0.2, 0.45, 0.55, 0.8, 1]) {
        await tester.pumpWidget(
          _host(
            AuraMark(size: AuraMarkSize.splash, reveal: reveal),
            animate: false,
          ),
        );
        expect(tester.takeException(), isNull, reason: 'reveal $reveal threw');
      }
    });

    testWidgets('holds its box whatever the glow is doing', (tester) async {
      for (final glow in const <double>[1, 1.35]) {
        await tester.pumpWidget(
          _host(
            AuraMark(size: AuraMarkSize.splash, glow: glow),
            animate: false,
          ),
        );
        expect(
          tester.getSize(find.byType(AuraMark)),
          const Size(132, 132),
          reason: 'the glow resized the mark at $glow',
        );
      }
    });
  });
}
