import 'health_record_audit.dart';
import 'record_provenance.dart';

enum HealthGoalStatus { active, paused, completed }

enum HealthGoalArea {
  sleep,
  movement,
  symptoms,
  carePreparation,
  nutrition,
  other,
}

/// A user-owned goal. [desiredBy] is a user target date, not a recovery
/// prediction, cure date, or medical promise.
///
/// [recordedAt] is TARU record time (when first entered). [desiredBy] is the
/// user's outcome-horizon date. A past [desiredBy] is allowed (historical or
/// imported aim) and is still a user goal date.
class HealthGoalRecord {
  const HealthGoalRecord({
    required this.id,
    required this.title,
    required this.area,
    this.description = '',
    this.recordedAt,
    this.updatedAt,
    this.desiredBy,
    this.status = HealthGoalStatus.active,
    this.notes = '',
    this.provenance = RecordProvenance.selfReported,
  });

  final String id;
  final String title;
  final HealthGoalArea area;
  final String description;

  /// When this goal was first entered into TARU. Not [desiredBy].
  final DateTime? recordedAt;
  final DateTime? updatedAt;

  /// User-chosen outcome horizon. Not predicted recovery.
  final DateTime? desiredBy;
  final HealthGoalStatus status;
  final String notes;
  final RecordProvenance provenance;

  HealthGoalRecord stamped({required DateTime now}) {
    final HealthRecordAudit audit = stampAudit(
      now: now,
      existingRecordedAt: recordedAt,
      provenance: provenance,
    );
    return HealthGoalRecord(
      id: id,
      title: title,
      area: area,
      description: description,
      recordedAt: audit.recordedAt,
      updatedAt: audit.updatedAt,
      desiredBy: desiredBy,
      status: status,
      notes: notes,
      provenance: audit.provenance,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'title': title,
      'area': area.name,
      'description': description,
      if (recordedAt != null) 'recordedAt': HealthRecordAudit.iso(recordedAt!),
      if (updatedAt != null) 'updatedAt': HealthRecordAudit.iso(updatedAt!),
      if (desiredBy != null) 'desiredBy': desiredBy!.toUtc().toIso8601String(),
      'desiredByMeaning': 'userGoalDate',
      'status': status.name,
      'notes': notes,
      'provenance': provenance.name,
    };
  }

  static HealthGoalRecord? fromMap(String id, Map<String, dynamic>? data) {
    if (data == null) return null;
    final String title = (data['title'] as String?)?.trim() ?? '';
    if (title.isEmpty) return null;
    HealthGoalArea area = HealthGoalArea.other;
    for (final HealthGoalArea value in HealthGoalArea.values) {
      if (value.name == data['area']) {
        area = value;
        break;
      }
    }
    HealthGoalStatus status = HealthGoalStatus.active;
    for (final HealthGoalStatus value in HealthGoalStatus.values) {
      if (value.name == data['status']) {
        status = value;
        break;
      }
    }
    return HealthGoalRecord(
      id: id,
      title: title,
      area: area,
      description: (data['description'] as String?) ?? '',
      recordedAt:
          HealthRecordAudit.parseTime(data['recordedAt']) ??
          HealthRecordAudit.parseTime(data['createdAt']),
      updatedAt: HealthRecordAudit.parseTime(data['updatedAt']),
      desiredBy: DateTime.tryParse(data['desiredBy'] as String? ?? ''),
      status: status,
      notes: (data['notes'] as String?) ?? '',
      provenance: RecordProvenance.fromName(data['provenance'] as String?),
    );
  }
}

String healthGoalAreaLabel(HealthGoalArea area) {
  switch (area) {
    case HealthGoalArea.sleep:
      return 'Sleep';
    case HealthGoalArea.movement:
      return 'Movement';
    case HealthGoalArea.symptoms:
      return 'Symptoms';
    case HealthGoalArea.carePreparation:
      return 'Care preparation';
    case HealthGoalArea.nutrition:
      return 'Nutrition';
    case HealthGoalArea.other:
      return 'Other';
  }
}
