@Tags(<String>['golden'])
library;

import 'package:aura_core/aura_core.dart';
import 'package:aura_design/aura_design.dart';
import 'package:aura_domain/aura_domain.dart';
import 'package:aura_feature_onboarding/aura_feature_onboarding.dart';
import 'package:aura_providers/aura_providers.dart';
import 'package:aura_test_kit/aura_test_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
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
      await pumpSplash(tester);
      await expectGolden(tester, 'splash_en');
    });

    testWidgets('Arabic', (tester) async {
      await pumpSplash(tester, locale: const Locale('ar'));
      await expectGolden(tester, 'splash_ar');
    });
  });

  group('permission', () {
    Widget subject() => ProviderScope(
      overrides: <Override>[
        locationPortProvider.overrideWithValue(
          const _Location(LocationPermission.notDetermined),
        ),
      ],
      child: PermissionScreen(onDone: () {}, onEnterManually: () {}),
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

/// Pumps the splash and lets its decision resolve.
///
/// The screen holds itself on screen for one turn of the loader before it
/// answers, so a test that never advances the clock leaves that timer pending
/// and the binding fails the test on it.
Future<void> pumpSplash(
  WidgetTester tester, {
  Locale locale = const Locale('en'),
  LocationPermission permission = LocationPermission.notDetermined,
  List<SavedCity> saved = const <SavedCity>[],
  ValueChanged<SplashDestination>? onReady,
}) async {
  await pumpScreen(
    tester,
    splashScreen(permission: permission, saved: saved, onReady: onReady),
    locale: locale,
  );
  await tester.pump(SplashViewModel.minimumOnScreen);
  await tester.pump(AuraMotion.control);
}

/// A splash screen with its ports wired to fakes.
///
/// The screen decides where the app opens as soon as it is built, so it needs
/// a location port and a saved list even when the test is only looking at the
/// lockup.
Widget splashScreen({
  LocationPermission permission = LocationPermission.notDetermined,
  List<SavedCity> saved = const <SavedCity>[],
  ValueChanged<SplashDestination>? onReady,
}) => ProviderScope(
  overrides: <Override>[
    locationPortProvider.overrideWithValue(_Location(permission)),
    savedCitiesPortProvider.overrideWithValue(_Cities(saved)),
  ],
  child: SplashScreen(onReady: onReady ?? (_) {}),
);

class _Location implements LocationPort {
  const _Location(this._permission);

  final LocationPermission _permission;

  @override
  Future<LocationPermission> permission() async => _permission;

  @override
  Future<LocationPermission> request() async => _permission;

  @override
  Future<Result<LocationRef, AppFailure>> currentPosition() async =>
      Ok<LocationRef, AppFailure>(
        LocationRef.coordinates(latitude: 30.04, longitude: 31.24),
      );
}

class _Cities implements SavedCitiesPort {
  const _Cities(this._saved);

  final List<SavedCity> _saved;

  @override
  Future<Result<List<SavedCity>, AppFailure>> readAll() async =>
      Ok<List<SavedCity>, AppFailure>(_saved);

  @override
  Future<Result<void, AppFailure>> add(SavedCity city) async =>
      const Ok<void, AppFailure>(null);

  @override
  Future<Result<void, AppFailure>> remove(LocationRef location) async =>
      const Ok<void, AppFailure>(null);
}
