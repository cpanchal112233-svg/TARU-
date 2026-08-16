import 'package:cloud_firestore/cloud_firestore.dart';

import '../../health_profile/domain/health_profile.dart';
import '../domain/blood_pressure_measurement.dart';
import '../domain/measurement_time.dart';
import '../domain/weight_measurement.dart';

/// Longitudinal measurements under `users/{uid}/measurements`.
///
/// Phase 11: weight (with backdated recordedAt + authoritative mirror) and
/// blood pressure (paired systolic/diastolic, no profile mirror).
class MeasurementsRepository {
  MeasurementsRepository(this._firestore);

  final FirebaseFirestore _firestore;

  static const int historyLimit = 50;

  CollectionReference<Map<String, dynamic>> _measurements(String uid) =>
      _firestore.collection('users').doc(uid).collection('measurements');

  DocumentReference<Map<String, dynamic>> _profileDocument(String uid) =>
      _firestore
          .collection('users')
          .doc(uid)
          .collection('health')
          .doc('profile');

  Query<Map<String, dynamic>> _weightQuery(String uid) {
    return _measurements(uid)
        .where('type', isEqualTo: measurementTypeWeight)
        .orderBy('recordedAt', descending: true)
        .orderBy(FieldPath.documentId, descending: true);
  }

  Query<Map<String, dynamic>> _bloodPressureQuery(String uid) {
    return _measurements(uid)
        .where('type', isEqualTo: measurementTypeBloodPressure)
        .orderBy('recordedAt', descending: true)
        .orderBy(FieldPath.documentId, descending: true);
  }

  Stream<List<WeightMeasurement>> watchWeightHistory(String uid) {
    return _weightQuery(
      uid,
    ).limit(historyLimit).snapshots().map(_mapWeightDocs);
  }

  /// Full weight history without the UI display cap ([historyLimit]).
  ///
  /// Prefer [watchWeightHistoryInRange] for Evidence Brief period windows.
  Stream<List<WeightMeasurement>> watchWeightHistoryUncapped(String uid) {
    return _weightQuery(uid).snapshots().map(_mapWeightDocs);
  }

  /// Weight readings with `recordedAt` in `[startInclusive, endExclusive)`.
  ///
  /// Uses the existing composite index:
  /// `type ASC, recordedAt DESC, __name__ DESC`.
  Stream<List<WeightMeasurement>> watchWeightHistoryInRange(
    String uid, {
    required DateTime startInclusive,
    required DateTime endExclusive,
  }) {
    return _weightQuery(uid)
        .where(
          'recordedAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startInclusive),
        )
        .where('recordedAt', isLessThan: Timestamp.fromDate(endExclusive))
        .snapshots()
        .map(_mapWeightDocs);
  }

  Stream<WeightMeasurement?> watchLatestWeight(String uid) {
    return _weightQuery(uid).limit(1).snapshots().map((snapshot) {
      final List<WeightMeasurement> items = _mapWeightDocs(snapshot);
      return items.isEmpty ? null : items.first;
    });
  }

  Stream<List<BloodPressureMeasurement>> watchBloodPressureHistory(String uid) {
    return _bloodPressureQuery(
      uid,
    ).limit(historyLimit).snapshots().map(_mapBloodPressureDocs);
  }

  /// Full blood-pressure history without the UI display cap ([historyLimit]).
  Stream<List<BloodPressureMeasurement>> watchBloodPressureHistoryUncapped(
    String uid,
  ) {
    return _bloodPressureQuery(uid).snapshots().map(_mapBloodPressureDocs);
  }

  /// BP readings with `recordedAt` in `[startInclusive, endExclusive)`.
  Stream<List<BloodPressureMeasurement>> watchBloodPressureHistoryInRange(
    String uid, {
    required DateTime startInclusive,
    required DateTime endExclusive,
  }) {
    return _bloodPressureQuery(uid)
        .where(
          'recordedAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startInclusive),
        )
        .where('recordedAt', isLessThan: Timestamp.fromDate(endExclusive))
        .snapshots()
        .map(_mapBloodPressureDocs);
  }

