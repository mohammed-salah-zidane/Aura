@Tags(<String>['golden'])
library;

import 'package:aura_feature_onboarding/aura_feature_onboarding.dart';
import 'package:aura_test_kit/aura_test_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Goldens are taken at the 393 by 852 canvas the design was drawn on, at a
/// pixel ratio of 1, so a file lines up with its pen frame point for point.
///
/// They exist to catch what a widget test cannot see: a fill layer that stopped
/// being painted, tracking that broke an Arabic word into pieces, a font that
/// silently fell back. Regenerate with `melos run gold:update` and read the
/// diff by eye before committing it.
void main() {
  setUpAll(loadAuraFonts);

  Future<void> expectGolden(WidgetTester tester, String name) => expectLater(
    find.byType(Directionality).first,
    matchesGoldenFile('goldens/$name.png'),
  );

  group('splash', () {
    testWidgets('English', (tester) async {
      await pumpScreen(tester, const SplashScreen());
      await expectGolden(tester, 'splash_en');
    });

    testWidgets('Arabic', (tester) async {
      await pumpScreen(
        tester,
        const SplashScreen(),
        locale: const Locale('ar'),
      );
      await expectGolden(tester, 'splash_ar');
    });
  });

  group('permission', () {
    Widget subject() => PermissionScreen(
      onAllow: () {},
      onEnterManually: () {},
    );

    testWidgets('English', (tester) async {
      await pumpScreen(tester, subject());
      await expectGolden(tester, 'permission_en');
    });

    testWidgets('Arabic', (tester) async {
      await pumpScreen(tester, subject(), locale: const Locale('ar'));
      await expectGolden(tester, 'permission_ar');
    });
  });
}
