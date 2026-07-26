import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Entry point. Composition happens here and nowhere else.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
  ]);

  runApp(const ProviderScope(child: AuraApp()));
}

/// Root of the application.
class AuraApp extends StatelessWidget {
  /// Creates the application root.
  const AuraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Aura',
      debugShowCheckedModeBanner: false,
      home: SizedBox.shrink(),
    );
  }
}
