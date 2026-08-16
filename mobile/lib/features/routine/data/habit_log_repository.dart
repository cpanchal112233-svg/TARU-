import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/habit.dart';

/// Stores lifestyle habit ticks, one document per day.
///
/// Parallel to [DoseLogRepository]: document IDs are `yyyy-MM-dd`, and each
/// habit id is a field under `statuses`.
class HabitLogRepository {
  HabitLogRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _logs(String uid) =>
      _firestore.collection('users').doc(uid).collection('habitLogs');

  Stream<DailyHabitLog> watchDay(String uid, String dateKey) {
    return _logs(uid).doc(dateKey).snapshots().map((snapshot) {
      final Map<String, dynamic>? data = snapshot.data();

      if (!snapshot.exists || data == null) {
        return DailyHabitLog(dateKey: dateKey);
      }

      return DailyHabitLog.fromMap(dateKey, data);
    });
  }

  Stream<List<DailyHabitLog>> watchRecent(String uid, {int days = 7}) {
    final DateTime start = DateTime.now().subtract(Duration(days: days - 1));

    return _logs(uid)
        .where(
          FieldPath.documentId,
          isGreaterThanOrEqualTo: DailyHabitLog.keyFor(start),
        )
        .orderBy(FieldPath.documentId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => DailyHabitLog.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  /// Inclusive `yyyy-MM-dd` document-ID window (no composite index).
  Stream<List<DailyHabitLog>> watchDateKeyRange(
    String uid, {
    required String startKey,
    required String endKey,
  }) {
    return _logs(uid)
        .where(FieldPath.documentId, isGreaterThanOrEqualTo: startKey)
        .where(FieldPath.documentId, isLessThanOrEqualTo: endKey)
        .orderBy(FieldPath.documentId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => DailyHabitLog.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<void> setStatus(
    String uid,
    String dateKey,
    String habitId,
    HabitStatus? status,
  ) {
    return _logs(uid).doc(dateKey).set(<String, dynamic>{
      'statuses': <String, Object?>{
        habitId: status == null ? FieldValue.delete() : status.name,
      },
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
