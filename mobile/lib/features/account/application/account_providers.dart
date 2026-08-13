import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/firebase_providers.dart';
import '../../auth/application/auth_providers.dart';
import '../data/account_root_repository.dart';
import '../domain/account_integrity.dart';
import '../domain/pending_signup_identity.dart';

final pendingSignupIdentityProvider = Provider<PendingSignupIdentity>(
  (Ref ref) => PendingSignupIdentity(),
);

final accountRootRepositoryProvider = Provider<AccountRootRepository>((
  Ref ref,
) {
  return AccountRootRepository(
    firestore: ref.watch(firestoreProvider),
    currentUid: () => ref.read(authStateChangesProvider).value?.uid,
  );
});

/// One listener per signed-in session. Cached reads are not treated as "missing".
final accountIntegrityProvider = StreamProvider<AccountIntegrity>((Ref ref) {
  final AsyncValue<User?> auth = ref.watch(authStateChangesProvider);

  if (auth.isLoading) {
    return Stream<AccountIntegrity>.value(AccountIntegrity.checking);
  }

  if (auth.hasError) {
    return Stream<AccountIntegrity>.value(
      AccountIntegrity.temporarilyUnavailable,
    );
  }

  final User? user = auth.value;
  if (user == null) {
    return Stream<AccountIntegrity>.value(AccountIntegrity.signedOut);
  }

  final Stream<DocumentSnapshot<Map<String, dynamic>>> snapshots = ref
      .watch(firestoreProvider)
      .collection('users')
      .doc(user.uid)
      .snapshots(includeMetadataChanges: true);

  return Stream<AccountIntegrity>.multi((
    StreamController<AccountIntegrity> controller,
  ) {
    final StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>
    subscription = snapshots.listen(
      (DocumentSnapshot<Map<String, dynamic>> snap) {
        controller.add(integrityFromSnapshot(snap));
      },
      onError: (Object _, StackTrace _) {
        controller.add(AccountIntegrity.temporarilyUnavailable);
      },
    );
    controller.onCancel = subscription.cancel;
  });
});

AccountIntegrity integrityFromSnapshot(
  DocumentSnapshot<Map<String, dynamic>> snap,
) {
  return interpretAccountRoot(
    exists: snap.exists,
    isFromCache: snap.metadata.isFromCache,
    deletionInProgress: snap.data()?['deletionInProgress'],
  );
}

/// Thrown when Auth succeeded but the identity root could not be written.
class AccountRootSetupException implements Exception {
  const AccountRootSetupException();
}
