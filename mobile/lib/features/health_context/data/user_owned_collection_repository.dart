import 'package:cloud_firestore/cloud_firestore.dart';

/// Typed collection under `users/{uid}/{collectionName}/{autoId}`.
class UserOwnedCollectionRepository<T> {
  UserOwnedCollectionRepository({
    required this.firestore,
    required this.collectionName,
    required this.fromMap,
    required this.toMap,
  });

  final FirebaseFirestore firestore;
  final String collectionName;
  final T? Function(String id, Map<String, dynamic> data) fromMap;
  final Map<String, dynamic> Function(T value) toMap;

  CollectionReference<Map<String, dynamic>> _collection(String uid) =>
      firestore.collection('users').doc(uid).collection(collectionName);

  String newId(String uid) => _collection(uid).doc().id;

  Stream<List<T>> watch(String uid) {
    return _collection(uid).snapshots().map((
      QuerySnapshot<Map<String, dynamic>> snap,
    ) {
      final List<T> items = <T>[];
      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in snap.docs) {
        final T? parsed = fromMap(doc.id, doc.data());
        if (parsed != null) items.add(parsed);
      }
      return items;
    });
  }

  Future<void> upsert(String uid, String id, T value) {
    return _collection(uid).doc(id).set(toMap(value));
  }

  Future<void> delete(String uid, String id) {
    return _collection(uid).doc(id).delete();
  }
}
