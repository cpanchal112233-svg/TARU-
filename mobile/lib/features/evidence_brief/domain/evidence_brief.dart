import 'package:flutter/foundation.dart';

import '../../measurements/domain/blood_pressure_measurement.dart';
import '../../measurements/domain/weight_measurement.dart';
import '../../reports/domain/medical_report.dart';
import '../../routine/domain/dose_schedule.dart';
import '../../routine/domain/habit.dart';
import 'evidence_brief_period.dart';
import 'evidence_brief_provenance.dart';
import 'evidence_brief_section_load.dart';

/// Whether a report uses takenOn or uploadedAt for inclusion/display.
enum ReportDateBasis { taken, uploaded }

/// Prefer [MedicalReport.takenOn] when present; otherwise [uploadedAt].
DateTime reportMeaningfulDate(MedicalReport report) =>
    report.takenOn ?? report.uploadedAt;

ReportDateBasis reportDateBasis(MedicalReport report) =>
    report.takenOn != null ? ReportDateBasis.taken : ReportDateBasis.uploaded;

/// User-facing date line: "Taken …" or "Uploaded …" — never silent upload-as-taken.
String reportDateBasisLabel(
  MedicalReport report, {
  String Function(DateTime)? format,
}) {
  final String Function(DateTime) fmt = format ?? _defaultDayFormat;
  if (report.takenOn != null) {
    return 'Taken ${fmt(report.takenOn!)}';
  }
  return 'Uploaded ${fmt(report.uploadedAt)}';
}

