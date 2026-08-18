import 'approximate_date.dart';
import 'health_record_audit.dart';
import 'record_provenance.dart';

/// One family-health history entry. TARU does not calculate inherited risk.
///
/// [onset] is health/event time. [recordedAt]/[updatedAt] are TARU record times.
class FamilyHistoryRecord {
  const FamilyHistoryRecord({
    required this.id,
    required this.relationship,
    required this.condition,
    this.onset = ApproximateDate.unknown,
    this.isCurrent = false,
    this.notes = '',
    this.provenance = RecordProvenance.selfReported,
    this.recordedAt,
    this.updatedAt,
  });

  final String id;
  final String relationship;
  final String condition;
  final ApproximateDate onset;
  final bool isCurrent;
  final String notes;
  final RecordProvenance provenance;
  final DateTime? recordedAt;
  final DateTime? updatedAt;

  FamilyHistoryRecord stamped({required DateTime now}) {
    final HealthRecordAudit audit = stampAudit(
      now: now,
      existingRecordedAt: recordedAt,
      provenance: provenance,
    );
    return FamilyHistoryRecord(
      id: id,
      relationship: relationship,
      condition: condition,
      onset: onset.persisted,
      isCurrent: isCurrent,
      notes: notes,
      provenance: audit.provenance,
      recordedAt: audit.recordedAt,
      updatedAt: audit.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'relationship': relationship,
      'condition': condition,
      'onset': onset.persisted.toMap(),
      'isCurrent': isCurrent,
      'notes': notes,
      'provenance': provenance.name,
      if (recordedAt != null) 'recordedAt': HealthRecordAudit.iso(recordedAt!),
      if (updatedAt != null) 'updatedAt': HealthRecordAudit.iso(updatedAt!),
    };
  }

  static FamilyHistoryRecord? fromMap(String id, Map<String, dynamic>? data) {
    if (data == null) return null;
    final String relationship = (data['relationship'] as String?)?.trim() ?? '';
    final String condition = (data['condition'] as String?)?.trim() ?? '';
    if (relationship.isEmpty && condition.isEmpty) return null;
    return FamilyHistoryRecord(
      id: id,
      relationship: relationship,
      condition: condition,
      onset: ApproximateDate.fromMap(data['onset']),
      isCurrent: data['isCurrent'] as bool? ?? false,
      notes: (data['notes'] as String?) ?? '',
      provenance: RecordProvenance.fromName(data['provenance'] as String?),
      recordedAt: HealthRecordAudit.parseTime(data['recordedAt']),
      updatedAt: HealthRecordAudit.parseTime(data['updatedAt']),
    );
  }
}

const List<String> familyRelationshipSuggestions = <String>[
  'Mother',
  'Father',
  'Sister',
  'Brother',
  'Daughter',
  'Son',
  'Grandmother',
  'Grandfather',
  'Aunt',
  'Uncle',
  'Cousin',
  'Other',
];
