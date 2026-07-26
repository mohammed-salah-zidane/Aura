import 'package:aura/src/di/providers.dart';
import 'package:aura/src/router/aura_router.dart';
import 'package:aura_design/aura_design.dart';
import 'package:aura_l10n/aura_l10n.dart';
import 'package:aura_providers/aura_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Entry point. Composition happens here and nowhere else.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  registerAuraFontLicenses();
  await AuraLocales.loadDateSymbols();

  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
  ]);

  // The sky runs to both edges and the system bars sit on it. Which way round
  // their icons go is declared by AuraSky, because a style set once here is
  // overridden by the window on both platforms.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Read once here rather than in the settings screen: the version is a fact
  // about the package, and a feature that read it would need a plugin of its
  // own to do it.
  final package = await PackageInfo.fromPlatform();

  runApp(
    ProviderScope(
      overrides: deviceOverrides(),
      child: AuraApp(version: package.version),
    ),
  );
}

/// Root of the application.
class AuraApp extends ConsumerStatefulWidget {
  /// Creates the application root.
  const AuraApp({required this.version, super.key});

  /// The build the settings screen reports.
  final String version;

  @override
  ConsumerState<AuraApp> createState() => _AuraAppState();
}

class _AuraAppState extends ConsumerState<AuraApp> {
  late final GoRouter _router = auraRouter(version: widget.version);
  String? _language;

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  /// Keeps `intl` and the API's `lang` in step with the locale `Localizations`
  /// actually resolved.
  ///
  /// The provider is written after the frame rather than inside it: writing to
  /// one while the tree is building is what Riverpod exists to stop.
  void _adopt(Locale locale) {
    AuraLocales.adopt(locale);
    final tag = locale.languageCode;
    if (tag == _language) return;
    _language = tag;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(languageProvider.notifier).tag = tag;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      onGenerateTitle: (context) => AuraBrand.name,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      // Runs inside Localizations, so it sees the locale that was actually
      // resolved.
      //
      // The Material is transparency only. Aura's screens paint their own sky
      // and pass a complete style to every Text, but a Text with no Material
      // above it inherits the framework's debug style, which draws a yellow
      // double underline under every string in the app.
      builder: (context, child) {
        _adopt(Localizations.localeOf(context));
        return Material(type: MaterialType.transparency, child: child);
      },
      routerConfig: _router,
    );
  }
}
