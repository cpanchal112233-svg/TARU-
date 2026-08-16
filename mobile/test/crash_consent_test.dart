import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/reliability/crash_category.dart';
import 'package:mobile/core/reliability/crash_diagnostics_store.dart';
import 'package:mobile/core/reliability/crash_reporter.dart';
import 'package:mobile/core/reliability/crashlytics_backend.dart';
import 'package:mobile/core/reliability/reliability_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MemoryCrashDiagnosticsStore implements CrashDiagnosticsStore {
  bool value = false;

  @override
  Future<bool> readEnabled() async => value;

  @override
  Future<void> writeEnabled(bool enabled) async {
    value = enabled;
  }
}

class RecordingCrashlyticsBackend implements CrashlyticsBackend {
  bool? collectionEnabled;
  int deleteUnsentCount = 0;
  int sendUnsentCount = 0;
  final List<String> recorded = <String>[];
  bool throwOnRecord = false;
  bool throwOnDelete = false;
  bool throwOnCollection = false;

  @override
  Future<void> setCollectionEnabled(bool enabled) async {
    if (throwOnCollection) {
      throw StateError('collection failed');
    }
    collectionEnabled = enabled;
  }

  @override
  Future<void> deleteUnsentReports() async {
    if (throwOnDelete) {
      throw StateError('delete failed');
    }
    deleteUnsentCount += 1;
  }

  @override
  Future<void> recordSanitized({
    required String remoteException,
    StackTrace? stack,
    required bool fatal,
  }) async {
    if (throwOnRecord) {
      throw StateError('record failed');
    }
    recorded.add(remoteException);
  }
}

void main() {
  test('default preference is false', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SharedPreferencesCrashDiagnosticsStore store =
        SharedPreferencesCrashDiagnosticsStore();
    expect(await store.readEnabled(), isFalse);
  });

  test('fresh-session reporter is disabled', () async {
    final MemoryCrashDiagnosticsStore store = MemoryCrashDiagnosticsStore();
    final RecordingCrashlyticsBackend backend = RecordingCrashlyticsBackend();
    final CrashReporter reporter = CrashReporter(
      store: store,
      backend: backend,
      allowRemoteReporting: true,
    );

    await reporter.applyStartup();

    expect(reporter.desiredEnabled, isFalse);
    expect(reporter.sessionReportingEnabled, isFalse);
    reporter.recordUnexpected(
      category: CrashCategory.unknown,
      error: 'WEIGHT_123_DO_NOT_SEND',
      stack: StackTrace.current,
    );
    expect(backend.recorded, isEmpty);
    expect(backend.collectionEnabled, isFalse);
  });

  test('enable preference persists', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SharedPreferencesCrashDiagnosticsStore store =
        SharedPreferencesCrashDiagnosticsStore();
    final RecordingCrashlyticsBackend backend = RecordingCrashlyticsBackend();
    final CrashReporter reporter = CrashReporter(
      store: store,
      backend: backend,
      allowRemoteReporting: true,
    );

    await reporter.setDesiredEnabled(true);

    expect(await store.readEnabled(), isTrue);
    expect(reporter.desiredEnabled, isTrue);
    expect(reporter.sessionReportingEnabled, isTrue);
    expect(backend.collectionEnabled, isTrue);
  });

  test(
    'disable preference persists and Dart reporter stops immediately',
    () async {
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
        category: CrashCategory.unknown,
        stack: StackTrace.current,
      );
      expect(backend.recorded, isNotEmpty);

      await reporter.setDesiredEnabled(false);

      expect(store.value, isFalse);
      expect(reporter.sessionReportingEnabled, isFalse);
      backend.recorded.clear();
      reporter.recordUnexpected(
        category: CrashCategory.unknown,
        stack: StackTrace.current,
      );
      expect(backend.recorded, isEmpty);
      expect(backend.deleteUnsentCount, greaterThan(0));
    },
  );

  test('startup while false requests deleteUnsentReports', () async {
    final MemoryCrashDiagnosticsStore store = MemoryCrashDiagnosticsStore();
    final RecordingCrashlyticsBackend backend = RecordingCrashlyticsBackend();
    final CrashReporter reporter = CrashReporter(
      store: store,
      backend: backend,
      allowRemoteReporting: true,
    );

    await reporter.applyStartup();

    expect(backend.deleteUnsentCount, 1);
    expect(backend.sendUnsentCount, 0);
  });

  test('opt-in never calls sendUnsentReports', () async {
    final MemoryCrashDiagnosticsStore store = MemoryCrashDiagnosticsStore();
    final RecordingCrashlyticsBackend backend = RecordingCrashlyticsBackend();
    final CrashReporter reporter = CrashReporter(
      store: store,
      backend: backend,
      allowRemoteReporting: true,
    );

    await reporter.setDesiredEnabled(true);

    expect(backend.sendUnsentCount, 0);
  });

  test('reporter failure never breaks TARU', () async {
    final MemoryCrashDiagnosticsStore store = MemoryCrashDiagnosticsStore()
      ..value = true;
    final RecordingCrashlyticsBackend backend = RecordingCrashlyticsBackend()
      ..throwOnRecord = true
      ..throwOnDelete = true
      ..throwOnCollection = true;
    final CrashReporter reporter = CrashReporter(
      store: store,
      backend: backend,
      allowRemoteReporting: true,
    );

    await expectLater(reporter.applyStartup(), completes);
    expect(
      () => reporter.recordUnexpected(
        category: CrashCategory.framework,
        error: StateError('boom'),
        stack: StackTrace.current,
      ),
      returnsNormally,
    );
    await expectLater(reporter.setDesiredEnabled(false), completes);
  });

  test('test/debug remote reporting is off by default', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);

    final CrashReporter reporter = container.read(crashReporterProvider);
    await reporter.applyStartup();
    await reporter.setDesiredEnabled(true);

    expect(reporter.desiredEnabled, isTrue);
    expect(reporter.sessionReportingEnabled, isFalse);
  });
}
