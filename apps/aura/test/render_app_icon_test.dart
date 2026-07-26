@Tags(<String>['icons'])
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:aura_design/aura_design.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Renders the app icon from the Aura mark itself.
///
/// The icon is the mark on the splash sky, so it comes from the same painter
/// the splash screen uses rather than from a copy someone drew beside it. Run
/// with `flutter test --tags icons` after the mark changes, and commit what it
/// writes.
void main() {
  testWidgets('renders every icon the two platforms ask for', (tester) async {
    for (final entry in _iosSizes.entries) {
      await _write(
        tester,
        const _Icon(),
        entry.value,
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/${entry.key}',
      );
    }

    for (final entry in _androidDensities.entries) {
      await _write(
        tester,
        const _Icon(),
        entry.value,
        'android/app/src/main/res/mipmap-${entry.key}/ic_launcher.png',
      );
      // The adaptive foreground is drawn on a 108 unit canvas whose middle 72
      // is all that is guaranteed to be visible, so the mark is inset by a
      // third and the launcher can mask the rest to any shape it likes.
      await _write(
        tester,
        const _AdaptiveForeground(),
        (entry.value * 108) ~/ 48,
        'android/app/src/main/res/mipmap-${entry.key}/ic_launcher_foreground.png',
      );
      await _write(
        tester,
        const _AdaptiveForeground(monochrome: true),
        (entry.value * 108) ~/ 48,
        'android/app/src/main/res/mipmap-${entry.key}/ic_launcher_monochrome.png',
      );
    }
  });
}

/// The iOS slots, from the asset catalogue.
const Map<String, int> _iosSizes = <String, int>{
  'Icon-App-20x20@1x.png': 20,
  'Icon-App-20x20@2x.png': 40,
  'Icon-App-20x20@3x.png': 60,
  'Icon-App-29x29@1x.png': 29,
  'Icon-App-29x29@2x.png': 58,
  'Icon-App-29x29@3x.png': 87,
  'Icon-App-40x40@1x.png': 40,
  'Icon-App-40x40@2x.png': 80,
  'Icon-App-40x40@3x.png': 120,
  'Icon-App-60x60@2x.png': 120,
  'Icon-App-60x60@3x.png': 180,
  'Icon-App-76x76@1x.png': 76,
  'Icon-App-76x76@2x.png': 152,
  'Icon-App-83.5x83.5@2x.png': 167,
  'Icon-App-1024x1024@1x.png': 1024,
};

/// The Android launcher densities, at their legacy 48 unit base.
const Map<String, int> _androidDensities = <String, int>{
  'mdpi': 48,
  'hdpi': 72,
  'xhdpi': 96,
  'xxhdpi': 144,
  'xxxhdpi': 192,
};

/// The mark on the splash sky, filling the icon.
class _Icon extends StatelessWidget {
  const _Icon();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: AuraSkies.splash.colors,
          stops: AuraSkies.splash.stops,
        ),
      ),
      child: const Center(
        child: FractionallySizedBox(
          widthFactor: 0.62,
          child: AspectRatio(aspectRatio: 1, child: _Mark()),
        ),
      ),
    );
  }
}

/// The mark alone, inset for the adaptive mask.
class _AdaptiveForeground extends StatelessWidget {
  const _AdaptiveForeground({this.monochrome = false});

  final bool monochrome;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FractionallySizedBox(
        widthFactor: 0.42,
        child: AspectRatio(
          aspectRatio: 1,
          child: _Mark(monochrome: monochrome),
        ),
      ),
    );
  }
}

/// The mark at whatever size it is given.
///
/// `AuraMark` is a closed set of the sizes the screens draw, because its ring
/// stroke is authored per size. An icon is none of those sizes, so it scales
/// the largest one rather than inventing a stroke.
class _Mark extends StatelessWidget {
  const _Mark({this.monochrome = false});

  final bool monochrome;

  @override
  Widget build(BuildContext context) {
    final mark = SizedBox.square(
      dimension: AuraMarkSize.splash.diameter,
      child: const AuraMark(size: AuraMarkSize.splash),
    );
    return FittedBox(
      child: monochrome
          ? ColorFiltered(
              colorFilter: const ColorFilter.mode(
                AuraColors.textPrimary,
                BlendMode.srcATop,
              ),
              child: mark,
            )
          : mark,
    );
  }
}

Future<void> _write(
  WidgetTester tester,
  Widget icon,
  int size,
  String path,
) async {
  // The root of a pumped tree fills the view, so the view is what decides how
  // large the capture is.
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = Size(size.toDouble(), size.toDouble());
  addTearDown(tester.view.reset);

  final key = GlobalKey();
  await tester.pumpWidget(RepaintBoundary(key: key, child: icon));
  await tester.pump();

  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  // Encoding a layer tree is real asynchronous work, and the fake clock a
  // widget test runs under never lets it finish.
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File(path)
      ..createSync(recursive: true)
      ..writeAsBytesSync(bytes!.buffer.asUint8List());
    image.dispose();
  });
}
