import 'package:aura_core/aura_core.dart';
import 'package:aura_domain/aura_domain.dart';
import 'package:aura_feature_search/aura_feature_search.dart';
import 'package:aura_l10n/aura_l10n.dart';
import 'package:aura_providers/aura_providers.dart';
import 'package:aura_test_kit/aura_test_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/search_harness.dart';

/// Long enough for the field to go quiet and the request to land.
const Duration _settled = Duration(milliseconds: 500);

void main() {
  setUpAll(loadAuraFonts);

  group('SearchViewModel', () {
    test('query an empty box asks nothing of the service', () async {
      final harness = SearchHarness(
        suggestions: <CitySuggestion>[
          citySuggestion('Cairo'),
        ],
      );

      harness.viewModel.query('   ');
      await Future<void>.delayed(_settled);

      expect(harness.container.read(searchViewModelProvider).hasQuery, isFalse);
    });

    test('query answers with the matches the service returned', () async {
      final harness = SearchHarness(
        suggestions: <CitySuggestion>[
          citySuggestion('Cairo'),
          citySuggestion('Cairns', region: 'Queensland'),
        ],
      );

      harness.viewModel.query('Cair');
      await Future<void>.delayed(_settled);

      final state = harness.container.read(searchViewModelProvider);
      expect(state.matches.map((m) => m.suggestion.name), <String>[
        'Cairo',
        'Cairns',
      ]);
    });

    test('query fills a reading in beside every match', () async {
      final harness = SearchHarness(
        suggestions: <CitySuggestion>[citySuggestion('Cairo')],
        reading: cityReading(35),
      );

      harness.viewModel.query('Cairo');
      await Future<void>.delayed(_settled);

      final state = harness.container.read(searchViewModelProvider);
      expect(state.matches.single.reading, isNotNull);
    });

    test(
      'query leaves a match without a reading rather than failing',
      () async {
        // The name is still the answer the user asked for.
        final harness = SearchHarness(
          suggestions: <CitySuggestion>[citySuggestion('Cairo')],
        );

        harness.viewModel.query('Cairo');
        await Future<void>.delayed(_settled);

        final state = harness.container.read(searchViewModelProvider);
        expect(state.matches.single.reading, isNull);
        expect(state.failure, isNull);
      },
    );

    test(
      'query a failure is reported and clears the previous matches',
      () async {
        final harness = SearchHarness(searchFailure: const NoConnection());

        harness.viewModel.query('Cairo');
        await Future<void>.delayed(_settled);

        final state = harness.container.read(searchViewModelProvider);
        expect(state.failure, const NoConnection());
        expect(state.matches, isEmpty);
      },
    );

    test('query the service is asked once for a burst of keystrokes', () async {
      final harness = SearchHarness(
        suggestions: <CitySuggestion>[citySuggestion('Cairo')],
      );

      harness.viewModel
        ..query('C')
        ..query('Ca')
        ..query('Cai');
      await Future<void>.delayed(_settled);

      expect(
        harness.container.read(searchViewModelProvider).matches,
        hasLength(1),
      );
    });

    test(
      'useCurrentLocation takes the device position when it is allowed',
      () async {
        final position = LocationRef.coordinates(
          latitude: 30.04,
          longitude: 31.24,
        );
        final harness = SearchHarness(
          permission: LocationPermission.granted,
          position: position,
        );

        await harness.viewModel.useCurrentLocation();

        expect(harness.container.read(activeLocationProvider), position);
      },
    );

    test(
      'useCurrentLocation asks for permission when it has never been asked',
      () async {
        final harness = SearchHarness();
        await harness.viewModel.useCurrentLocation();
        expect(harness.location.requests, 1);
      },
    );

    test(
      'useCurrentLocation falls back to the address the service resolves',
      () async {
        // Refusing is never a dead end: `q=auto:ip` needs no permission at all.
        final harness = SearchHarness(permission: LocationPermission.denied);
        await harness.viewModel.useCurrentLocation();

        expect(
          harness.container.read(activeLocationProvider).isCurrentLocation,
          isTrue,
        );
      },
    );

    test('save keeps the place the user picked', () async {
      final harness = SearchHarness();
      await harness.viewModel.save(citySuggestion('Cairo'));
      expect(harness.cities.cities.single.name, 'Cairo');
    });
  });

  group('SearchScreen', () {
    testWidgets('build shows the heading and the way out of the screen', (
      tester,
    ) async {
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      final harness = SearchHarness();
      await pumpScreen(tester, harness.screen());

      expect(find.text(l10n.searchTitle), findsOneWidget);
      expect(find.text(l10n.searchUseCurrentLocation), findsOneWidget);
    });

    testWidgets('build lists nothing until something is typed', (tester) async {
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      final harness = SearchHarness(
        suggestions: <CitySuggestion>[citySuggestion('Cairo')],
      );
      await pumpScreen(tester, harness.screen());

      expect(
        find.text(l10n.searchResultsLabel.toUpperCase()),
        findsNothing,
      );
    });

    testWidgets('build shows each match with its place and its reading', (
      tester,
    ) async {
      final harness = SearchHarness(
        suggestions: <CitySuggestion>[
          citySuggestion('Cairns', region: 'Queensland'),
        ],
        reading: cityReading(28),
      );
      await pumpScreen(tester, harness.screen());

      await tester.enterText(find.byType(EditableText), 'Cair');
      await tester.pump(_settled);
      await tester.pump();

      expect(find.text('Cairns'), findsOneWidget);
      expect(find.text('Queensland, Egypt'), findsOneWidget);
      expect(find.text('28°'), findsOneWidget);
    });

    testWidgets('build says so when the service matched nothing', (
      tester,
    ) async {
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      final harness = SearchHarness();
      await pumpScreen(tester, harness.screen());

      await tester.enterText(find.byType(EditableText), 'zzzz');
      await tester.pump(_settled);
      await tester.pump();

      expect(find.text(l10n.searchNoResults), findsOneWidget);
    });

    testWidgets('build picking a match makes it the place home shows', (
      tester,
    ) async {
      var done = 0;
      final harness = SearchHarness(
        suggestions: <CitySuggestion>[citySuggestion('Cairo')],
        reading: cityReading(35),
      );
      await pumpScreen(tester, harness.screen(onDone: () => done++));

      await tester.enterText(find.byType(EditableText), 'Cairo');
      await tester.pump(_settled);
      await tester.pump();
      // The query is in the field as well as in the list, so the tap has to
      // name the row rather than the word.
      await tester.tap(
        find.descendant(
          of: find.byType(SearchResults),
          matching: find.text('Cairo'),
        ),
      );
      await tester.pumpAndSettle();

      expect(harness.container.read(activeLocationProvider).query, 'Cairo');
      expect(harness.cities.cities, hasLength(1));
      expect(done, 1);
    });

    testWidgets('build renders the Arabic screen without overflowing', (
      tester,
    ) async {
      final harness = SearchHarness();
      await pumpScreen(tester, harness.screen(), locale: const Locale('ar'));
      expect(tester.takeException(), isNull);
    });
  });
}
