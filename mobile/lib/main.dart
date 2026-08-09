import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'features/privacy/data/local_privacy_cleanup.dart';
import 'features/startup/presentation/pages/auth_gate.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await cleanupStaleTaruTempsOnLaunch();

  runApp(const ProviderScope(child: TaruApp()));
}

class TaruApp extends StatelessWidget {
  const TaruApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TARU',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AuthGate(),
    );
  }
}
