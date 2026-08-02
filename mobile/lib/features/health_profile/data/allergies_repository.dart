import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/allergy.dart';

class AllergiesRepository {
  AllergiesRepository(this._firestore);

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _allergiesDocument(String uid) =>
      _firestore
          .collection('users')
          .doc(uid)
          .collection('health')
          .doc('allergies');

  Stream<AllergyRecord> watch(String uid) {
    return _allergiesDocument(uid).snapshots().map((snapshot) {
      final Map<String, dynamic>? data = snapshot.data();

      if (!snapshot.exists || data == null) return AllergyRecord.empty;

      return AllergyRecord.fromMap(data);
    });
  }

  Future<void> save(String uid, AllergyRecord record) {
    return _allergiesDocument(uid).set(<String, dynamic>{
      'items': record.allergies
          .map((UserAllergy allergy) => allergy.toMap())
          .toList(),
      'noKnownAllergies': record.noKnownAllergies,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
