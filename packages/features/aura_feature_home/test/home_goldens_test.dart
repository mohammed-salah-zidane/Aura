@Tags(<String>['golden'])
library;

import 'package:aura_core/aura_core.dart';
import 'package:aura_domain/aura_domain.dart';
import 'package:aura_test_kit/aura_test_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/home_harness.dart';

/// Goldens are taken at the 393 by 852 canvas the design was drawn on.
///
/// The weather screen is taller than a phone, so its golden is taken at the
/// full height of the page: a file cut off at 852 points would only ever prove
/// the hero still renders.
const Size _page = Size(393, 1700);

void main() {
  setUpAll(loadAuraFonts);

  Future<void> expectGolden(WidgetTester tester, String name) => expectLater(
    find.byType(Directionality).first,
    matchesGoldenFile('goldens/$name.png'),
  );

  Future<void> pumpHome(
    WidgetTester tester,
    HomeHarness harness, {
    Locale locale = const Locale('en'),
    Size size = _page,
  }) async {
    await pumpScreen(
      tester,
      harness.screen(),
      locale: locale,
      size: size,
    );
    await tester.pumpAndSettle();
  }

  group('weather', () {
    testWidgets('English', (tester) async {
      await pumpHome(
        tester,
        HomeHarness(
          snapshot: weatherFixture(
            alerts: <WeatherAlert>[alertFixture()],
          ),
        ),
      );
      await expectGolden(tester, 'home_en');
    });

    testWidgets('Arabic', (tester) async {
      await pumpHome(
        tester,
        HomeHarness(
          snapshot: weatherFixture(
            alerts: <WeatherAlert>[alertFixture()],
          ),
        ),
        locale: const Locale('ar'),
      );
      await expectGolden(tester, 'home_ar');
    });
  });

  group('offline', () {
    testWidgets('English', (tester) async {
      await pumpHome(
        tester,
        HomeHarness(
          fetchedAt: fixtureNow.subtract(const Duration(hours: 2)),
        ),
        size: const Size(393, 852),
      );
      await expectGolden(tester, 'home_offline_en');
    });

    testWidgets('Arabic', (tester) async {
      await pumpHome(
        tester,
        HomeHarness(
          fetchedAt: fixtureNow.subtract(const Duration(hours: 2)),
        ),
        locale: const Locale('ar'),
        size: const Size(393, 852),
      );
      await expectGolden(tester, 'home_offline_ar');
    });
  });

  group('unavailable', () {
    testWidgets('English', (tester) async {
      await pumpHome(
        tester,
        HomeHarness(failure: const RateLimited()),
        size: const Size(393, 852),
      );
      await expectGolden(tester, 'home_unavailable_en');
    });
  });

  group('loading', () {
    testWidgets('English', (tester) async {
      final harness = HomeHarness(delay: const Duration(seconds: 5));
      await pumpScreen(tester, harness.screen());
      await expectGolden(tester, 'home_loading_en');
      await tester.pumpAndSettle(const Duration(seconds: 6));
    });
  });
}
