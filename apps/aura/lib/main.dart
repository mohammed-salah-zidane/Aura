import 'package:aura_design/aura_design.dart';
import 'package:aura_feature_onboarding/aura_feature_onboarding.dart';
import 'package:aura_l10n/aura_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  runApp(const ProviderScope(child: AuraApp()));
}

/// Root of the application.
class AuraApp extends StatelessWidget {
  /// Creates the application root.
  const AuraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AuraBrand.name,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      // Runs inside Localizations, so it sees the locale that was actually
      // resolved and keeps intl's own formatters in step with it.
      //
      // The Material is transparency only. Aura's screens paint their own sky
      // and pass a complete style to every Text, but a Text with no Material
      // above it inherits the framework's debug style, which draws a yellow
      // double underline under every string in the app.
      builder: (context, child) {
        AuraLocales.adopt(Localizations.localeOf(context));
        return Material(type: MaterialType.transparency, child: child);
      },
      home: const SplashScreen(),
    );
  }
}
