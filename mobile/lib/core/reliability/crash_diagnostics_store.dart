import 'package:shared_preferences/shared_preferences.dart';

/// Device-local crash-diagnostics preference. Not health data. Not synced.
abstract class CrashDiagnosticsStore {
  Future<bool> readEnabled();

  Future<void> writeEnabled(bool enabled);
}

class SharedPreferencesCrashDiagnosticsStore implements CrashDiagnosticsStore {
  SharedPreferencesCrashDiagnosticsStore();

  static const String key = 'crash_diagnostics_enabled';

  @override
  Future<bool> readEnabled() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key) ?? false;
  }

  @override
  Future<void> writeEnabled(bool enabled) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, enabled);
  }
}
