/// Factual source labels for Evidence Brief items.
///
/// These are provenance markers only — never "clinician verified",
/// "medically verified", or "AI verified".
enum EvidenceProvenance {
  selfReported('Self-reported'),
  manualMeasurement('Manual measurement'),
  reportRecord('Report record'),
  routineLog('Routine log');

  const EvidenceProvenance(this.label);

  final String label;
}
