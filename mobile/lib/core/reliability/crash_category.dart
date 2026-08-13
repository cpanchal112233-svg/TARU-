/// Allowlisted operational categories for sanitized crash reports.
enum CrashCategory {
  framework,
  isolate,
  unknown;

  String get code {
    switch (this) {
      case CrashCategory.framework:
        return 'framework';
      case CrashCategory.isolate:
        return 'isolate';
      case CrashCategory.unknown:
        return 'unknown';
    }
  }
}
