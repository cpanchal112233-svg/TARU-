import 'package:flutter/foundation.dart';

import 'evidence_brief.dart';
import 'evidence_brief_section_load.dart';

/// Major Evidence Brief sections the user can include or exclude before sharing.
enum EvidenceBriefSectionId {
  currentContext,
  measurements,
  reports,
  medicineRoutine,
  lifestyleRoutine,
  notes,
}

extension EvidenceBriefSectionIdLabel on EvidenceBriefSectionId {
  String get label => switch (this) {
    EvidenceBriefSectionId.currentContext => 'Current health context',
    EvidenceBriefSectionId.measurements => 'Measurements',
    EvidenceBriefSectionId.reports => 'Reports',
    EvidenceBriefSectionId.medicineRoutine => 'Medicine routine',
    EvidenceBriefSectionId.lifestyleRoutine => 'Lifestyle routine',
    EvidenceBriefSectionId.notes => 'Personal notes/questions',
  };
}

/// Which sections to include when formatting / sharing the brief.
@immutable
class EvidenceBriefShareSelection {
  const EvidenceBriefShareSelection({
    this.currentContext = true,
    this.measurements = true,
    this.reports = true,
    this.medicineRoutine = true,
    this.lifestyleRoutine = true,
    this.notes = true,
  });

  final bool currentContext;
  final bool measurements;
  final bool reports;
  final bool medicineRoutine;
  final bool lifestyleRoutine;
  final bool notes;

  bool includes(EvidenceBriefSectionId id) => switch (id) {
    EvidenceBriefSectionId.currentContext => currentContext,
    EvidenceBriefSectionId.measurements => measurements,
    EvidenceBriefSectionId.reports => reports,
    EvidenceBriefSectionId.medicineRoutine => medicineRoutine,
    EvidenceBriefSectionId.lifestyleRoutine => lifestyleRoutine,
    EvidenceBriefSectionId.notes => notes,
  };

  EvidenceBriefShareSelection copyWith({
    bool? currentContext,
    bool? measurements,
    bool? reports,
    bool? medicineRoutine,
    bool? lifestyleRoutine,
    bool? notes,
  }) {
    return EvidenceBriefShareSelection(
      currentContext: currentContext ?? this.currentContext,
      measurements: measurements ?? this.measurements,
      reports: reports ?? this.reports,
      medicineRoutine: medicineRoutine ?? this.medicineRoutine,
      lifestyleRoutine: lifestyleRoutine ?? this.lifestyleRoutine,
      notes: notes ?? this.notes,
    );
  }

  EvidenceBriefShareSelection withSection(
    EvidenceBriefSectionId id,
    bool enabled,
  ) {
    return switch (id) {
      EvidenceBriefSectionId.currentContext => copyWith(
        currentContext: enabled,
      ),
      EvidenceBriefSectionId.measurements => copyWith(measurements: enabled),
      EvidenceBriefSectionId.reports => copyWith(reports: enabled),
      EvidenceBriefSectionId.medicineRoutine => copyWith(
        medicineRoutine: enabled,
      ),
      EvidenceBriefSectionId.lifestyleRoutine => copyWith(
        lifestyleRoutine: enabled,
      ),
      EvidenceBriefSectionId.notes => copyWith(notes: enabled),
    };
  }

  /// Force failed sections off so they cannot remain selected.
  EvidenceBriefShareSelection withoutFailedSections(EvidenceBrief brief) {
    return copyWith(
      currentContext: currentContext && brief.contextLoad.isShareable,
      measurements: measurements && brief.measurementsLoad.isShareable,
      reports: reports && brief.reportsLoad.isShareable,
      medicineRoutine: medicineRoutine && brief.medicineLoad.isShareable,
      lifestyleRoutine: lifestyleRoutine && brief.lifestyleLoad.isShareable,
    );
  }

  /// Defaults: include shareable sections that have content (or empty notes off).
  factory EvidenceBriefShareSelection.defaultsFor(EvidenceBrief brief) {
    final bool hasNotes = brief.notes.trim().isNotEmpty;
    return EvidenceBriefShareSelection(
      currentContext:
          brief.contextLoad.isShareable &&
          (!brief.context.isEmpty || brief.context.hasAnyAnswer),
      measurements:
          brief.measurementsLoad.isShareable && !brief.measurements.isEmpty,
      reports: brief.reportsLoad.isShareable && !brief.reports.isEmpty,
      medicineRoutine:
          brief.medicineLoad.isShareable && brief.routine.hasMedicineContent,
      lifestyleRoutine:
          brief.lifestyleLoad.isShareable && brief.routine.hasLifestyleContent,
      notes: hasNotes,
    );
  }

  bool isShareableFor(EvidenceBrief brief) {
    return evidenceBriefSelectionIsShareable(
      context: brief.contextLoad,
      measurements: brief.measurementsLoad,
      reports: brief.reportsLoad,
      medicineRoutine: brief.medicineLoad,
      lifestyleRoutine: brief.lifestyleLoad,
      includeContext: currentContext,
      includeMeasurements: measurements,
      includeReports: reports,
      includeMedicine: medicineRoutine,
      includeLifestyle: lifestyleRoutine,
    );
  }
}

extension EvidenceBriefSectionLoadLookup on EvidenceBrief {
  EvidenceBriefSectionLoad loadFor(EvidenceBriefSectionId id) => switch (id) {
    EvidenceBriefSectionId.currentContext => contextLoad,
    EvidenceBriefSectionId.measurements => measurementsLoad,
    EvidenceBriefSectionId.reports => reportsLoad,
    EvidenceBriefSectionId.medicineRoutine => medicineLoad,
    EvidenceBriefSectionId.lifestyleRoutine => lifestyleLoad,
    EvidenceBriefSectionId.notes => const EvidenceBriefSectionLoad.ready(),
  };
}
