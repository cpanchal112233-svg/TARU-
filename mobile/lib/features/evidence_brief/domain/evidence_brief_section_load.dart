import 'package:flutter/foundation.dart';

/// Load state for one Evidence Brief data-backed section.
enum EvidenceBriefSectionLoadStatus { loading, ready, empty, failed }

/// Compact per-section load result — not a generic state framework.
@immutable
class EvidenceBriefSectionLoad {
  const EvidenceBriefSectionLoad._(this.status, this.error);

  const EvidenceBriefSectionLoad.loading()
    : this._(EvidenceBriefSectionLoadStatus.loading, null);

  const EvidenceBriefSectionLoad.ready()
    : this._(EvidenceBriefSectionLoadStatus.ready, null);

  const EvidenceBriefSectionLoad.empty()
    : this._(EvidenceBriefSectionLoadStatus.empty, null);

  const EvidenceBriefSectionLoad.failed(Object error)
    : this._(EvidenceBriefSectionLoadStatus.failed, error);

  final EvidenceBriefSectionLoadStatus status;
  final Object? error;

  bool get isLoading => status == EvidenceBriefSectionLoadStatus.loading;

  bool get isFailed => status == EvidenceBriefSectionLoadStatus.failed;

  bool get isEmpty => status == EvidenceBriefSectionLoadStatus.empty;

  bool get isReady => status == EvidenceBriefSectionLoadStatus.ready;

  /// Ready or empty may be included in a share payload.
  bool get isShareable =>
      status == EvidenceBriefSectionLoadStatus.ready ||
      status == EvidenceBriefSectionLoadStatus.empty;

  String get failureLabel {
    return switch (this) {
      EvidenceBriefSectionLoad(status: EvidenceBriefSectionLoadStatus.failed) =>
        "Couldn't load this section.",
      _ => '',
    };
  }
}

/// Whether [selection] may produce a trustworthy share payload for [loads].
bool evidenceBriefSelectionIsShareable({
  required EvidenceBriefSectionLoad context,
  required EvidenceBriefSectionLoad measurements,
  required EvidenceBriefSectionLoad reports,
  required EvidenceBriefSectionLoad medicineRoutine,
  required EvidenceBriefSectionLoad lifestyleRoutine,
  required bool includeContext,
  required bool includeMeasurements,
  required bool includeReports,
  required bool includeMedicine,
  required bool includeLifestyle,
}) {
  if (includeContext && !context.isShareable) return false;
  if (includeMeasurements && !measurements.isShareable) return false;
  if (includeReports && !reports.isShareable) return false;
  if (includeMedicine && !medicineRoutine.isShareable) return false;
  if (includeLifestyle && !lifestyleRoutine.isShareable) return false;
  return true;
}
