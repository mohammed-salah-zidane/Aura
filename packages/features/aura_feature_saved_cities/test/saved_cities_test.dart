import 'package:aura_core/aura_core.dart';
import 'package:aura_design/aura_design.dart';
import 'package:aura_domain/aura_domain.dart';
import 'package:aura_feature_saved_cities/aura_feature_saved_cities.dart';
import 'package:aura_l10n/aura_l10n.dart';
import 'package:aura_providers/aura_providers.dart';
import 'package:aura_test_kit/aura_test_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

Future<AppLocalizations> _copy([Locale locale = const Locale('en')]) =>
    AppLocalizations.delegate.load(locale);

final class _Harness {
  _Harness({List<SavedCity> saved = const <SavedCity>[]})
    : repository = FakeWeatherRepository(),
      cities = FakeSavedCities(saved) {
    container = ProviderContainer(
      overrides: <Override>[
        clockProvider.overrideWithValue(FixedClock(fixtureNow)),
        weatherRepositoryProvider.overrideWithValue(repository),
        settingsPortProvider.overrideWithValue(FakeSettings()),
        savedCitiesPortProvider.overrideWithValue(cities),
      ],
    );
    addTearDown(container.dispose);
  }

  final FakeWeatherRepository repository;
  final FakeSavedCities cities;
  late final ProviderContainer container;

  Widget screen({VoidCallback? onOpenSearch, VoidCallback? onSelect}) =>
      UncontrolledProviderScope(
        container: container,
        child: SavedCitiesScreen(
          onOpenSearch: onOpenSearch ?? () {},
          onSelect: onSelect ?? () {},
        ),
      );
}

void main() {
  setUpAll(loadAuraFonts);

  group('SavedCitiesViewModel', () {
    test('build puts the device position at the top of the list', () async {
      final harness = _Harness(saved: <SavedCity>[savedCityFixture()]);
      final rows = await harness.container.read(
        savedCitiesViewModelProvider.future,
      );

      expect(rows.first.isCurrentLocation, isTrue);
      expect(rows.first.location.isCurrentLocation, isTrue);
      expect(rows, hasLength(2));
    });

    test('build keeps a place whose reading could not be fetched', () async {
      final harness = _Harness(saved: <SavedCity>[savedCityFixture()])
        ..repository.failure = const NoConnection();

      final rows = await harness.container.read(
        savedCitiesViewModelProvider.future,
      );

      expect(rows, hasLength(2));
      expect(rows.last.snapshot, isNull);
      expect(rows.last.name, 'London');
    });

    test('remove forgets the place', () async {
      final harness = _Harness(saved: <SavedCity>[savedCityFixture()]);
      await harness.container.read(savedCitiesViewModelProvider.future);

      await harness.container
          .read(savedCitiesViewModelProvider.notifier)
          .remove(savedCityFixture().location);

      expect(harness.cities.cities, isEmpty);
    });
  });

  group('SavedCitiesScreen', () {
    testWidgets('build shows the heading and the way into search', (
      tester,
    ) async {
      final harness = _Harness();
      await pumpScreen(tester, harness.screen());
      await tester.pumpAndSettle();
      final l10n = await _copy();

      expect(find.text(l10n.savedCitiesTitle), findsOneWidget);
      expect(find.text(l10n.searchPlaceholder), findsOneWidget);
    });

    testWidgets('build the search field opens search rather than a keyboard', (
      tester,
    ) async {
      var opened = 0;
      final harness = _Harness();
      await pumpScreen(tester, harness.screen(onOpenSearch: () => opened++));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(AuraSearchField));
      await tester.pump();

      expect(opened, 1);
      expect(find.byType(EditableText), findsNothing);
    });

    testWidgets('build marks the device position as the current one', (
      tester,
    ) async {
      final harness = _Harness();
      await pumpScreen(tester, harness.screen());
      await tester.pumpAndSettle();
      final l10n = await _copy();

      expect(
        find.textContaining(RegExp('Current')),
        findsOneWidget,
        reason: 'the device position was not marked as the current one',
      );
      expect(find.text(l10n.savedCitiesTitle), findsOneWidget);
    });

    testWidgets('build a card carries the reading for its place', (
      tester,
    ) async {
      final harness = _Harness(saved: <SavedCity>[savedCityFixture()]);
      await pumpScreen(tester, harness.screen());
      await tester.pumpAndSettle();

      expect(find.byType(AuraCityCard), findsNWidgets(2));
      expect(find.text('35°'), findsNWidgets(2));
    });

    testWidgets('build picking a place makes it the one home shows', (
      tester,
    ) async {
      var selected = 0;
      final city = savedCityFixture();
      final harness = _Harness(saved: <SavedCity>[city]);
      await pumpScreen(tester, harness.screen(onSelect: () => selected++));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(AuraCityCard).last);
      await tester.pumpAndSettle();

      expect(harness.container.read(activeLocationProvider), city.location);
      expect(selected, 1);
    });

    testWidgets('build the remove control appears only while editing', (
      tester,
    ) async {
      final harness = _Harness(saved: <SavedCity>[savedCityFixture()]);
      await pumpScreen(tester, harness.screen());
      await tester.pumpAndSettle();
      expect(find.byIcon(AuraIcons.close), findsNothing);

      await tester.tap(find.byIcon(AuraIcons.more));
      await tester.pumpAndSettle();

      // One on the card, and one on the button that leaves editing.
      expect(find.byIcon(AuraIcons.close), findsNWidgets(2));
    });

    testWidgets('build removing a place forgets it', (tester) async {
      final harness = _Harness(saved: <SavedCity>[savedCityFixture()]);
      await pumpScreen(tester, harness.screen());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(AuraIcons.more));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AuraCityCard),
          matching: find.byIcon(AuraIcons.close),
        ),
      );
      await tester.pumpAndSettle();

      expect(harness.cities.cities, isEmpty);
    });

    testWidgets('build the device position cannot be forgotten', (
      tester,
    ) async {
      final harness = _Harness();
      await pumpScreen(tester, harness.screen());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(AuraIcons.more));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(AuraCityCard),
          matching: find.byIcon(AuraIcons.close),
        ),
        findsNothing,
      );
    });

    testWidgets('build renders the Arabic screen without overflowing', (
      tester,
    ) async {
      final harness = _Harness(saved: <SavedCity>[savedCityFixture()]);
      await pumpScreen(tester, harness.screen(), locale: const Locale('ar'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
