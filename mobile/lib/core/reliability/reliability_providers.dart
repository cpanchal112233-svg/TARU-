import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'crash_diagnostics_store.dart';
import 'crash_reporter.dart';
import 'crashlytics_backend.dart';

final crashReporterProvider = Provider<CrashReporter>((Ref ref) {
  return CrashReporter(
    store: SharedPreferencesCrashDiagnosticsStore(),
    backend: kReleaseMode
        ? FirebaseCrashlyticsBackend()
        : const NoOpCrashlyticsBackend(),
    allowRemoteReporting: kReleaseMode,
  );
});

class CrashDiagnosticsController extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final CrashReporter reporter = ref.watch(crashReporterProvider);
    await reporter.applyStartup();
    return reporter.desiredEnabled;
  }

  Future<void> setEnabled(bool enabled) async {
    await ref.read(crashReporterProvider).setDesiredEnabled(enabled);
    state = AsyncValue<bool>.data(enabled);
  }
}

final crashDiagnosticsControllerProvider =
    AsyncNotifierProvider<CrashDiagnosticsController, bool>(
      CrashDiagnosticsController.new,
    );
