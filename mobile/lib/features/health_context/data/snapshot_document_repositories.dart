import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/dietary_profile.dart';
import '../domain/health_context_paths.dart';
import '../domain/lifestyle_context.dart';

class DietaryProfileRepository {
  DietaryProfileRepository(this._firestore);

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _doc(String uid) => _firestore
      .collection('users')
      .doc(uid)
      .collection('health')
      .doc(HealthContextPaths.dietaryProfileDoc);

  Stream<DietaryProfile> watch(String uid) {
    return _doc(uid).snapshots().map((
      DocumentSnapshot<Map<String, dynamic>> snap,
    ) {
      if (!snap.exists || snap.data() == null) return DietaryProfile.empty;
      return DietaryProfile.fromMap(snap.data());
    });
  }

  Future<void> save(String uid, DietaryProfile profile, {DateTime? now}) async {
    final DateTime clock = (now ?? DateTime.now()).toUtc();
    final DocumentSnapshot<Map<String, dynamic>> snap = await _doc(uid).get();
    final DateTime? previous = DietaryProfile.fromMap(snap.data()).recordedAt;
    return _doc(uid).set(
      profile.stamped(now: clock, previousRecordedAt: previous).toMap(),
      SetOptions(merge: true),
    );
  }
}

class LifestyleContextRepository {
  LifestyleContextRepository(this._firestore);

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _doc(String uid) => _firestore
      .collection('users')
      .doc(uid)
      .collection('health')
      .doc(HealthContextPaths.lifestyleDoc);

  Stream<LifestyleContext> watch(String uid) {
    return _doc(uid).snapshots().map((
      DocumentSnapshot<Map<String, dynamic>> snap,
    ) {
      if (!snap.exists || snap.data() == null) return LifestyleContext.empty;
      return LifestyleContext.fromMap(snap.data());
    });
  }

  Future<void> save(
    String uid,
    LifestyleContext context, {
    DateTime? now,
  }) async {
    final DateTime clock = (now ?? DateTime.now()).toUtc();
    final DocumentSnapshot<Map<String, dynamic>> snap = await _doc(uid).get();
    final DateTime? previous = LifestyleContext.fromMap(snap.data()).recordedAt;
    return _doc(uid).set(
      context.stamped(now: clock, previousRecordedAt: previous).toMap(),
      SetOptions(merge: true),
    );
  }
}
