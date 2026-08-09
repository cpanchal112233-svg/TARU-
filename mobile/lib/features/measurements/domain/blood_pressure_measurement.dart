import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Discriminator for blood-pressure documents in `users/{uid}/measurements`.
const String measurementTypeBloodPressure = 'blood_pressure';

/// How a BP measurement entered TARU. Phase 11 only writes [manual].
const String bloodPressureSourceManual = 'manual';

/// Technical input shape for systolic/diastolic mmHg (1–999).
///
/// This is a form/digit limit, not a clinical reference range.
bool isTechnicallyValidBpMmHg(int value) => value >= 1 && value <= 999;

/// Validates a BP field string before parse/save.
///
/// Digits-only text is allowed to grow beyond three characters so the user
/// can see what they typed; values with more than three digits, or outside
/// 1–999, are rejected. Never silently truncate.
bool isTechnicallyValidBpMmHgInput(String? raw) {
  final String text = raw?.trim() ?? '';
  if (text.isEmpty) return false;
  if (text.length > 3) return false;
  final int? parsed = int.tryParse(text);
  if (parsed == null) return false;
  return isTechnicallyValidBpMmHg(parsed);
}

/// One paired systolic/diastolic blood-pressure recording.
@immutable
class BloodPressureMeasurement {
  const BloodPressureMeasurement({
    required this.id,
    required this.systolicMmHg,
    required this.diastolicMmHg,
    required this.recordedAt,
    this.source = bloodPressureSourceManual,
  });

  final String id;
  final int systolicMmHg;
  final int diastolicMmHg;
  final DateTime recordedAt;
  final String source;

  Map<String, dynamic> toMap({required Timestamp recordedAtTimestamp}) {
    return <String, dynamic>{
      'type': measurementTypeBloodPressure,
      'systolicMmHg': systolicMmHg,
      'diastolicMmHg': diastolicMmHg,
      'source': source,
      'recordedAt': recordedAtTimestamp,
    };
  }

  /// Returns null when the document is not a usable blood-pressure reading.
  static BloodPressureMeasurement? fromMap(
    String id,
    Map<String, dynamic>? map,
  ) {
    if (map == null) return null;
    if (map['type'] != measurementTypeBloodPressure) return null;

    final int? systolic = _asInt(map['systolicMmHg']);
    final int? diastolic = _asInt(map['diastolicMmHg']);
    if (systolic == null || diastolic == null) return null;

    final Object? rawAt = map['recordedAt'];
    final DateTime? recordedAt = switch (rawAt) {
      final Timestamp t => t.toDate(),
      final DateTime d => d,
      _ => null,
    };
    if (recordedAt == null) return null;

    final Object? rawSource = map['source'];
    final String source = rawSource is String && rawSource.isNotEmpty
        ? rawSource
        : bloodPressureSourceManual;

    return BloodPressureMeasurement(
      id: id,
      systolicMmHg: systolic,
      diastolicMmHg: diastolic,
      recordedAt: recordedAt,
      source: source,
    );
  }

  static int? _asInt(Object? raw) {
    return switch (raw) {
      final int i => i,
      final num n => n.toInt(),
      _ => null,
    };
  }
}
