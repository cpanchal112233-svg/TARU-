import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/dose_schedule.dart';

/// Stores which doses were taken, one document per day.
///
/// Document IDs are `yyyy-MM-dd`, so a plain ID sort is also a date sort and
/// the last week can be read without a composite index.
class DoseLogRepository {
  DoseLogRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _logs(String uid) =>
      _firestore.collection('users').doc(uid).collection('doseLogs');

  Stream<DailyDoseLog> watchDay(String uid, String dateKey) {
    return _logs(uid).doc(dateKey).snapshots().map((snapshot) {
      final Map<String, dynamic>? data = snapshot.data();

      if (!snapshot.exists || data == null) {
        return DailyDoseLog(dateKey: dateKey);
      }

      return DailyDoseLog.fromMap(dateKey, data);
    });
  }

  /// Reads the window forwards from a start date rather than taking the newest
  /// documents in reverse, because a descending sort on document ID needs a
  /// custom Firestore index while an ascending range read does not.
  Stream<List<DailyDoseLog>> watchRecent(String uid, {int days = 7}) {
    final DateTime start = DateTime.now().subtract(Duration(days: days - 1));

    return _logs(uid)
        .where(
          FieldPath.documentId,
          isGreaterThanOrEqualTo: DailyDoseLog.keyFor(start),
        )
        .orderBy(FieldPath.documentId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => DailyDoseLog.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  /// Records, changes or clears one dose. Passing null removes the tick, so an
  /// accidental tap can be undone rather than leaving a wrong record behind.
  Future<void> setStatus(
    String uid,
    String dateKey,
    String doseKey,
    DoseStatus? status,
  ) {
    return _logs(uid).doc(dateKey).set(<String, dynamic>{
      'statuses': <String, Object?>{
        doseKey: status == null ? FieldValue.delete() : status.name,
      },
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
