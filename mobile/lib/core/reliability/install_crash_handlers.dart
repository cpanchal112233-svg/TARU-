import 'package:flutter/foundation.dart';

import 'crash_category.dart';
import 'crash_reporter.dart';

/// Installs Flutter and platform error hooks.
///
/// Preserves existing presentation / previous handlers. Does not add a Zone.
///
/// PlatformDispatcher contract:
/// - true = error handled
/// - false = invoke platform fallback
///
/// When diagnostics are OFF and no previous handler exists, return false so
/// TARU does not silently consume an unhandled async error. When diagnostics
/// are ON and the sync reporting path accepts the call, return true (Crashlytics
/// handled path). Async upload completion is not claimed by the boolean.
void installCrashHandlers(CrashReporter reporter) {
  final FlutterExceptionHandler? previousFlutter = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    if (previousFlutter != null) {
      previousFlutter(details);
    } else {
      FlutterError.presentError(details);
    }
    reporter.recordUnexpected(
      category: CrashCategory.framework,
      stack: details.stack,
      fatal: true,
    );
  };

  final bool Function(Object error, StackTrace stack)? previousPlatform =
      PlatformDispatcher.instance.onError;
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    bool diagnosticsHandled = false;
    try {
      if (reporter.sessionReportingEnabled) {
        diagnosticsHandled = reporter.recordUnexpected(
          category: CrashCategory.isolate,
          stack: stack,
          fatal: true,
        );
      }
    } catch (_) {
      diagnosticsHandled = false;
    }

    if (previousPlatform != null) {
      return previousPlatform(error, stack);
    }

    // No previous handler:
    // OFF / sync reporter failure → platform fallback (false)
    // ON and sync report accepted → handled (true)
    return diagnosticsHandled;
  };
}
