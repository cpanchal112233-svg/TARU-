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

  static const String _itemsField = 'items';

  DocumentReference<Map<String, dynamic>> _conditionsDocument(String uid) =>
      _firestore
          .collection('users')
          .doc(uid)
          .collection('health')
          .doc('conditions');

  Stream<List<UserCondition>> watch(String uid) {
    return _conditionsDocument(uid).snapshots().map((snapshot) {
      final Object? items = snapshot.data()?[_itemsField];

      if (items is! List) return const <UserCondition>[];

      return items
          .whereType<Map<String, dynamic>>()
          .map(UserCondition.fromMap)
          .whereType<UserCondition>()
          .toList();
    });
  }

  Future<void> save(String uid, List<UserCondition> conditions) {
    return _conditionsDocument(uid).set(<String, dynamic>{
      _itemsField: conditions
          .map((UserCondition condition) => condition.toMap())
          .toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