  Stream<BloodPressureMeasurement?> watchLatestBloodPressure(String uid) {
    return _bloodPressureQuery(uid).limit(1).snapshots().map((snapshot) {
      final List<BloodPressureMeasurement> items = _mapBloodPressureDocs(
        snapshot,
      );
      return items.isEmpty ? null : items.first;
    });
  }

  Future<bool> hasWeightHistory(String uid) async {
    final QuerySnapshot<Map<String, dynamic>> snapshot = await _weightQuery(
      uid,
    ).limit(1).get();
    return snapshot.docs.isNotEmpty;
  }

  Future<List<WeightMeasurement>> fetchLatestWeights(
    String uid, {
    int limit = 2,
  }) async {
    final QuerySnapshot<Map<String, dynamic>> snapshot = await _weightQuery(
      uid,
    ).limit(limit).get();
    return _mapWeightDocs(snapshot);
  }

  Future<List<BloodPressureMeasurement>> fetchLatestBloodPressures(
    String uid, {
    int limit = 2,
  }) async {
    final QuerySnapshot<Map<String, dynamic>> snapshot =
        await _bloodPressureQuery(uid).limit(limit).get();
    return _mapBloodPressureDocs(snapshot);
  }

  /// Records weight at [recordedAt] and updates `profile.weightKg` only when
  /// the new document becomes the authoritative latest.
  Future<void> recordWeight(
    String uid,
    double valueKg, {
    DateTime? recordedAt,
    DateTime? now,
  }) async {
    if (!isPlausibleWeightKg(valueKg)) {
      throw ArgumentError.value(valueKg, 'valueKg', 'Weight out of range.');
    }

    final DateTime takenAt = recordedAt ?? DateTime.now();
    ensureRecordedAtAllowed(takenAt, now: now);

    final DocumentReference<Map<String, dynamic>> measurementRef =
        _measurements(uid).doc();
    final List<WeightMeasurement> latest = await fetchLatestWeights(
      uid,
      limit: 1,
    );
    final bool updateMirror = isAuthoritativeNewer(
      candidateRecordedAt: takenAt,
      candidateDocumentId: measurementRef.id,
      latestRecordedAt: latest.isEmpty ? null : latest.first.recordedAt,
      latestDocumentId: latest.isEmpty ? null : latest.first.id,
    );

    final WriteBatch batch = _firestore.batch();
    batch.set(measurementRef, <String, dynamic>{
      'type': measurementTypeWeight,
      'valueKg': valueKg,
      'source': measurementSourceManual,
      'recordedAt': Timestamp.fromDate(takenAt),
    });

    if (updateMirror) {
      batch.set(_profileDocument(uid), <String, dynamic>{
        'weightKg': valueKg,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    await batch.commit();
  }

  /// Saves a full Health Profile merge, recording a weight measurement when
  /// [next] contains an intentional new non-null weight.
  ///
  /// Profile fields always merge. The optional measurement uses the same
  /// authoritative-latest mirror gate as [recordWeight] (time = now).
  Future<void> saveHealthProfileWithWeightTracking({
    required String uid,
    required HealthProfile previous,
    required HealthProfile next,
    required bool hasWeightHistory,
    DateTime? now,
  }) async {
    final bool clearingWeight =
        previous.weightKg != null && next.weightKg == null;
    if (hasWeightHistory && clearingWeight) {
      throw StateError(
        'Tracked weight cannot be cleared from Health Profile. '
        'Delete entries in Weight History instead.',
      );
    }

    final bool shouldRecord = isIntentionalNewWeight(
      previous: previous.weightKg,
      next: next.weightKg,
    );

    if (shouldRecord &&
        next.weightKg != null &&
        !isPlausibleWeightKg(next.weightKg!)) {
      throw ArgumentError.value(
        next.weightKg,
        'weightKg',
        'Weight out of range.',
      );
    }

    final WriteBatch batch = _firestore.batch();
    Map<String, dynamic> profileMap = next.toMap();

    if (shouldRecord) {
      final DateTime referenceNow = now ?? DateTime.now();
      final DateTime takenAt = referenceNow;
      ensureRecordedAtAllowed(takenAt, now: referenceNow);

      final DocumentReference<Map<String, dynamic>> measurementRef =
          _measurements(uid).doc();
      final List<WeightMeasurement> latest = await fetchLatestWeights(
        uid,
        limit: 1,
      );
      final bool updateMirror = isAuthoritativeNewer(
        candidateRecordedAt: takenAt,
        candidateDocumentId: measurementRef.id,
        latestRecordedAt: latest.isEmpty ? null : latest.first.recordedAt,
        latestDocumentId: latest.isEmpty ? null : latest.first.id,
      );

      batch.set(measurementRef, <String, dynamic>{
        'type': measurementTypeWeight,
        'valueKg': next.weightKg,
        'source': measurementSourceManual,
        'recordedAt': Timestamp.fromDate(takenAt),
      });

      // Profile draft carries next.weightKg. Mirror only when this recording
      // becomes authoritative latest; otherwise keep the existing latest.
      if (!updateMirror && latest.isNotEmpty) {
        profileMap = <String, dynamic>{
          ...profileMap,
          'weightKg': latest.first.valueKg,
        };
      }
    }

    batch.set(_profileDocument(uid), profileMap, SetOptions(merge: true));
    await batch.commit();
  }

  /// Deletes one weight measurement and reconciles the profile snapshot when
  /// the deleted doc was the latest.
  Future<void> deleteWeightMeasurement(String uid, String measurementId) async {
    final List<WeightMeasurement> latestTwo = await fetchLatestWeights(
      uid,
      limit: 2,
    );

    final bool isLatest =
        latestTwo.isNotEmpty && latestTwo.first.id == measurementId;

    final WriteBatch batch = _firestore.batch();
    batch.delete(_measurements(uid).doc(measurementId));

    if (isLatest) {
      final double? nextWeight = latestTwo.length > 1
          ? latestTwo[1].valueKg
          : null;
      batch.set(_profileDocument(uid), <String, dynamic>{
        'weightKg': nextWeight,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    await batch.commit();
  }

  /// Records a paired BP reading. No Health Profile mirror.
  Future<void> recordBloodPressure(
    String uid, {
    required int systolicMmHg,
    required int diastolicMmHg,
    DateTime? recordedAt,
    DateTime? now,
  }) async {
    if (!isTechnicallyValidBpMmHg(systolicMmHg)) {
      throw ArgumentError('Enter a valid systolic value.');
    }
    if (!isTechnicallyValidBpMmHg(diastolicMmHg)) {
      throw ArgumentError('Enter a valid diastolic value.');
    }

    final DateTime takenAt = recordedAt ?? DateTime.now();
    ensureRecordedAtAllowed(takenAt, now: now);

    final DocumentReference<Map<String, dynamic>> measurementRef =
        _measurements(uid).doc();
    await measurementRef.set(<String, dynamic>{
      'type': measurementTypeBloodPressure,
      'systolicMmHg': systolicMmHg,
      'diastolicMmHg': diastolicMmHg,
      'source': bloodPressureSourceManual,
      'recordedAt': Timestamp.fromDate(takenAt),
    });
  }

  Future<void> deleteBloodPressureMeasurement(
    String uid,
    String measurementId,
  ) async {
    await _measurements(uid).doc(measurementId).delete();
  }

  List<WeightMeasurement> _mapWeightDocs(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final List<WeightMeasurement> items = <WeightMeasurement>[];
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
        in snapshot.docs) {
      final WeightMeasurement? measurement = WeightMeasurement.fromMap(
        doc.id,
        doc.data(),
      );
      if (measurement != null) items.add(measurement);
    }
    return items;
  }

  List<BloodPressureMeasurement> _mapBloodPressureDocs(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final List<BloodPressureMeasurement> items = <BloodPressureMeasurement>[];
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
        in snapshot.docs) {
      final BloodPressureMeasurement? measurement =
          BloodPressureMeasurement.fromMap(doc.id, doc.data());
      if (measurement != null) items.add(measurement);
    }
    return items;
  }
}
