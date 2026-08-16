import 'package:cloud_functions/cloud_functions.dart';

import '../domain/purge_mode.dart';

/// Callable client for trusted server purge in europe-west2.
class PurgeClient {
  PurgeClient(this._functions);

  /// Must match Functions region (Firestore location).
  static const String region = 'europe-west2';

  static const String callableName = 'purgeUserData';

  final FirebaseFunctions _functions;

  factory PurgeClient.forRegion([FirebaseFunctions? functions]) {
    return PurgeClient(
      functions ?? FirebaseFunctions.instanceFor(region: region),
    );
  }

  /// Invokes purgeUserData. Never sends uid/path — backend uses auth.uid.
  Future<void> purge(PurgeMode mode) async {
    final HttpsCallable callable = _functions.httpsCallable(callableName);

    try {
      final HttpsCallableResult<dynamic> result = await callable.call(
        <String, dynamic>{'mode': mode.wireValue},
      );
      final Object? data = result.data;
      if (data is Map && data['ok'] == true) {
        return;
      }
      throw const PurgeException(PurgeFailureCode.purgeFailed);
    } on FirebaseFunctionsException catch (error) {
      throw PurgeException(_mapCode(error), message: error.message);
    }
  }

  PurgeFailureCode _mapCode(FirebaseFunctionsException error) {
    final String message = error.message ?? '';
    if (message.contains('RECENT_AUTH_REQUIRED') ||
        error.code == 'failed-precondition') {
      return PurgeFailureCode.recentAuthRequired;
    }
    if (message.contains('UNAUTHENTICATED') ||
        error.code == 'unauthenticated') {
      return PurgeFailureCode.unauthenticated;
    }
    if (message.contains('PURGE_RETRY_REQUIRED') ||
        error.code == 'unavailable') {
      return PurgeFailureCode.purgeRetryRequired;
    }
    return PurgeFailureCode.purgeFailed;
  }
}
