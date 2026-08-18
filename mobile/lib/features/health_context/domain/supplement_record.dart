import 'approximate_date.dart';
import 'health_record_audit.dart';
import 'record_provenance.dart';

/// A vitamin, mineral, herbal, Ayurvedic, or other non-prescription product.
///
/// Not a medication record. Not a prescription. Not a recommendation.
/// [started]/[stopped] are health/event times. [recordedAt]/[updatedAt] are
/// TARU record times.
class SupplementRecord {
  const SupplementRecord({
    required this.id,
    required this.name,
    this.form = '',
    this.doseText = '',
    this.frequency = '',
    this.started = ApproximateDate.unknown,
    this.stopped = ApproximateDate.unknown,
    this.reason = '',
    this.notes = '',
    this.isCurrent = true,
    this.provenance = RecordProvenance.selfReported,
    this.recordedAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String form;
  final String doseText;
  final String frequency;
  final ApproximateDate started;
  final ApproximateDate stopped;
  final String reason;
  final String notes;
  final bool isCurrent;
  final RecordProvenance provenance;
  final DateTime? recordedAt;
  final DateTime? updatedAt;

  /// Current products must not carry a stopped event date. A known stopped
  /// date must not precede a known started date. Missing dates are not inferred.
  bool get isTemporallyConsistent {
    if (isCurrent && !stopped.isUnknown) return false;
    return !stopped.isKnownBefore(started);
  }

  SupplementRecord stamped({required DateTime now}) {
    final HealthRecordAudit audit = stampAudit(
      now: now,
      existingRecordedAt: recordedAt,
      provenance: provenance,
    );
    return SupplementRecord(
      id: id,
      name: name,
      form: form,
      doseText: doseText,
      frequency: frequency,
      started: started.persisted,
      stopped: isCurrent ? ApproximateDate.unknown : stopped.persisted,
      reason: reason,
      notes: notes,
      isCurrent: isCurrent,
      provenance: audit.provenance,
      recordedAt: audit.recordedAt,
      updatedAt: audit.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'form': form,
      'doseText': doseText,
      'frequency': frequency,
      'started': started.persisted.toMap(),
      'stopped': (isCurrent ? ApproximateDate.unknown : stopped.persisted)
          .toMap(),
      'reason': reason,
      'notes': notes,
      'isCurrent': isCurrent,
      'provenance': provenance.name,
      if (recordedAt != null) 'recordedAt': HealthRecordAudit.iso(recordedAt!),
      if (updatedAt != null) 'updatedAt': HealthRecordAudit.iso(updatedAt!),
    };
  }

  static SupplementRecord? fromMap(String id, Map<String, dynamic>? data) {
    if (data == null) return null;
    final String name = (data['name'] as String?)?.trim() ?? '';
    if (name.isEmpty) return null;
    final SupplementRecord record = SupplementRecord(
      id: id,
      name: name,
      form: (data['form'] as String?) ?? '',
      doseText: (data['doseText'] as String?) ?? '',
      frequency: (data['frequency'] as String?) ?? '',
      started: ApproximateDate.fromMap(data['started']),
      stopped: ApproximateDate.fromMap(data['stopped']),
      reason: (data['reason'] as String?) ?? '',
      notes: (data['notes'] as String?) ?? '',
      isCurrent: data['isCurrent'] as bool? ?? true,
      provenance: RecordProvenance.fromName(data['provenance'] as String?),
      recordedAt: HealthRecordAudit.parseTime(data['recordedAt']),
      updatedAt: HealthRecordAudit.parseTime(data['updatedAt']),
    );
    if (!record.isTemporallyConsistent) return null;
    return record;
  }
}
