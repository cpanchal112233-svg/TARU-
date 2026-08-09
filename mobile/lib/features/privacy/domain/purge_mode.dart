enum PurgeMode {
  health('health'),
  account('account');

  const PurgeMode(this.wireValue);

  final String wireValue;
}

/// Stable client-facing purge failures.
enum PurgeFailureCode {
  unauthenticated,
  recentAuthRequired,
  purgeFailed,
  purgeRetryRequired,
  unknown,
}

class PurgeException implements Exception {
  const PurgeException(this.code, {this.message});

  final PurgeFailureCode code;
  final String? message;

  @override
  String toString() => message ?? code.name;
}
