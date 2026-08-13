import '../../privacy/domain/purge_mode.dart';

/// Signed-in account-root integrity. Fail closed: never assume a missing root
/// from a failed or cached-only read.
enum AccountIntegrity {
  signedOut,
  checking,
  ready,
  deletionHealthInProgress,
  deletionAccountInProgress,
  missingRoot,
  temporarilyUnavailable,
}

enum AccountRootCreateResult { created, alreadyExists }

/// Interprets a users/{uid} snapshot without creating or mutating data.
AccountIntegrity interpretAccountRoot({
  required bool exists,
  required bool isFromCache,
  Object? deletionInProgress,
}) {
  if (!exists) {
    return isFromCache
        ? AccountIntegrity.temporarilyUnavailable
        : AccountIntegrity.missingRoot;
  }

  if (deletionInProgress == PurgeMode.health.wireValue) {
    return AccountIntegrity.deletionHealthInProgress;
  }
  if (deletionInProgress == PurgeMode.account.wireValue) {
    return AccountIntegrity.deletionAccountInProgress;
  }
  return AccountIntegrity.ready;
}
