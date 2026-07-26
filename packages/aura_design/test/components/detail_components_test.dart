import 'package:aura_design/aura_design.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/load_aura_fonts.dart';

Widget _host(Widget child, {double width = 321}) => Directionality(
  textDirection: TextDirection.ltr,
  child: MediaQuery(
    data: const MediaQueryData(size: Size(393, 852)),
    child: Align(
      child: SizedBox(width: width, child: child),
    ),
  ),
);

/// Hosts a component that carries its own size, with nothing stretching it.
Widget _loose(Widget child) => _host(Align(child: child));

const List<Color> _ramp = <Color>[
  AuraColors.scaleLevel1,
  AuraColors.scaleLevel5,
];
const List<double> _stops = <double>[0, 1];

void main() {
  setUpAll(loadAuraFonts);

  group('AuraIndexScaleBar', () {
    testWidgets('build keeps the marker on the bar at either end', (
      tester,
    ) async {
      for (final position in <double>[0, 1]) {
        await tester.pumpWidget(
          _host(
            AuraIndexScaleBar(
              colors: _ramp,
              stops: _stops,
              position: position,
            ),
          ),
        );
        final bar = tester.getRect(find.byType(AuraIndexScaleBar));
        final marker = tester.getRect(find.byType(Container).last);

        expect(marker.left, greaterThanOrEqualTo(bar.left - 0.5));
        expect(marker.right, lessThanOrEqualTo(bar.right + 0.5));
      }
    });

    testWidgets('build moves the marker along as the reading rises', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const AuraIndexScaleBar(
            colors: _ramp,
            stops: _stops,
            position: 0,
          ),
        ),
      );
      final low = tester.getRect(find.byType(Container).last).center.dx;

      await tester.pumpWidget(
        _host(
          const AuraIndexScaleBar(
            colors: _ramp,
            stops: _stops,
            position: 1,
          ),
        ),
      );
      final high = tester.getRect(find.byType(Container).last).center.dx;

      expect(high, greaterThan(low));
    });

    testWidgets('build mirrors the scale when the script runs right to left', (
      tester,
    ) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.rtl,
          child: MediaQuery(
            data: MediaQueryData(size: Size(393, 852)),
            child: Align(
              child: SizedBox(
                width: 321,
                child: AuraIndexScaleBar(
                  colors: _ramp,
                  stops: _stops,
                  position: 0,
                ),
              ),
            ),
          ),
        ),
      );

      final bar = tester.getRect(find.byType(AuraIndexScaleBar));
      final marker = tester.getRect(find.byType(Container).last);
      expect(marker.center.dx, greaterThan(bar.center.dx));
    });
  });

  group('AuraSunPath', () {
    testWidgets('build takes the height the design draws it at', (
      tester,
    ) async {
      await tester.pumpWidget(_host(const AuraSunPath(position: 0.5)));
      expect(
        tester.getSize(find.byType(AuraSunPath)).height,
        AuraSizes.sunChartHeight,
      );
    });

    testWidgets('build draws the arc with no sun where there is no sunrise', (
      tester,
    ) async {
      // A polar day is a real reading. The path exists and nothing is on it.
      await tester.pumpWidget(_host(const AuraSunPath(position: null)));
      expect(tester.takeException(), isNull);
    });
  });

  group('AuraMoonPhase', () {
    testWidgets('build is square at the size the design draws it', (
      tester,
    ) async {
      await tester.pumpWidget(
        _loose(const AuraMoonPhase(illumination: 0.34, isWaxing: true)),
      );
      final size = tester.getSize(find.byType(AuraMoonPhase));
      expect(size.width, AuraSizes.moonPhase);
      expect(size.height, AuraSizes.moonPhase);
    });

    testWidgets('build draws every phase of the month without failing', (
      tester,
    ) async {
      for (final illumination in <double>[0, 0.25, 0.5, 0.75, 1]) {
        for (final waxing in <bool>[true, false]) {
          await tester.pumpWidget(
            _loose(
              AuraMoonPhase(illumination: illumination, isWaxing: waxing),
            ),
          );
          expect(tester.takeException(), isNull);
        }
      }
    });
  });

  group('AuraCircleButton', () {
    testWidgets('build draws each size the design authors', (tester) async {
      for (final size in AuraCircleButtonSize.values) {
        await tester.pumpWidget(
          _loose(
            AuraCircleButton(
              icon: AuraIcons.settings,
              semanticLabel: 'Settings',
              size: size,
              onPressed: () {},
            ),
          ),
        );
        expect(
          tester.getSize(find.byType(AuraCircleButton)).width,
          size.diameter,
        );
      }
    });

    testWidgets('build speaks its label, having no text of its own', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          AuraCircleButton(
            icon: AuraIcons.close,
            semanticLabel: 'Close',
            onPressed: () {},
          ),
        ),
      );
      expect(find.bySemanticsLabel('Close'), findsOneWidget);
      handle.dispose();
    });
  });

  group('AuraSearchField', () {
    testWidgets('build takes no focus when it is a way into search', (
      tester,
    ) async {
      var tapped = 0;
      await tester.pumpWidget(
        _host(
          AuraSearchField(
            placeholder: 'Search for a city',
            onTap: () => tapped++,
          ),
        ),
      );

      await tester.tap(find.byType(AuraSearchField));
      await tester.pump();

      expect(tapped, 1);
      expect(find.byType(EditableText), findsNothing);
    });

    testWidgets('build accepts text when it is the field on search', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const AuraSearchField(
            placeholder: 'Search for a city',
            variant: AuraSearchFieldVariant.active,
          ),
        ),
      );

      await tester.enterText(find.byType(EditableText), 'Cair');
      await tester.pump();

      expect(find.text('Cair'), findsOneWidget);
      expect(find.byIcon(AuraIcons.clear), findsOneWidget);
    });
  });
}
