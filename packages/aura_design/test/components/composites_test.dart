import 'package:aura_design/aura_design.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/load_aura_fonts.dart';

Widget _host(Widget child, {double width = 393}) => Directionality(
  textDirection: TextDirection.ltr,
  child: MediaQuery(
    data: const MediaQueryData(size: Size(393, 852)),
    child: Align(
      child: SizedBox(width: width, child: child),
    ),
  ),
);

void main() {
  setUpAll(loadAuraFonts);

  group('AuraMetricCard', () {
    testWidgets('shows the label, value and sub-line', (tester) async {
      await tester.pumpWidget(
        _host(
          const AuraMetricCard(
            icon: AuraIcons.wind,
            label: 'WIND',
            value: '15 km/h',
            sub: 'NW · gusts 22',
          ),
          width: 172,
        ),
      );
      expect(find.text('WIND'), findsOneWidget);
      expect(find.text('15 km/h'), findsOneWidget);
      expect(find.text('NW · gusts 22'), findsOneWidget);
    });

    testWidgets('renders nothing in the sub slot when the API has no field', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const AuraMetricCard(
            icon: AuraIcons.eye,
            label: 'VISIBILITY',
            value: '10 km',
          ),
          width: 172,
        ),
      );
      expect(find.text('VISIBILITY'), findsOneWidget);
      expect(find.byType(Text), findsNWidgets(2));
    });

    testWidgets('matches the height in the design', (tester) async {
      await tester.pumpWidget(
        _host(
          const AuraMetricCard(
            icon: AuraIcons.gauge,
            label: 'PRESSURE',
            value: '1013',
          ),
          width: 172,
        ),
      );
      expect(tester.getSize(find.byType(AuraMetricCard)).height, 116);
    });

    testWidgets('accepts a scale bar for the UV variant', (tester) async {
      await tester.pumpWidget(
        _host(
          const AuraMetricCard(
            icon: AuraIcons.sun,
            label: 'UV INDEX',
            value: '9',
            sub: 'Very High',
            scale: AuraScaleBar(
              position: 0.9,
              colors: <Color>[AuraColors.scaleLevel1, AuraColors.scaleLevel4],
              stops: <double>[0, 1],
            ),
          ),
          width: 172,
        ),
      );
      expect(find.byType(AuraScaleBar), findsOneWidget);
    });
  });

  group('AuraScaleBar', () {
    testWidgets('clamps a position outside the bar', (tester) async {
      for (final position in <double>[-1, 0, 0.5, 1, 2]) {
        await tester.pumpWidget(
          _host(
            AuraScaleBar(
              position: position,
              colors: const <Color>[
                AuraColors.scaleLevel1,
                AuraColors.scaleLevel5,
              ],
              stops: const <double>[0, 1],
            ),
            width: 100,
          ),
        );
        expect(tester.takeException(), isNull, reason: 'failed at $position');
      }
    });

    testWidgets('matches the height in the design', (tester) async {
      await tester.pumpWidget(
        _host(
          const AuraScaleBar(
            position: 0.5,
            colors: <Color>[AuraColors.scaleLevel1, AuraColors.scaleLevel5],
            stops: <double>[0, 1],
          ),
          width: 100,
        ),
      );
      expect(tester.getSize(find.byType(AuraScaleBar)).height, 4);
    });
  });

  group('AuraForecastRow', () {
    Widget row({String? rain}) => AuraForecastRow(
      day: 'Mon',
      icon: AuraIcons.sun,
      iconTint: AuraColors.conditionSun,
      low: '24°',
      high: '36°',
      rangeStart: 0.2,
      rangeExtent: 0.5,
      rainProbability: rain,
    );

    testWidgets('shows the day, low and high', (tester) async {
      await tester.pumpWidget(_host(row()));
      expect(find.text('Mon'), findsOneWidget);
      expect(find.text('24°'), findsOneWidget);
      expect(find.text('36°'), findsOneWidget);
    });

    testWidgets('shows rain chance only when the API reports one', (
      tester,
    ) async {
      await tester.pumpWidget(_host(row()));
      expect(find.text('10%'), findsNothing);

      await tester.pumpWidget(_host(row(rain: '10%')));
      expect(find.text('10%'), findsOneWidget);
    });

    testWidgets('matches the height in the design', (tester) async {
      await tester.pumpWidget(_host(row()));
      expect(tester.getSize(find.byType(AuraForecastRow)).height, 54);
    });
  });

  group('AuraRangeBar', () {
    testWidgets('keeps a flat day visible', (tester) async {
      await tester.pumpWidget(
        _host(const AuraRangeBar(start: 0.5, extent: 0), width: 200),
      );
      final box = tester.widget<FractionallySizedBox>(
        find.byType(FractionallySizedBox),
      );
      expect(box.widthFactor, greaterThan(0));
    });

    testWidgets('never lets the segment run past the track', (tester) async {
      await tester.pumpWidget(
        _host(const AuraRangeBar(start: 0.8, extent: 1), width: 200),
      );
      final box = tester.widget<FractionallySizedBox>(
        find.byType(FractionallySizedBox),
      );
      expect(box.widthFactor! + 0.8, lessThanOrEqualTo(1.0001));
    });

    testWidgets('matches the track height in the design', (tester) async {
      await tester.pumpWidget(
        _host(const AuraRangeBar(start: 0, extent: 1), width: 200),
      );
      expect(tester.getSize(find.byType(AuraRangeBar)).height, 6);
    });
  });

  group('AuraHourCell', () {
    testWidgets('draws the current hour heavier than the rest', (tester) async {
      await tester.pumpWidget(
        _host(
          const Row(
            children: <Widget>[
              AuraHourCell(
                time: 'Now',
                icon: AuraIcons.sun,
                iconTint: AuraColors.conditionSun,
                temperature: '35°',
                isNow: true,
              ),
              AuraHourCell(
                time: '3 PM',
                icon: AuraIcons.sun,
                iconTint: AuraColors.conditionSun,
                temperature: '36°',
              ),
            ],
          ),
        ),
      );
      final now = tester.widget<Text>(find.text('Now')).style!;
      final later = tester.widget<Text>(find.text('3 PM')).style!;
      expect(now.fontVariations, isNot(later.fontVariations));
      expect(now.color, AuraColors.textPrimary);
      expect(later.color, AuraColors.textSecondary);
    });
  });

  group('AuraCityCard', () {
    testWidgets('shows the city, condition and temperatures', (tester) async {
      await tester.pumpWidget(
        _host(
          const AuraCityCard(
            city: 'Cairo',
            localTime: '2:34 PM · Current',
            condition: 'Mostly Sunny',
            temperature: '35°',
            highLow: 'H:37° L:24°',
            sky: AuraSkyKind.clearDay,
          ),
        ),
      );
      expect(find.text('Cairo'), findsOneWidget);
      expect(find.text('Mostly Sunny'), findsOneWidget);
      expect(find.text('35°'), findsOneWidget);
      expect(find.text('H:37° L:24°'), findsOneWidget);
    });

    testWidgets('paints the sky belonging to that city', (tester) async {
      await tester.pumpWidget(
        _host(
          const AuraCityCard(
            city: 'London',
            localTime: '12:34 PM',
            condition: 'Rain Showers',
            temperature: '14°',
            highLow: 'H:16° L:9°',
            sky: AuraSkyKind.rain,
          ),
        ),
      );
      final decoration =
          tester
                  .widget<Container>(
                    find
                        .descendant(
                          of: find.byType(AuraCityCard),
                          matching: find.byType(Container),
                        )
                        .first,
                  )
                  .decoration!
              as BoxDecoration;
      expect(
        (decoration.gradient! as LinearGradient).colors,
        AuraSkies.rain.colors,
      );
    });

    testWidgets('uses Outfit for the temperature, matching the screens', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const AuraCityCard(
            city: 'Tokyo',
            localTime: '9:34 PM',
            condition: 'Clear',
            temperature: '24°',
            highLow: 'H:27° L:20°',
            sky: AuraSkyKind.clearNight,
          ),
        ),
      );
      expect(
        tester.widget<Text>(find.text('24°')).style!.fontFamily,
        'packages/${AuraFonts.package}/${AuraFonts.app}',
      );
    });

    testWidgets('reports itself as a button when tappable', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(
          AuraCityCard(
            city: 'Cairo',
            localTime: '2:34 PM',
            condition: 'Mostly Sunny',
            temperature: '35°',
            highLow: 'H:37° L:24°',
            sky: AuraSkyKind.clearDay,
            onTap: () => taps++,
          ),
        ),
      );
      await tester.tap(find.byType(AuraCityCard));
      expect(taps, 1);
    });
  });

  group('AuraAlertBanner', () {
    testWidgets('shows the event and its supporting line', (tester) async {
      await tester.pumpWidget(
        _host(
          const AuraAlertBanner(
            title: 'Heat Advisory',
            subtitle: 'In effect until 8:00 PM · tap for details',
          ),
        ),
      );
      expect(find.text('Heat Advisory'), findsOneWidget);
      expect(
        find.text('In effect until 8:00 PM · tap for details'),
        findsOneWidget,
      );
    });

    testWidgets('shows a chevron only when it leads somewhere', (tester) async {
      await tester.pumpWidget(
        _host(
          const AuraAlertBanner(title: 'Heat Advisory', subtitle: 'Until 8 PM'),
        ),
      );
      expect(find.byIcon(AuraIcons.chevronRight), findsNothing);

      await tester.pumpWidget(
        _host(
          AuraAlertBanner(
            title: 'Heat Advisory',
            subtitle: 'Until 8 PM',
            onTap: () {},
          ),
        ),
      );
      expect(find.byIcon(AuraIcons.chevronRight), findsOneWidget);
    });

    testWidgets('carries the alert tint rather than plain glass', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const AuraAlertBanner(title: 'Heat Advisory', subtitle: 'Until 8 PM'),
        ),
      );
      final decoration =
          tester
                  .widget<Container>(
                    find
                        .descendant(
                          of: find.byType(AuraAlertBanner),
                          matching: find.byType(Container),
                        )
                        .first,
                  )
                  .decoration!
              as BoxDecoration;
      expect(decoration.border!.bottom.color, AuraColors.alertBorder);
    });
  });

  group('AuraSettingsRow', () {
    testWidgets('shows a value and a chevron when it opens a picker', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          AuraSettingsRow(
            icon: AuraIcons.thermometer,
            label: 'Temperature',
            value: 'Celsius °C',
            onTap: () {},
          ),
        ),
      );
      expect(find.text('Temperature'), findsOneWidget);
      expect(find.text('Celsius °C'), findsOneWidget);
      expect(find.byIcon(AuraIcons.chevronRight), findsOneWidget);
    });

    testWidgets('shows a control instead when it acts in place', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          AuraSettingsRow(
            icon: AuraIcons.alert,
            label: 'Severe Weather Alerts',
            trailing: AuraToggle(value: true, onChanged: (_) {}),
          ),
        ),
      );
      expect(find.byType(AuraToggle), findsOneWidget);
      expect(find.byIcon(AuraIcons.chevronRight), findsNothing);
    });

    testWidgets('rejects being given both a value and a control', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          AuraSettingsRow(
            icon: AuraIcons.alert,
            label: 'Broken',
            value: 'On',
            trailing: AuraToggle(value: true, onChanged: (_) {}),
          ),
        ),
      );
      expect(tester.takeException(), isA<AssertionError>());
    });
  });
}
