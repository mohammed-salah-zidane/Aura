import 'package:aura_design/aura_design.dart';
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

BoxDecoration _decorationOf(WidgetTester tester, Finder finder) =>
    tester.widget<Container>(finder).decoration! as BoxDecoration;

void main() {
  setUpAll(loadAuraFonts);

  group('AuraSky', () {
    testWidgets('paints the gradient belonging to its kind', (tester) async {
      await tester.pumpWidget(
        _host(const AuraSky(kind: AuraSkyKind.rain, child: SizedBox())),
      );
      final decoration = _decorationOf(
        tester,
        find.descendant(
          of: find.byType(AuraSky),
          matching: find.byType(Container),
        ),
      );
      final gradient = decoration.gradient! as LinearGradient;
      expect(gradient.colors, AuraSkies.rain.colors);
      expect(gradient.stops, AuraSkies.rain.stops);
    });

    testWidgets('runs top to bottom', (tester) async {
      await tester.pumpWidget(
        _host(const AuraSky(kind: AuraSkyKind.clearDay, child: SizedBox())),
      );
      final gradient =
          _decorationOf(
                tester,
                find.descendant(
                  of: find.byType(AuraSky),
                  matching: find.byType(Container),
                ),
              ).gradient!
              as LinearGradient;
      expect(gradient.begin, Alignment.topCenter);
      expect(gradient.end, Alignment.bottomCenter);
    });

    testWidgets('only clear night carries a starfield', (tester) async {
      for (final kind in AuraSkyKind.values) {
        await tester.pumpWidget(
          _host(AuraSky(kind: kind, child: const SizedBox())),
        );
        expect(
          find.byType(CustomPaint),
          kind == AuraSkyKind.clearNight
              ? findsAtLeastNWidgets(1)
              : findsNothing,
          reason: '${kind.name} has the wrong starfield state',
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
      await tester.pumpWidget(_host(const AuraMark(size: 132)));
      expect(tester.getSize(find.byType(AuraMark)), const Size(132, 132));
    });

    testWidgets('defaults to the size the design specifies', (tester) async {
      await tester.pumpWidget(_host(const AuraMark()));
      expect(
        tester.getSize(find.byType(AuraMark)),
        const Size(AuraMark.referenceSize, AuraMark.referenceSize),
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