String _defaultDayFormat(DateTime date) {
  const List<String> months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

/// One line in the current self-reported context section.
@immutable
class EvidenceBriefContextItem {
  const EvidenceBriefContextItem({required this.label, required this.detail});

  final String label;
  final String? detail;

  EvidenceProvenance get provenance => EvidenceProvenance.selfReported;
}

/// Current (not period-filtered) self-reported health context.
@immutable
class EvidenceBriefContextSection {
  const EvidenceBriefContextSection({
    required this.conditions,
    required this.allergies,
    required this.medicines,
    required this.conditionsAnswered,
    required this.allergiesAnswered,
    required this.medicinesAnswered,
    required this.noKnownConditions,
    required this.noKnownAllergies,
    required this.takesNoMedication,
    required this.asOf,
  });

  final List<EvidenceBriefContextItem> conditions;
  final List<EvidenceBriefContextItem> allergies;
  final List<EvidenceBriefContextItem> medicines;
  final bool conditionsAnswered;
  final bool allergiesAnswered;
  final bool medicinesAnswered;
  final bool noKnownConditions;
  final bool noKnownAllergies;
  final bool takesNoMedication;

  /// Local calendar day this snapshot is "current as of".
  final DateTime asOf;

  EvidenceProvenance get provenance => EvidenceProvenance.selfReported;

  bool get isEmpty =>
      conditions.isEmpty && allergies.isEmpty && medicines.isEmpty;

  bool get hasAnyAnswer =>
      conditionsAnswered || allergiesAnswered || medicinesAnswered;

  String get asOfLabel =>
      'Current information you have recorded in TARU as of '
      '${_defaultDayFormat(asOf)}.';
}

/// Weight or BP row recorded in the selected period.
@immutable
class EvidenceBriefMeasurementItem {
  const EvidenceBriefMeasurementItem.weight(this.weight) : bloodPressure = null;

  const EvidenceBriefMeasurementItem.bloodPressure(this.bloodPressure)
    : weight = null;

  final WeightMeasurement? weight;
  final BloodPressureMeasurement? bloodPressure;

  EvidenceProvenance get provenance => EvidenceProvenance.manualMeasurement;

  bool get isWeight => weight != null;

  DateTime get recordedAt => weight?.recordedAt ?? bloodPressure!.recordedAt;
}

@immutable
class EvidenceBriefMeasurementsSection {
  const EvidenceBriefMeasurementsSection({
    required this.weights,
    required this.bloodPressures,
  });

  final List<WeightMeasurement> weights;
  final List<BloodPressureMeasurement> bloodPressures;

  EvidenceProvenance get provenance => EvidenceProvenance.manualMeasurement;

  bool get isEmpty => weights.isEmpty && bloodPressures.isEmpty;

  int get count => weights.length + bloodPressures.length;
}

@immutable
class EvidenceBriefReportItem {
  const EvidenceBriefReportItem({required this.report});

  final MedicalReport report;

  EvidenceProvenance get provenance => EvidenceProvenance.reportRecord;

  DateTime get meaningfulDate => reportMeaningfulDate(report);

  ReportDateBasis get dateBasis => reportDateBasis(report);

  String get dateBasisLabel => reportDateBasisLabel(report);
}

@immutable
class EvidenceBriefReportsSection {
  const EvidenceBriefReportsSection({required this.reports});

  final List<EvidenceBriefReportItem> reports;

  EvidenceProvenance get provenance => EvidenceProvenance.reportRecord;

  bool get isEmpty => reports.isEmpty;
}

/// Factual routine logging counts for the period — no combined score.
@immutable
class EvidenceBriefRoutineSection {
  const EvidenceBriefRoutineSection({
    required this.medicine,
    required this.lifestyle,
    required this.noMedicinesConfigured,
    required this.noActiveHabits,
    required this.caveats,
    this.medicineDaysWithRecords = 0,
    this.lifestyleDaysWithRecords = 0,
  });

  final AdherenceSummary? medicine;
  final HabitAdherenceSummary? lifestyle;
  final bool noMedicinesConfigured;
  final bool noActiveHabits;

  /// Distinct local days with at least one dose status in the period.
  final int medicineDaysWithRecords;

  /// Distinct local days with at least one habit status in the period.
  final int lifestyleDaysWithRecords;

  /// Phase 7 honesty lines preserved for share and UI.
  final List<String> caveats;

  EvidenceProvenance get provenance => EvidenceProvenance.routineLog;

  bool get isEmpty =>
      (medicine == null || !medicine!.hasData) &&
      (lifestyle == null || !lifestyle!.hasData);

  bool get hasMedicineContent =>
      noMedicinesConfigured || (medicine != null && medicine!.hasData);

  bool get hasLifestyleContent =>
      noActiveHabits || (lifestyle != null && lifestyle!.hasData);

  /// Toggle enabled even when the factual line is "no logs in this period".
  bool get medicineSelectable => true;

  bool get lifestyleSelectable => true;
}

/// Non-clinical transparency summary — not a completeness or health score.
@immutable
class EvidenceBriefSourcesSummary {
  const EvidenceBriefSourcesSummary({
    required this.hasCurrentContext,
    required this.weightCount,
    required this.bloodPressureCount,
    required this.reportCount,
    required this.medicineDaysWithRecords,
    required this.lifestyleDaysWithRecords,
  });

  final bool hasCurrentContext;
  final int weightCount;
  final int bloodPressureCount;
  final int reportCount;
  final int medicineDaysWithRecords;
  final int lifestyleDaysWithRecords;

  List<String> get lines {
    final List<String> out = <String>[];
    if (hasCurrentContext) {
      out.add('Current self-reported context');
    }
    if (weightCount > 0) {
      out.add(
        '$weightCount weight '
        '${weightCount == 1 ? 'reading' : 'readings'}',
      );
    }
    if (bloodPressureCount > 0) {
      out.add(
        '$bloodPressureCount blood-pressure '
        '${bloodPressureCount == 1 ? 'reading' : 'readings'}',
      );
    }
    if (reportCount > 0) {
      out.add(
        '$reportCount report '
        '${reportCount == 1 ? 'record' : 'records'}',
      );
    }
    if (medicineDaysWithRecords > 0) {
      out.add(
        'Medicine logs on $medicineDaysWithRecords '
        '${medicineDaysWithRecords == 1 ? 'day' : 'days'}',
      );
    }
    if (lifestyleDaysWithRecords > 0) {
      out.add(
        'Lifestyle logs on $lifestyleDaysWithRecords '
        '${lifestyleDaysWithRecords == 1 ? 'day' : 'days'}',
      );
    }
    if (out.isEmpty) {
      out.add('No period records in this selection yet');
    }
    return out;
  }

  factory EvidenceBriefSourcesSummary.fromBrief(EvidenceBrief brief) {
    return EvidenceBriefSourcesSummary(
      hasCurrentContext:
          brief.contextLoad.isShareable &&
          (brief.context.hasAnyAnswer || !brief.context.isEmpty),
      weightCount: brief.measurementsLoad.isShareable
          ? brief.measurements.weights.length
          : 0,
      bloodPressureCount: brief.measurementsLoad.isShareable
          ? brief.measurements.bloodPressures.length
          : 0,
      reportCount: brief.reportsLoad.isShareable
          ? brief.reports.reports.length
          : 0,
      medicineDaysWithRecords: brief.medicineLoad.isShareable
          ? brief.routine.medicineDaysWithRecords
          : 0,
      lifestyleDaysWithRecords: brief.lifestyleLoad.isShareable
          ? brief.routine.lifestyleDaysWithRecords
          : 0,
    );
  }
}

/// Assembled Evidence Brief for one period + optional ephemeral notes.
@immutable
class EvidenceBrief {
  const EvidenceBrief({
    required this.period,
    required this.context,
    required this.measurements,
    required this.reports,
    required this.routine,
    this.notes = '',
    this.createdAt,
    this.contextLoad = const EvidenceBriefSectionLoad.ready(),
    this.measurementsLoad = const EvidenceBriefSectionLoad.ready(),
    this.reportsLoad = const EvidenceBriefSectionLoad.ready(),
    this.medicineLoad = const EvidenceBriefSectionLoad.ready(),
    this.lifestyleLoad = const EvidenceBriefSectionLoad.ready(),
  });

  final EvidenceBriefPeriod period;
  final EvidenceBriefContextSection context;
  final EvidenceBriefMeasurementsSection measurements;
  final EvidenceBriefReportsSection reports;
  final EvidenceBriefRoutineSection routine;
  final String notes;

  /// When the brief was assembled (for share "Created:" line).
  final DateTime? createdAt;

  final EvidenceBriefSectionLoad contextLoad;
  final EvidenceBriefSectionLoad measurementsLoad;
  final EvidenceBriefSectionLoad reportsLoad;
  final EvidenceBriefSectionLoad medicineLoad;
  final EvidenceBriefSectionLoad lifestyleLoad;

  EvidenceBriefSourcesSummary get sourcesSummary =>
      EvidenceBriefSourcesSummary.fromBrief(this);

  bool get isLoading =>
      contextLoad.isLoading ||
      measurementsLoad.isLoading ||
      reportsLoad.isLoading ||
      medicineLoad.isLoading ||
      lifestyleLoad.isLoading;

  /// True only when every data-backed section failed (legacy whole-brief gate).
  bool get hasError =>
      contextLoad.isFailed &&
      measurementsLoad.isFailed &&
      reportsLoad.isFailed &&
      medicineLoad.isFailed &&
      lifestyleLoad.isFailed;

  bool get isEffectivelyEmpty =>
      !isLoading &&
      contextLoad.isShareable &&
      measurementsLoad.isShareable &&
      reportsLoad.isShareable &&
      medicineLoad.isShareable &&
      lifestyleLoad.isShareable &&
      context.isEmpty &&
      !context.hasAnyAnswer &&
      measurements.isEmpty &&
      reports.isEmpty &&
      routine.isEmpty &&
      notes.trim().isEmpty;

  /// Period historical evidence only (excludes current snapshot context).
  bool get hasNoPeriodEvidence =>
      !isLoading &&
      measurementsLoad.isShareable &&
      reportsLoad.isShareable &&
      medicineLoad.isShareable &&
      lifestyleLoad.isShareable &&
      measurements.isEmpty &&
      reports.isEmpty &&
      routine.isEmpty;
}

/// Filters measurements to [period] by recorded calendar day.
List<WeightMeasurement> weightsInPeriod(
  Iterable<WeightMeasurement> all,
  EvidenceBriefPeriod period,
) {
  return all
      .where((WeightMeasurement m) => period.containsInstant(m.recordedAt))
      .toList(growable: false);
}

List<BloodPressureMeasurement> bloodPressuresInPeriod(
  Iterable<BloodPressureMeasurement> all,
  EvidenceBriefPeriod period,
) {
  return all
      .where(
        (BloodPressureMeasurement m) => period.containsInstant(m.recordedAt),
      )
      .toList(growable: false);
}

/// Reports whose inclusion date falls in [period].
///
/// Inclusion uses [takenOn] when present, otherwise [uploadedAt].
/// Never includes OCR / extracted body.
List<MedicalReport> reportsInPeriod(
  Iterable<MedicalReport> all,
  EvidenceBriefPeriod period,
) {
  final List<MedicalReport> matched = all
      .where(
        (MedicalReport report) =>
            period.containsInstant(reportMeaningfulDate(report)),
      )
      .toList();
  matched.sort(
    (MedicalReport a, MedicalReport b) =>
        reportMeaningfulDate(b).compareTo(reportMeaningfulDate(a)),
  );
  return matched;
}

/// Builds factual routine counts for [period] from existing Phase 7 formulas.
EvidenceBriefRoutineSection buildRoutineSection({
  required EvidenceBriefPeriod period,
  required List<DailyDoseLog> doseLogs,
  required List<DailyHabitLog> habitLogs,
  required int dosesPerDay,
  required List<HabitItem> activeHabits,
}) {
  final List<DailyDoseLog> doseInPeriod = doseLogs
      .where((DailyDoseLog log) => period.containsDateKey(log.dateKey))
      .toList(growable: false);
  final List<DailyHabitLog> habitInPeriod = habitLogs
      .where((DailyHabitLog log) => period.containsDateKey(log.dateKey))
      .toList(growable: false);

  final bool noMedicines = dosesPerDay <= 0;
  final bool noHabits = activeHabits.isEmpty;

  AdherenceSummary? medicine;
  if (!noMedicines) {
    final AdherenceSummary summary = AdherenceSummary.fromLogs(
      logs: doseInPeriod,
      dosesPerDay: dosesPerDay,
      windowDays: period.dayCount,
      asOf: period.end,
    );
    medicine = summary.hasData ? summary : null;
  }

  HabitAdherenceSummary? lifestyle;
  if (!noHabits) {
    final HabitAdherenceSummary summary = HabitAdherenceSummary.fromLogs(
      logs: habitInPeriod,
      activeHabits: activeHabits,
      windowDays: period.dayCount,
      asOf: period.end,
    );
    lifestyle = _lifestyleForPeriod(
      summary: summary,
      habitInPeriod: habitInPeriod,
      activeHabits: activeHabits,
    );
  }

  final int medicineDays = doseInPeriod
      .where((DailyDoseLog log) => log.statuses.isNotEmpty)
      .map((DailyDoseLog log) => log.dateKey)
      .toSet()
      .length;
  final int lifestyleDays = habitInPeriod
      .where((DailyHabitLog log) => log.statuses.isNotEmpty)
      .map((DailyHabitLog log) => log.dateKey)
      .toSet()
      .length;

  return EvidenceBriefRoutineSection(
    medicine: medicine,
    lifestyle: lifestyle,
    noMedicinesConfigured: noMedicines,
    noActiveHabits: noHabits,
    medicineDaysWithRecords: medicineDays,
    lifestyleDaysWithRecords: lifestyleDays,
    caveats: const <String>[
      'Medicine expected doses use your current medicine schedule, not a '
          'historical prescription record.',
      'Routine figures are self-reported logs, not a clinical adherence score.',
      'Medicine and lifestyle are separate — there is no combined score.',
    ],
  );
}

/// Union of local days that have medicine or lifestyle routine records.
int routineDaysUnionCount({
  required EvidenceBriefPeriod period,
  required List<DailyDoseLog> doseLogs,
  required List<DailyHabitLog> habitLogs,
}) {
  final Set<String> days = <String>{};
  for (final DailyDoseLog log in doseLogs) {
    if (period.containsDateKey(log.dateKey) && log.statuses.isNotEmpty) {
      days.add(log.dateKey);
    }
  }
  for (final DailyHabitLog log in habitLogs) {
    if (period.containsDateKey(log.dateKey) && log.statuses.isNotEmpty) {
      days.add(log.dateKey);
    }
  }
  return days.length;
}

HabitAdherenceSummary? _lifestyleForPeriod({
  required HabitAdherenceSummary summary,
  required List<DailyHabitLog> habitInPeriod,
  required List<HabitItem> activeHabits,
}) {
  if (summary.hasData) return summary;

  if (habitInPeriod.isEmpty || activeHabits.isEmpty) return null;

  final List<DailyHabitLog> withStatuses = habitInPeriod
      .where((DailyHabitLog log) => log.statuses.isNotEmpty)
      .toList(growable: false);
  if (withStatuses.isEmpty) return null;

  int done = 0;
  for (final DailyHabitLog log in withStatuses) {
    for (final HabitItem habit in activeHabits) {
      if (log.statusOf(habit.id) == HabitStatus.done) done += 1;
    }
  }

  final int possible = activeHabits.length * withStatuses.length;
  if (possible <= 0) return null;

  final Map<HabitPillar, int> pillarDone = <HabitPillar, int>{
    for (final HabitPillar pillar in HabitPillar.values) pillar: 0,
  };
  final Map<HabitPillar, int> pillarPossible = <HabitPillar, int>{
    for (final HabitPillar pillar in HabitPillar.values) pillar: 0,
  };
  for (final HabitItem habit in activeHabits) {
    pillarPossible[habit.pillar] =
        (pillarPossible[habit.pillar] ?? 0) + withStatuses.length;
  }
  for (final DailyHabitLog log in withStatuses) {
    for (final HabitItem habit in activeHabits) {
      if (log.statusOf(habit.id) == HabitStatus.done) {
        pillarDone[habit.pillar] = (pillarDone[habit.pillar] ?? 0) + 1;
      }
    }
  }

  final List<HabitPillarWeekStat> byPillar = HabitPillar.values
      .map(
        (HabitPillar pillar) => HabitPillarWeekStat(
          pillar: pillar,
          done: pillarDone[pillar] ?? 0,
          possible: pillarPossible[pillar] ?? 0,
        ),
      )
      .where((HabitPillarWeekStat stat) => stat.possible > 0)
      .toList(growable: false);

  return HabitAdherenceSummary(
    done: done,
    possible: possible,
    daysCovered: withStatuses.length,
    byPillar: byPillar,
  );
}
