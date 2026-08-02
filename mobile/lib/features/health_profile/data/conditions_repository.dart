import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/medical_condition.dart';

/// Reads and writes the user's medical conditions.
///
/// The whole list lives in one document: it is small and bounded, and a person's
/// conditions are always read together, so a single document keeps reads and
/// writes atomic without needing a subcollection.
class ConditionsRepository {
  ConditionsRepository(this._firestore);

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _conditionsDocument(String uid) =>
      _firestore
          .collection('users')
          .doc(uid)
          .collection('health')
          .doc('conditions');

  Stream<ConditionRecord> watch(String uid) {
    return _conditionsDocument(uid).snapshots().map((snapshot) {
      final Map<String, dynamic>? data = snapshot.data();

      if (!snapshot.exists || data == null) return ConditionRecord.empty;

      return ConditionRecord.fromMap(data);
    });
  }

  Future<void> save(String uid, ConditionRecord record) {
    return _conditionsDocument(uid).set(<String, dynamic>{
      'items': record.conditions
          .map((UserCondition condition) => condition.toMap())
          .toList(),
      'noKnownConditions': record.noKnownConditions,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
