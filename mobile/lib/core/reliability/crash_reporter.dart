import 'dart:async';

import 'crash_category.dart';
import 'crash_diagnostics_store.dart';
import 'crashlytics_backend.dart';

/// Opt-in crash diagnostics. Dart reporting follows [sessionReportingEnabled].
///
/// Native Crashlytics collection is configured at startup and when the
/// preference changes. Same-session native disablement is not assumed to be
/// instantaneous; the Dart reporter stops immediately on opt-out.
class CrashReporter {
  CrashReporter({
    required CrashDiagnosticsStore store,
    required CrashlyticsBackend backend,
    required bool allowRemoteReporting,
  }) : _store = store,
       _backend = backend,
       _allowRemoteReporting = allowRemoteReporting;

  final CrashDiagnosticsStore _store;
  final CrashlyticsBackend _backend;
  final bool _allowRemoteReporting;

  bool _desiredEnabled = false;

  /// What the user selected. Default false.
  bool get desiredEnabled => _desiredEnabled;

  /// Whether this process may send sanitized reports.
  bool get sessionReportingEnabled =>
      _desiredEnabled && _allowRemoteReporting;

  Future<void> applyStartup() async {
    try {
      _desiredEnabled = await _store.readEnabled();
    } catch (_) {
      _desiredEnabled = false;
    }

    await _configureNative();
    if (!_desiredEnabled) {
      await _deleteUnsentQuietly();
    }
  }

  Future<void> setDesiredEnabled(bool enabled) async {
    try {
      await _store.writeEnabled(enabled);
    } catch (_) {}
    _desiredEnabled = enabled;
    await _configureNative();
    if (!enabled) {
      await _deleteUnsentQuietly();
    }
  }

  /// Unexpected software failure only. Original exception text is never sent.
  ///
  /// Returns true when session reporting accepted the sync call path.
  /// Returns false when disabled or a synchronous reporter failure occurred.
  /// Async upload success is not claimed by this return value.
  bool recordUnexpected({
    required CrashCategory category,
    Object? error,
    StackTrace? stack,
    bool fatal = true,
  }) {
    if (!sessionReportingEnabled) return false;
    // [error] is intentionally discarded and never forwarded.
    try {
      _backend
          .recordSanitized(
            remoteException: 'UnexpectedFailure(${category.code})',
            stack: stack,
            fatal: fatal,
          )
          .ignore();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _configureNative() async {
    try {
      await _backend.setCollectionEnabled(
        _desiredEnabled && _allowRemoteReporting,
      );
    } catch (_) {}
  }

  Future<void> _deleteUnsentQuietly() async {
    try {
      await _backend.deleteUnsentReports();
    } catch (_) {}
  }
}
