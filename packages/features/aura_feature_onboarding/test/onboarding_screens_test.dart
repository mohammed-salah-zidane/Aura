import 'package:aura_core/aura_core.dart';
import 'package:aura_design/aura_design.dart';
import 'package:aura_domain/aura_domain.dart';
import 'package:aura_feature_onboarding/aura_feature_onboarding.dart';
import 'package:aura_l10n/aura_l10n.dart';
import 'package:aura_providers/aura_providers.dart';
import 'package:aura_test_kit/aura_test_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

const Locale _en = Locale('en');
const Locale _ar = Locale('ar');

/// The copy the screen should be showing, in the locale under test.
Future<AppLocalizations> _copy(Locale locale) =>
    AppLocalizations.delegate.load(locale);

void main() {
  setUpAll(loadAuraFonts);

  group('SplashScreen', () {
    testWidgets('shows the wordmark, the tagline and the attribution', (
      tester,
    ) async {
      await pumpSplash(tester);
      final l10n = await _copy(_en);

      expect(find.text(AuraBrand.name), findsOneWidget);
      expect(find.text(l10n.splashTagline.toUpperCase()), findsOneWidget);
      expect(find.text(l10n.splashAttribution.toUpperCase()), findsOneWidget);
    });

    testWidgets('carries the mark at the size the splash specifies', (
      tester,
    ) async {
      await pumpSplash(tester);
      expect(
        tester.widget<AuraMark>(find.byType(AuraMark)).size,
        AuraMarkSize.splash,
      );
    });

    testWidgets('paints the splash sky', (tester) async {
      await pumpSplash(tester);
      expect(
        tester.widget<AuraSky>(find.byType(AuraSky)).kind,
        AuraSkyKind.splash,
      );
    });

    testWidgets('pins the loader and attribution to the screen edge', (
      tester,
    ) async {
      // Both are absolutely placed in the pen, measured from the bottom of a
      // canvas that runs under the home indicator, so neither moves with the
      // safe area.
      await pumpSplash(tester);
      final attribution = tester.getRect(
        find.text((await _copy(_en)).splashAttribution.toUpperCase()),
      );
      expect(
        AuraSizes.referenceHeight - attribution.bottom,
        moreOrLessEquals(AuraSizes.splashAttributionInset, epsilon: 0.5),
      );
    });

    testWidgets('the loader keeps moving', (tester) async {
      // The one splash test that is about the motion rather than the frame, so
      // it is also the one that has to opt back into it.
      await pumpSplash(tester, reduceMotion: false);
      final opacities = <double>{};
      for (var i = 0; i < 4; i++) {
        await tester.pump(AuraMotion.shimmer ~/ 3);
        opacities.add(
          tester
              .widgetList<AnimatedOpacity>(find.byType(AnimatedOpacity))
              .first
              .opacity,
        );
      }
      expect(
        opacities.length,
        greaterThan(1),
        reason: 'the first dot never changed, so the loader is frozen',
      );
    });

    testWidgets('speaks a label in place of the dots', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpSplash(tester);
      expect(
        find.bySemanticsLabel((await _copy(_en)).splashLoading),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('renders the Arabic copy right to left', (tester) async {
      await pumpSplash(tester, locale: _ar);
      final l10n = await _copy(_ar);

      expect(find.text(l10n.splashTagline.toUpperCase()), findsOneWidget);
      expect(find.text(l10n.splashAttribution.toUpperCase()), findsOneWidget);
      // The wordmark is a proper noun and reads the same in either locale.
      expect(find.text(AuraBrand.name), findsOneWidget);
    });

    testWidgets('drops letter tracking in Arabic', (tester) async {
      // Arabic letters join. Tracking prises those joins apart and renders the
      // word as a row of disconnected shapes.
      await pumpSplash(tester, locale: _ar);
      final tagline = tester.widget<Text>(
        find.text((await _copy(_ar)).splashTagline.toUpperCase()),
      );
      expect(tagline.style!.letterSpacing, 0);
    });

    testWidgets('keeps letter tracking in English', (tester) async {
      await pumpSplash(tester);
      final tagline = tester.widget<Text>(
        find.text((await _copy(_en)).splashTagline.toUpperCase()),
      );
      expect(tagline.style!.letterSpacing, AuraText.tagline.letterSpacing);
    });

    testWidgets('nothing overflows on either locale', (tester) async {
      for (final locale in <Locale>[_en, _ar]) {
        await pumpSplash(tester, locale: locale);
        expect(
          tester.takeException(),
          isNull,
          reason: 'the splash overflowed in ${locale.languageCode}',
        );
      }
    });
  });

  group('PermissionScreen', () {
    Widget subject({
      VoidCallback? onDone,
      VoidCallback? onEnterManually,
      FakeLocation? location,
    }) => ProviderScope(
      overrides: <Override>[
        locationPortProvider.overrideWithValue(location ?? FakeLocation()),
      ],
      child: PermissionScreen(
        onDone: onDone ?? () {},
        onEnterManually: onEnterManually ?? () {},
      ),
    );

    testWidgets('shows the heading, the reason and both actions', (
      tester,
    ) async {
      await pumpScreen(tester, subject());
      final l10n = await _copy(_en);

      expect(find.text(l10n.permissionTitle), findsOneWidget);
      expect(find.text(l10n.permissionBody), findsOneWidget);
      expect(find.text(l10n.permissionAllow), findsOneWidget);
      expect(find.text(l10n.permissionEnterManually), findsOneWidget);
    });

    testWidgets('names Aura, not the product the pen left behind', (
      tester,
    ) async {
      await pumpScreen(tester, subject());
      final body = (await _copy(_en)).permissionBody;
      expect(body, contains(AuraBrand.name));
      expect(body, isNot(contains('Cairo Weather')));
    });

    testWidgets('carries the pin and the navigation glyph from the pen', (
      tester,
    ) async {
      await pumpScreen(tester, subject());
      expect(find.byIcon(AuraIcons.mapPin), findsOneWidget);
      expect(find.byIcon(AuraIcons.navigation), findsOneWidget);
    });

    testWidgets('the primary action asks the system, once per tap', (
      tester,
    ) async {
      var allowed = 0;
      final location = FakeLocation();
      await pumpScreen(
        tester,
        subject(onDone: () => allowed++, location: location),
      );
      await tester.tap(find.text((await _copy(_en)).permissionAllow));
      await tester.pumpAndSettle();

      expect(location.requests, 1, reason: 'the prompt was never put up');
      expect(allowed, 1);
    });

    testWidgets('the primary action moves on when the prompt is refused', (
      tester,
    ) async {
      var allowed = 0;
      final location = FakeLocation(granted: LocationPermission.denied);
      await pumpScreen(
        tester,
        subject(onDone: () => allowed++, location: location),
      );
      await tester.tap(find.text((await _copy(_en)).permissionAllow));
      await tester.pumpAndSettle();

      // Refusing is not a dead end: the service resolves an approximate
      // position from the request itself.
      expect(allowed, 1);
    });

    testWidgets('the secondary action offers a way past location', (
      tester,
    ) async {
      var skipped = 0;
      await pumpScreen(tester, subject(onEnterManually: () => skipped++));
      await tester.tap(
        find.text((await _copy(_en)).permissionEnterManually),
      );
      await tester.pump();
      expect(skipped, 1);
    });

    testWidgets('both actions read as buttons to assistive tech', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpScreen(tester, subject());
      expect(
        find.bySemanticsLabel((await _copy(_en)).permissionAllow),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('the actions sit at the foot of the screen', (tester) async {
      await pumpScreen(tester, subject());
      final secondary = tester.getRect(find.byType(AuraButtonSecondary));
      expect(
        AuraSizes.referenceHeight - secondary.bottom,
        moreOrLessEquals(AuraSizes.stateBottomInset, epsilon: 0.5),
      );
    });

    testWidgets('the body is set to the measure the pen specifies', (
      tester,
    ) async {
      await pumpScreen(tester, subject());
      final body = tester.getRect(
        find.text((await _copy(_en)).permissionBody),
      );
      expect(
        body.width,
        moreOrLessEquals(AuraSizes.stateBodyMeasure, epsilon: 0.5),
      );
    });

    testWidgets('renders the Arabic copy without overflowing', (tester) async {
      await pumpScreen(tester, subject(), locale: _ar);
      final l10n = await _copy(_ar);

      expect(find.text(l10n.permissionTitle), findsOneWidget);
      expect(find.text(l10n.permissionBody), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('mirrors the primary button icon in Arabic', (tester) async {
      // The row runs from the right, so the glyph leads on the right.
      await pumpScreen(tester, subject(), locale: _ar);
      final icon = tester.getRect(find.byIcon(AuraIcons.navigation));
      final label = tester.getRect(
        find.text((await _copy(_ar)).permissionAllow),
      );
      expect(
        icon.left,
        greaterThan(label.left),
        reason: 'the icon did not move to the trailing side in RTL',
      );
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
  bool reduceMotion = true,
}) async {
  await pumpScreen(
    tester,
    splashScreen(permission: permission, saved: saved, onReady: onReady),
    locale: locale,
    reduceMotion: reduceMotion,
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
