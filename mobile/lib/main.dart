import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/reliability/crash_diagnostics_store.dart';
import 'core/reliability/crash_reporter.dart';
import 'core/reliability/crashlytics_backend.dart';
import 'core/reliability/install_crash_handlers.dart';
import 'core/reliability/reliability_providers.dart';
import 'core/theme/app_theme.dart';
import 'features/privacy/data/local_privacy_cleanup.dart';
import 'features/startup/presentation/pages/auth_gate.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final CrashReporter crashReporter = CrashReporter(
    store: SharedPreferencesCrashDiagnosticsStore(),
    backend: FirebaseCrashlyticsBackend(),
    allowRemoteReporting: kReleaseMode,
  );
  installCrashHandlers(crashReporter);
  await crashReporter.applyStartup();
  await cleanupStaleTaruTempsOnLaunch();

  runApp(
    ProviderScope(
      overrides: [crashReporterProvider.overrideWithValue(crashReporter)],
      child: const TaruApp(),
    ),
  );
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
