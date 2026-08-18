/// Factual source of a user-owned health-context record.
///
/// These labels are not clinical verification. Do not add "verified",
/// "doctor verified", "clinically verified", or "AI verified".
enum RecordProvenance {
  selfReported,
  importedLater,
  clinicianProvidedLater,
  reportDerivedLater;

  String get label {
    switch (this) {
      case RecordProvenance.selfReported:
        return 'Self-reported';
      case RecordProvenance.importedLater:
        return 'Imported';
      case RecordProvenance.clinicianProvidedLater:
        return 'Clinician-provided';
      case RecordProvenance.reportDerivedLater:
        return 'Report-derived';
    }
  }

  static RecordProvenance fromName(String? raw) {
    for (final RecordProvenance value in RecordProvenance.values) {
      if (value.name == raw) return value;
    }
    return RecordProvenance.selfReported;
  }
}
