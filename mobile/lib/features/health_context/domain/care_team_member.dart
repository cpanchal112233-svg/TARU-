import 'health_record_audit.dart';
import 'record_provenance.dart';

/// User-owned clinician/care-team reference. TARU does not contact them.
///
/// No health-event date. [recordedAt]/[updatedAt] are TARU record times.
class CareTeamMember {
  const CareTeamMember({
    required this.id,
    this.name = '',
    this.role = '',
    this.organisation = '',
    this.phone = '',
    this.email = '',
    this.notes = '',
    this.provenance = RecordProvenance.selfReported,
    this.recordedAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String role;
  final String organisation;
  final String phone;
  final String email;
  final String notes;
  final RecordProvenance provenance;
  final DateTime? recordedAt;
  final DateTime? updatedAt;

  bool get hasContent =>
      name.trim().isNotEmpty ||
      role.trim().isNotEmpty ||
      organisation.trim().isNotEmpty ||
      phone.trim().isNotEmpty ||
      email.trim().isNotEmpty ||
      notes.trim().isNotEmpty;

  CareTeamMember stamped({required DateTime now}) {
    final HealthRecordAudit audit = stampAudit(
      now: now,
      existingRecordedAt: recordedAt,
      provenance: provenance,
    );
    return CareTeamMember(
      id: id,
      name: name,
      role: role,
      organisation: organisation,
      phone: phone,
      email: email,
      notes: notes,
      provenance: audit.provenance,
      recordedAt: audit.recordedAt,
      updatedAt: audit.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'role': role,
      'organisation': organisation,
      'phone': phone,
      'email': email,
      'notes': notes,
      'provenance': provenance.name,
      if (recordedAt != null) 'recordedAt': HealthRecordAudit.iso(recordedAt!),
      if (updatedAt != null) 'updatedAt': HealthRecordAudit.iso(updatedAt!),
    };
  }

  static CareTeamMember? fromMap(String id, Map<String, dynamic>? data) {
    if (data == null) return null;
    final CareTeamMember member = CareTeamMember(
      id: id,
      name: (data['name'] as String?) ?? '',
      role: (data['role'] as String?) ?? '',
      organisation: (data['organisation'] as String?) ?? '',
      phone: (data['phone'] as String?) ?? '',
      email: (data['email'] as String?) ?? '',
      notes: (data['notes'] as String?) ?? '',
      provenance: RecordProvenance.fromName(data['provenance'] as String?),
      recordedAt: HealthRecordAudit.parseTime(data['recordedAt']),
      updatedAt: HealthRecordAudit.parseTime(data['updatedAt']),
    );
    if (!member.hasContent) return null;
    return member;
  }
}
