import 'approximate_date.dart';
import 'health_record_audit.dart';
import 'record_provenance.dart';

/// A factual vaccination record. TARU does not infer missing doses.
///
/// [givenOn] is health/event time. [recordedAt]/[updatedAt] are TARU record
/// times.
class ImmunizationRecord {
  const ImmunizationRecord({
    required this.id,
    required this.vaccine,
    this.doseDescription = '',
    this.givenOn = ApproximateDate.unknown,
    this.notes = '',
    this.provenance = RecordProvenance.selfReported,
    this.recordedAt,
    this.updatedAt,
  });

  final String id;
  final String vaccine;
  final String doseDescription;
  final ApproximateDate givenOn;
  final String notes;
  final RecordProvenance provenance;
  final DateTime? recordedAt;
  final DateTime? updatedAt;

  ImmunizationRecord stamped({required DateTime now}) {
    final HealthRecordAudit audit = stampAudit(
      now: now,
      existingRecordedAt: recordedAt,
      provenance: provenance,
    );
    return ImmunizationRecord(
      id: id,
      vaccine: vaccine,
      doseDescription: doseDescription,
      givenOn: givenOn.persisted,
      notes: notes,
      provenance: audit.provenance,
      recordedAt: audit.recordedAt,
      updatedAt: audit.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'vaccine': vaccine,
      'doseDescription': doseDescription,
      'givenOn': givenOn.persisted.toMap(),
      'notes': notes,
      'provenance': provenance.name,
      if (recordedAt != null) 'recordedAt': HealthRecordAudit.iso(recordedAt!),
      if (updatedAt != null) 'updatedAt': HealthRecordAudit.iso(updatedAt!),
    };
  }

  static ImmunizationRecord? fromMap(String id, Map<String, dynamic>? data) {
    if (data == null) return null;
    final String vaccine = (data['vaccine'] as String?)?.trim() ?? '';
    if (vaccine.isEmpty) return null;
    return ImmunizationRecord(
      id: id,
      vaccine: vaccine,
      doseDescription: (data['doseDescription'] as String?) ?? '',
      givenOn: ApproximateDate.fromMap(data['givenOn']),
      notes: (data['notes'] as String?) ?? '',
      provenance: RecordProvenance.fromName(data['provenance'] as String?),
      recordedAt: HealthRecordAudit.parseTime(data['recordedAt']),
      updatedAt: HealthRecordAudit.parseTime(data['updatedAt']),
    );
  }
}
