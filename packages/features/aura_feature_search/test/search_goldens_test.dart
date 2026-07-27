@Tags(<String>['golden'])
library;

import 'package:aura_domain/aura_domain.dart';
import 'package:aura_test_kit/aura_test_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/search_harness.dart';

void main() {
  setUpAll(loadAuraFonts);

  Future<void> expectGolden(WidgetTester tester, String name) => expectLater(
    find.byType(Directionality).first,
    matchesGoldenFile('goldens/$name.png'),
  );

  for (final locale in const <Locale>[Locale('en'), Locale('ar')]) {
    testWidgets('search ${locale.languageCode}', (tester) async {
      final harness = searchHarness(
        suggestions: <CitySuggestion>[
          citySuggestion('Cairo'),
          citySuggestion(
            'Cairns',
            region: 'Queensland',
            country: 'Australia',
          ),
        ],
        reading: cityReading(28),
      );
      await pumpScreen(
        tester,
        harness.screen(),
        locale: locale,
      );
      await tester.enterText(find.byType(EditableText), 'Cair');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();

      await expectGolden(tester, 'search_${locale.languageCode}');
    });
  }
}
