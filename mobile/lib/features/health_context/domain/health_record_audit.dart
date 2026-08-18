import 'package:cloud_firestore/cloud_firestore.dart';

import 'record_provenance.dart';

/// TARU record-time metadata. Not health/event time.
///
/// [recordedAt] = when this record was first entered into TARU.
/// [updatedAt] = when this TARU representation was last modified.
/// Event fields (occurredOn, givenOn, onset, started/stopped, desiredBy)
/// remain separate.
class HealthRecordAudit {
  const HealthRecordAudit({
    required this.recordedAt,
    required this.updatedAt,
    this.provenance = RecordProvenance.selfReported,
  });

  final DateTime recordedAt;
  final DateTime updatedAt;
  final RecordProvenance provenance;

  static HealthRecordAudit firstWrite(
    DateTime now, {
    RecordProvenance provenance = RecordProvenance.selfReported,
  }) {
    final DateTime clock = now.toUtc();
    return HealthRecordAudit(
      recordedAt: clock,
      updatedAt: clock,
      provenance: provenance,
    );
  }

  HealthRecordAudit touched(DateTime now) {
    return HealthRecordAudit(
      recordedAt: recordedAt,
      updatedAt: now.toUtc(),
      provenance: provenance,
    );
  }

  static DateTime? parseTime(Object? raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw.toUtc();
    if (raw is Timestamp) return raw.toDate().toUtc();
    if (raw is String) return DateTime.tryParse(raw)?.toUtc();
    return null;
  }

  static String iso(DateTime value) => value.toUtc().toIso8601String();

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'recordedAt': iso(recordedAt),
      'updatedAt': iso(updatedAt),
      'provenance': provenance.name,
    };
  }
}

HealthRecordAudit stampAudit({
  required DateTime now,
  DateTime? existingRecordedAt,
  RecordProvenance provenance = RecordProvenance.selfReported,
}) {
  final DateTime clock = now.toUtc();
  return HealthRecordAudit(
    recordedAt: existingRecordedAt?.toUtc() ?? clock,
    updatedAt: clock,
    provenance: provenance,
  );
}
