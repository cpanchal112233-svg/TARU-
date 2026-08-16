import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// Minimal Crashlytics surface. Intentionally omits sendUnsentReports,
/// setUserIdentifier, log, and custom keys.
abstract class CrashlyticsBackend {
  Future<void> setCollectionEnabled(bool enabled);

  Future<void> deleteUnsentReports();

  Future<void> recordSanitized({
    required String remoteException,
    StackTrace? stack,
    required bool fatal,
  });
}

class NoOpCrashlyticsBackend implements CrashlyticsBackend {
  const NoOpCrashlyticsBackend();

  @override
  Future<void> setCollectionEnabled(bool enabled) async {}

  @override
  Future<void> deleteUnsentReports() async {}

  @override
  Future<void> recordSanitized({
    required String remoteException,
    StackTrace? stack,
    required bool fatal,
  }) async {}
}

class FirebaseCrashlyticsBackend implements CrashlyticsBackend {
  FirebaseCrashlyticsBackend({this._crashlytics});

  final FirebaseCrashlytics? _crashlytics;

  FirebaseCrashlytics get _sdk => _crashlytics ?? FirebaseCrashlytics.instance;

  @override
  Future<void> setCollectionEnabled(bool enabled) {
    return _sdk.setCrashlyticsCollectionEnabled(enabled);
  }

  @override
  Future<void> deleteUnsentReports() {
    return _sdk.deleteUnsentReports();
  }

  @override
  Future<void> recordSanitized({
    required String remoteException,
    StackTrace? stack,
    required bool fatal,
  }) {
    return _sdk.recordError(
      remoteException,
      stack,
      printDetails: false,
      fatal: fatal,
    );
  }
}
