import 'package:aura_core/aura_core.dart';
import 'package:aura_domain/aura_domain.dart';
import 'package:aura_feature_home/aura_feature_home.dart';
import 'package:aura_test_kit/aura_test_kit.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/home_harness.dart';

void main() {
  group('build', () {
    test('build a reading fetched this run is ready', () async {
      final harness = HomeHarness();
      expect(await harness.state(), isA<HomeReady>());
    });

    test(
      'build a reading older than the request is offered, not shown',
      () async {
        // The repository fell back to the cache, so the app has data and no
        // network. The design puts the offline screen in front of the reading
        // rather than handing over yesterday's weather with nothing to say so.
        final harness = HomeHarness(
          fetchedAt: fixtureNow.subtract(const Duration(hours: 2)),
        );

        final state = await harness.state();
        expect(state, isA<HomeStale>());
        expect((state as HomeStale).age, const Duration(hours: 2));
      },
    );

    test('build a failure carries the reason the screen explains', () async {
      final harness = HomeHarness(failure: const NoConnection());
      final state = await harness.state();

      expect(state, isA<HomeUnavailable>());
      expect((state as HomeUnavailable).failure, const NoConnection());
    });

    test('build the units the screen draws in come from storage', () async {
      final harness = HomeHarness()
        ..settings.units = const UnitPreferences(
          temperature: TemperatureUnit.fahrenheit,
        );

      final state = await harness.state();
      expect(state.units.temperature, TemperatureUnit.fahrenheit);
    });
  });

  group('useStoredReading', () {
    test(
      'useStoredReading shows the reading the offline screen offered',
      () async {
        final harness = HomeHarness(
          fetchedAt: fixtureNow.subtract(const Duration(hours: 2)),
        );
        await harness.state();

        harness.container
            .read(homeViewModelProvider.notifier)
            .useStoredReading();

        expect(
          harness.container.read(homeViewModelProvider).value,
          isA<HomeReady>(),
        );
      },
    );

    test(
      'useStoredReading fetches nothing, because the reading is in hand',
      () async {
        final harness = HomeHarness(
          fetchedAt: fixtureNow.subtract(const Duration(hours: 2)),
        );
        await harness.state();
        final before = harness.repository.snapshotCalls;

        harness.container
            .read(homeViewModelProvider.notifier)
            .useStoredReading();

        expect(harness.repository.snapshotCalls, before);
      },
    );

    test(
      'useStoredReading does nothing when the reading is already live',
      () async {
        final harness = HomeHarness();
        await harness.state();

        harness.container
            .read(homeViewModelProvider.notifier)
            .useStoredReading();

        expect(
          harness.container.read(homeViewModelProvider).value,
          isA<HomeReady>(),
        );
      },
    );
  });

  group('refresh', () {
    test('refresh asks the service again', () async {
      final harness = HomeHarness();
      await harness.state();
      final before = harness.repository.snapshotCalls;

      await harness.container.read(homeViewModelProvider.notifier).refresh();

      expect(harness.repository.snapshotCalls, greaterThan(before));
    });

    test('refresh takes back a stored reading the user had accepted', () async {
      // Accepting stale data is about the reading in hand. Asking again is a
      // new question, and its answer stands on its own.
      final harness = HomeHarness(
        fetchedAt: fixtureNow.subtract(const Duration(hours: 2)),
      );
      await harness.state();
      harness.container.read(homeViewModelProvider.notifier).useStoredReading();

      await harness.container.read(homeViewModelProvider.notifier).refresh();

      expect(await harness.state(), isA<HomeStale>());
    });
  });
}
