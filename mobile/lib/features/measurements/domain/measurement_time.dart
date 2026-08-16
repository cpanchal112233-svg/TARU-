/// Shared recordedAt validation for Phase 11 measurements.
///
/// [recordedAt] is the instant the measurement was taken. Materially future
/// times are rejected; a small clock-skew tolerance is allowed.
const Duration kMeasurementFutureSkewTolerance = Duration(minutes: 2);

/// Throws [ArgumentError] when [recordedAt] is more than
/// [kMeasurementFutureSkewTolerance] after [now].
void ensureRecordedAtAllowed(DateTime recordedAt, {DateTime? now}) {
  final DateTime reference = now ?? DateTime.now();
  if (recordedAt.isAfter(reference.add(kMeasurementFutureSkewTolerance))) {
    throw ArgumentError('Choose a measurement time that is not in the future.');
  }
}

/// Whether [candidate] ranks as the authoritative latest under:
/// recordedAt DESC, documentId DESC (Firestore FieldPath.documentId).
bool isAuthoritativeNewer({
  required DateTime candidateRecordedAt,
  required String candidateDocumentId,
  required DateTime? latestRecordedAt,
  required String? latestDocumentId,
}) {
  if (latestRecordedAt == null || latestDocumentId == null) {
    return true;
  }

  final int timeCompare = candidateRecordedAt.compareTo(latestRecordedAt);
  if (timeCompare != 0) {
    return timeCompare > 0;
  }

  // Descending documentId: lexicographically greater id ranks first.
  return candidateDocumentId.compareTo(latestDocumentId) > 0;
}
