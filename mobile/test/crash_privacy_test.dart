import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/reliability/crash_category.dart';
import 'package:mobile/core/reliability/crash_reporter.dart';

import 'crash_consent_test.dart';

void main() {
  const String reportName = 'REPORT_NAME_DO_NOT_SEND';
  const String weight = 'WEIGHT_123_DO_NOT_SEND';
  const String email = 'USER_EMAIL_DO_NOT_SEND';

  test('sanitized reporting does not propagate original exception text', () async {
    final MemoryCrashDiagnosticsStore store = MemoryCrashDiagnosticsStore()
      ..value = true;
    final RecordingCrashlyticsBackend backend = RecordingCrashlyticsBackend();
    final CrashReporter reporter = CrashReporter(
      store: store,
      backend: backend,
      allowRemoteReporting: true,
    );
    await reporter.applyStartup();

    reporter.recordUnexpected(
      category: CrashCategory.framework,
      error: StateError('$reportName $weight $email'),
      stack: StackTrace.current,
    );

    expect(backend.recorded, <String>['UnexpectedFailure(framework)']);
    expect(backend.recorded.single, isNot(contains(reportName)));
    expect(backend.recorded.single, isNot(contains(weight)));
    expect(backend.recorded.single, isNot(contains(email)));
  });

  test('allowlisted generic category only', () async {
    final MemoryCrashDiagnosticsStore store = MemoryCrashDiagnosticsStore()
      ..value = true;
    final RecordingCrashlyticsBackend backend = RecordingCrashlyticsBackend();
    final CrashReporter reporter = CrashReporter(
      store: store,
      backend: backend,
      allowRemoteReporting: true,
    );
    await reporter.applyStartup();

    reporter.recordUnexpected(
      category: CrashCategory.isolate,
      error: Exception('USER_EMAIL_DO_NOT_SEND'),
      stack: StackTrace.current,
    );

    expect(backend.recorded, <String>['UnexpectedFailure(isolate)']);
  });

  test('CrashlyticsBackend has no setUserIdentifier or log API', () {
    expect(
      RecordingCrashlyticsBackend().toString(),
      isNot(contains('setUserIdentifier')),
    );
    const List<String> members = <String>[
      'setCollectionEnabled',
      'deleteUnsentReports',
      'recordSanitized',
    ];
    expect(members, isNot(contains('setUserIdentifier')));
    expect(members, isNot(contains('log')));
    expect(members, isNot(contains('sendUnsentReports')));
  });
}
