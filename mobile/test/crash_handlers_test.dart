import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/reliability/crash_reporter.dart';
import 'package:mobile/core/reliability/crashlytics_backend.dart';
import 'package:mobile/core/reliability/install_crash_handlers.dart';

import 'crash_consent_test.dart';

class _SyncThrowBackend implements CrashlyticsBackend {
  @override
  Future<void> setCollectionEnabled(bool enabled) async {}

  @override
  Future<void> deleteUnsentReports() async {}

  @override
  Future<void> recordSanitized({
    required String remoteException,
    StackTrace? stack,
    required bool fatal,
  }) {
    // Synchronous throw before a Future is returned.
    throw StateError('sync reporter failure');
  }
}

void main() {
  late FlutterExceptionHandler? previousFlutter;
  late bool Function(Object error, StackTrace stack)? previousPlatform;

  setUp(() {
    previousFlutter = FlutterError.onError;
    previousPlatform = PlatformDispatcher.instance.onError;
  });

  tearDown(() {
    FlutterError.onError = previousFlutter;
    PlatformDispatcher.instance.onError = previousPlatform;
  });

  test('FlutterError preserves presentation and reports only when enabled', () async {
    int presented = 0;
    FlutterError.onError = (FlutterErrorDetails details) {
      presented += 1;
    };

    final MemoryCrashDiagnosticsStore store = MemoryCrashDiagnosticsStore();
    final RecordingCrashlyticsBackend backend = RecordingCrashlyticsBackend();
    final CrashReporter reporter = CrashReporter(
      store: store,
      backend: backend,
      allowRemoteReporting: true,
    );
    await reporter.applyStartup();
    installCrashHandlers(reporter);

    FlutterError.reportError(
      FlutterErrorDetails(
        exception: StateError('REPORT_NAME_DO_NOT_SEND'),
        stack: StackTrace.current,
      ),
    );
    expect(presented, 1);
    expect(backend.recorded, isEmpty);

    await reporter.setDesiredEnabled(true);
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: StateError('WEIGHT_123_DO_NOT_SEND'),
        stack: StackTrace.current,
      ),
    );
    expect(presented, 2);
    expect(backend.recorded, <String>['UnexpectedFailure(framework)']);
    expect(backend.recorded.single, isNot(contains('WEIGHT_123_DO_NOT_SEND')));
  });

  test('A previous handler true → result true', () async {
    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) =>
        true;
    final MemoryCrashDiagnosticsStore store = MemoryCrashDiagnosticsStore()
      ..value = true;
    final RecordingCrashlyticsBackend backend = RecordingCrashlyticsBackend();
    final CrashReporter reporter = CrashReporter(
      store: store,
      backend: backend,
      allowRemoteReporting: true,
    );
    await reporter.applyStartup();
    installCrashHandlers(reporter);

    expect(
      PlatformDispatcher.instance.onError!(
        Exception('EMAIL_DO_NOT_SEND@example.test'),
        StackTrace.current,
      ),
      isTrue,
    );
  });

  test('B previous handler false → result false', () async {
    bool previousCalled = false;
    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      previousCalled = true;
      return false;
    };
    final MemoryCrashDiagnosticsStore store = MemoryCrashDiagnosticsStore()
      ..value = true;
    final RecordingCrashlyticsBackend backend = RecordingCrashlyticsBackend();
    final CrashReporter reporter = CrashReporter(
      store: store,
      backend: backend,
      allowRemoteReporting: true,
    );
    await reporter.applyStartup();
    installCrashHandlers(reporter);

    final bool handled = PlatformDispatcher.instance.onError!(
      Exception('EMAIL_DO_NOT_SEND@example.test'),
      StackTrace.current,
    );

    expect(previousCalled, isTrue);
    expect(handled, isFalse);
  });

  test('C no previous + diagnostics OFF → false and reporter not invoked', () async {
    PlatformDispatcher.instance.onError = null;
    final MemoryCrashDiagnosticsStore store = MemoryCrashDiagnosticsStore();
    final RecordingCrashlyticsBackend backend = RecordingCrashlyticsBackend();
    final CrashReporter reporter = CrashReporter(
      store: store,
      backend: backend,
      allowRemoteReporting: true,
    );
    await reporter.applyStartup();
    installCrashHandlers(reporter);

    final bool handled = PlatformDispatcher.instance.onError!(
      Exception('REPORT_NAME_DO_NOT_SEND'),
      StackTrace.current,
    );

    expect(handled, isFalse);
    expect(backend.recorded, isEmpty);
  });

  test('D no previous + diagnostics ON → sanitized report + true', () async {
    PlatformDispatcher.instance.onError = null;
    final MemoryCrashDiagnosticsStore store = MemoryCrashDiagnosticsStore()
      ..value = true;
    final RecordingCrashlyticsBackend backend = RecordingCrashlyticsBackend();
    final CrashReporter reporter = CrashReporter(
      store: store,
      backend: backend,
      allowRemoteReporting: true,
    );
    await reporter.applyStartup();
    installCrashHandlers(reporter);

    final bool handled = PlatformDispatcher.instance.onError!(
      Exception(
        'EMAIL_DO_NOT_SEND@example.test REPORT_NAME_DO_NOT_SEND WEIGHT_123_DO_NOT_SEND',
      ),
      StackTrace.current,
    );

    expect(handled, isTrue);
    expect(backend.recorded, <String>['UnexpectedFailure(isolate)']);
  });

  test('E sync reporter throw → handler does not throw → false', () async {
    PlatformDispatcher.instance.onError = null;
    final MemoryCrashDiagnosticsStore store = MemoryCrashDiagnosticsStore()
      ..value = true;
    final CrashReporter reporter = CrashReporter(
      store: store,
      backend: _SyncThrowBackend(),
      allowRemoteReporting: true,
    );
    await reporter.applyStartup();
    installCrashHandlers(reporter);

    expect(
      () => PlatformDispatcher.instance.onError!(
        Exception('WEIGHT_123_DO_NOT_SEND'),
        StackTrace.current,
      ),
      returnsNormally,
    );
    expect(
      PlatformDispatcher.instance.onError!(
        Exception('WEIGHT_123_DO_NOT_SEND'),
        StackTrace.current,
      ),
      isFalse,
    );
  });

  test('F fake PHI-like markers never reach mocked backend', () async {
    PlatformDispatcher.instance.onError = null;
    final MemoryCrashDiagnosticsStore store = MemoryCrashDiagnosticsStore()
      ..value = true;
    final RecordingCrashlyticsBackend backend = RecordingCrashlyticsBackend();
    final CrashReporter reporter = CrashReporter(
      store: store,
      backend: backend,
      allowRemoteReporting: true,
    );
    await reporter.applyStartup();
    installCrashHandlers(reporter);

    PlatformDispatcher.instance.onError!(
      Exception(
        'EMAIL_DO_NOT_SEND@example.test REPORT_NAME_DO_NOT_SEND WEIGHT_123_DO_NOT_SEND',
      ),
      StackTrace.current,
    );

    expect(backend.recorded, <String>['UnexpectedFailure(isolate)']);
    expect(backend.recorded.single, isNot(contains('EMAIL_DO_NOT_SEND')));
    expect(backend.recorded.single, isNot(contains('REPORT_NAME_DO_NOT_SEND')));
    expect(backend.recorded.single, isNot(contains('WEIGHT_123_DO_NOT_SEND')));
  });
}
