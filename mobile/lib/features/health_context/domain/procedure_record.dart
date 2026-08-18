import 'approximate_date.dart';
import 'health_record_audit.dart';
import 'record_provenance.dart';

/// A self-reported procedure or surgery. Not a clinical procedure code.
///
/// [occurredOn] is health/event time. [recordedAt]/[updatedAt] are TARU record
/// times.
class ProcedureRecord {
  const ProcedureRecord({
    required this.id,
    required this.name,
    this.occurredOn = ApproximateDate.unknown,
    this.reason = '',
    this.facility = '',
    this.clinician = '',
    this.notes = '',
    this.provenance = RecordProvenance.selfReported,
    this.recordedAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final ApproximateDate occurredOn;
  final String reason;
  final String facility;
  final String clinician;
  final String notes;
  final RecordProvenance provenance;
  final DateTime? recordedAt;
  final DateTime? updatedAt;

  ProcedureRecord stamped({required DateTime now}) {
    final HealthRecordAudit audit = stampAudit(
      now: now,
      existingRecordedAt: recordedAt,
      provenance: provenance,
    );
    return ProcedureRecord(
      id: id,
      name: name,
      occurredOn: occurredOn.persisted,
      reason: reason,
      facility: facility,
      clinician: clinician,
      notes: notes,
      provenance: audit.provenance,
      recordedAt: audit.recordedAt,
      updatedAt: audit.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'occurredOn': occurredOn.persisted.toMap(),
      'reason': reason,
      'facility': facility,
      'clinician': clinician,
      'notes': notes,
      'provenance': provenance.name,
      if (recordedAt != null) 'recordedAt': HealthRecordAudit.iso(recordedAt!),
      if (updatedAt != null) 'updatedAt': HealthRecordAudit.iso(updatedAt!),
    };
  }

  static ProcedureRecord? fromMap(String id, Map<String, dynamic>? data) {
    if (data == null) return null;
    final String name = (data['name'] as String?)?.trim() ?? '';
    if (name.isEmpty) return null;
    return ProcedureRecord(
      id: id,
      name: name,
      occurredOn: ApproximateDate.fromMap(data['occurredOn']),
      reason: (data['reason'] as String?) ?? '',
      facility: (data['facility'] as String?) ?? '',
      clinician: (data['clinician'] as String?) ?? '',
      notes: (data['notes'] as String?) ?? '',
      provenance: RecordProvenance.fromName(data['provenance'] as String?),
      recordedAt: HealthRecordAudit.parseTime(data['recordedAt']),
      updatedAt: HealthRecordAudit.parseTime(data['updatedAt']),
    );
  }
}
