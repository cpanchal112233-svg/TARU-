import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../domain/account_integrity.dart';

/// Minimal identity-root create/repair. Never writes health data or guards.
class AccountRootRepository {
  AccountRootRepository({
    required FirebaseFirestore firestore,
    String? Function()? currentUid,
  }) : _firestore = firestore,
       _currentUid =
           currentUid ?? (() => FirebaseAuth.instance.currentUser?.uid);

  final FirebaseFirestore _firestore;
  final String? Function() _currentUid;

  /// Creates `users/{currentUid}` with identity fields only if it is missing.
  ///
  /// Does not overwrite an existing root (including deletion guards).
  Future<AccountRootCreateResult> createIdentityRoot({
    required String name,
    required String email,
  }) async {
    final String? uid = _currentUid();
    if (uid == null || uid.isEmpty) {
      throw StateError('Cannot create an account root while signed out.');
    }

    final DocumentReference<Map<String, dynamic>> doc = _firestore
        .collection('users')
        .doc(uid);

    final DocumentSnapshot<Map<String, dynamic>> snap = await doc.get();
    if (snap.exists) {
      return AccountRootCreateResult.alreadyExists;
    }

    await doc.set(<String, dynamic>{
      'name': name.trim(),
      'email': email.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    return AccountRootCreateResult.created;
  }
}
