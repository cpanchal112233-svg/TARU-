import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/health_profile.dart';

/// Reads and writes the user's health basics.
///
/// Medical data lives in its own `health` subcollection rather than on the
/// account document, so security rules and future exports can treat it
/// separately from ordinary account fields like name and email.
class HealthProfileRepository {
  HealthProfileRepository(this._firestore);

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _profileDocument(String uid) =>
      _firestore
          .collection('users')
          .doc(uid)
          .collection('health')
          .doc('profile');

  Stream<HealthProfile> watch(String uid) {
    return _profileDocument(uid).snapshots().map((snapshot) {
      final Map<String, dynamic>? data = snapshot.data();

      if (!snapshot.exists || data == null) return HealthProfile.empty;

      return HealthProfile.fromMap(data);
    });
  }

  /// Merges so partially answered sections never wipe earlier answers.
  Future<void> save(String uid, HealthProfile profile) {
    return _profileDocument(uid).set(profile.toMap(), SetOptions(merge: true));
  }
}
