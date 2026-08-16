import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/habit.dart';

/// Persists which lifestyle habits appear on the Routine checklist.
///
/// Stored at `users/{uid}/routine/habitPreferences`. A missing document means
/// every catalog habit is enabled.
///
/// Preference writes never touch `habitLogs`. Disabling a habit only changes
/// the active checklist and progress denominators — historical completions
/// stay intact and reappear if the habit is turned back on.
class HabitPreferencesRepository {
  HabitPreferencesRepository(this._firestore);

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _doc(String uid) => _firestore
      .collection('users')
      .doc(uid)
      .collection('routine')
      .doc('habitPreferences');

  Stream<HabitPreferences> watch(String uid) {
    return _doc(uid).snapshots().map((
      DocumentSnapshot<Map<String, dynamic>> snap,
    ) {
      if (!snap.exists) return HabitPreferences.allEnabled;
      return HabitPreferences.fromMap(snap.data());
    });
  }

  Future<void> save(String uid, HabitPreferences preferences) {
    return _doc(uid).set(<String, dynamic>{
      ...preferences.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
