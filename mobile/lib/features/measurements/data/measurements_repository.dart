import 'package:cloud_firestore/cloud_firestore.dart';

import '../../health_profile/domain/health_profile.dart';
import '../domain/weight_measurement.dart';

/// Longitudinal measurements under `users/{uid}/measurements`.
///
/// Phase 8 ships weight only. [recordWeight] is the single write path that
/// creates a measurement and mirrors `health/profile.weightKg`.
class MeasurementsRepository {
  MeasurementsRepository(this._firestore);

  final FirebaseFirestore _firestore;

  static const int historyLimit = 50;

  CollectionReference<Map<String, dynamic>> _measurements(String uid) =>
      _firestore.collection('users').doc(uid).collection('measurements');

  DocumentReference<Map<String, dynamic>> _profileDocument(String uid) =>
      _firestore.collection('users').doc(uid).collection('health').doc('profile');

  Query<Map<String, dynamic>> _weightQuery(String uid) {
    return _measurements(uid)
        .where('type', isEqualTo: measurementTypeWeight)
        .orderBy('recordedAt', descending: true)
        .orderBy(FieldPath.documentId, descending: true);
  }

  Stream<List<WeightMeasurement>> watchWeightHistory(String uid) {
    return _weightQuery(uid).limit(historyLimit).snapshots().map(_mapDocs);
  }

  Stream<WeightMeasurement?> watchLatestWeight(String uid) {
    return _weightQuery(uid).limit(1).snapshots().map((snapshot) {
      final List<WeightMeasurement> items = _mapDocs(snapshot);
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
    return _mapDocs(snapshot);
  }

  /// Records weight now and mirrors the Health Profile snapshot.
  ///
  /// Used by Weight History "Add weight" and "Start tracking".
  Future<void> recordWeight(String uid, double valueKg) async {
    if (!isPlausibleWeightKg(valueKg)) {
      throw ArgumentError.value(valueKg, 'valueKg', 'Weight out of range.');
    }

    final WriteBatch batch = _firestore.batch();
    final DocumentReference<Map<String, dynamic>> measurementRef =
        _measurements(uid).doc();
    final Timestamp recordedAt = Timestamp.fromDate(DateTime.now());

    batch.set(measurementRef, <String, dynamic>{
      'type': measurementTypeWeight,
      'valueKg': valueKg,
      'source': measurementSourceManual,
      'recordedAt': recordedAt,
    });
    batch.set(_profileDocument(uid), <String, dynamic>{
      'weightKg': valueKg,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await batch.commit();
  }

  /// Saves a full Health Profile merge, recording a weight measurement when
  /// [next] contains an intentional new non-null weight.
  ///
  /// Profile fields and the optional measurement commit in one WriteBatch.
  Future<void> saveHealthProfileWithWeightTracking({
    required String uid,
    required HealthProfile previous,
    required HealthProfile next,
    required bool hasWeightHistory,
  }) async {
    final bool clearingWeight = previous.weightKg != null && next.weightKg == null;
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

    if (shouldRecord && next.weightKg != null && !isPlausibleWeightKg(next.weightKg!)) {
      throw ArgumentError.value(next.weightKg, 'weightKg', 'Weight out of range.');
    }

    final WriteBatch batch = _firestore.batch();
    batch.set(_profileDocument(uid), next.toMap(), SetOptions(merge: true));

    if (shouldRecord) {
      final DocumentReference<Map<String, dynamic>> measurementRef =
          _measurements(uid).doc();
      batch.set(measurementRef, <String, dynamic>{
        'type': measurementTypeWeight,
        'valueKg': next.weightKg,
        'source': measurementSourceManual,
        'recordedAt': Timestamp.fromDate(DateTime.now()),
      });
    }

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

  List<WeightMeasurement> _mapDocs(
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
}
