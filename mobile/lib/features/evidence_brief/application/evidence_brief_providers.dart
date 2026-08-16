import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../auth/application/auth_providers.dart';
import '../../health_profile/application/allergies_providers.dart';
import '../../health_profile/application/conditions_providers.dart';
import '../../health_profile/application/medications_providers.dart';
import '../../health_profile/domain/allergy.dart';
import '../../health_profile/domain/medical_condition.dart';
import '../../health_profile/domain/medication.dart';
import '../../measurements/application/measurements_providers.dart';
import '../../measurements/domain/blood_pressure_measurement.dart';
import '../../measurements/domain/weight_measurement.dart';
import '../../reports/application/reports_providers.dart';
import '../../reports/domain/medical_report.dart';
import '../../routine/application/habit_providers.dart';
import '../../routine/application/routine_providers.dart';
import '../../routine/domain/dose_schedule.dart';
import '../../routine/domain/habit.dart';
import '../domain/evidence_brief.dart';
import '../domain/evidence_brief_period.dart';
import '../domain/evidence_brief_section_load.dart';
import '../domain/evidence_brief_sections.dart';
import '../domain/evidence_brief_text.dart';

class EvidenceBriefPeriodController extends Notifier<EvidenceBriefPeriod> {
  @override
  EvidenceBriefPeriod build() => EvidenceBriefPeriod.lastDays(7);

  void setPeriod(EvidenceBriefPeriod period) => state = period;
}

final evidenceBriefPeriodProvider =
    NotifierProvider<EvidenceBriefPeriodController, EvidenceBriefPeriod>(
      EvidenceBriefPeriodController.new,
    );

class EvidenceBriefNotesController extends Notifier<String> {
  @override
  String build() => '';

  void setNotes(String value) => state = value;
}

/// Ephemeral questions/notes — never persisted to Firestore.
final evidenceBriefNotesProvider =
    NotifierProvider<EvidenceBriefNotesController, String>(
      EvidenceBriefNotesController.new,
    );

class EvidenceBriefShareSelectionController
    extends Notifier<EvidenceBriefShareSelection> {
  @override
  EvidenceBriefShareSelection build() {
    ref.listen<EvidenceBrief>(evidenceBriefProvider, (
      EvidenceBrief? previous,
      EvidenceBrief next,
    ) {
      final bool periodChanged =
          previous == null || previous.period.label != next.period.label;
      if (periodChanged) {
        state = EvidenceBriefShareSelection.defaultsFor(next);
        return;
      }
      // Keep user choices, but force failed sections off.
      state = state.withoutFailedSections(next);
    });
    return const EvidenceBriefShareSelection();
  }

  void setSelection(EvidenceBriefShareSelection value) => state = value;

  void setSection(EvidenceBriefSectionId id, bool enabled) {
    final EvidenceBrief brief = ref.read(evidenceBriefProvider);
    if (enabled && !brief.loadFor(id).isShareable) return;
    state = state.withSection(id, enabled);
  }

  void resetToDefaults(EvidenceBrief brief) {
    state = EvidenceBriefShareSelection.defaultsFor(brief);
  }
}

final evidenceBriefShareSelectionProvider =
    NotifierProvider<
      EvidenceBriefShareSelectionController,
      EvidenceBriefShareSelection
    >(EvidenceBriefShareSelectionController.new);

/// Dose logs for the selected inclusive date-key window.
final evidenceBriefDoseLogsProvider = StreamProvider<List<DailyDoseLog>>((
  Ref ref,
) {
  final User? user = ref.watch(authStateChangesProvider).value;
  final EvidenceBriefPeriod period = ref.watch(evidenceBriefPeriodProvider);

  if (user == null) {
    return Stream<List<DailyDoseLog>>.value(const <DailyDoseLog>[]);
  }

  return ref
      .watch(doseLogRepositoryProvider)
      .watchDateKeyRange(
        user.uid,
        startKey: period.startKey,
        endKey: period.endKey,
      );
});

/// Habit logs for the selected inclusive date-key window.
final evidenceBriefHabitLogsProvider = StreamProvider<List<DailyHabitLog>>((
  Ref ref,
) {
  final User? user = ref.watch(authStateChangesProvider).value;
  final EvidenceBriefPeriod period = ref.watch(evidenceBriefPeriodProvider);

  if (user == null) {
    return Stream<List<DailyHabitLog>>.value(const <DailyHabitLog>[]);
  }

  return ref
      .watch(habitLogRepositoryProvider)
      .watchDateKeyRange(
        user.uid,
        startKey: period.startKey,
        endKey: period.endKey,
      );
});

/// Period-bounded weight history (existing measurements composite index).
final evidenceBriefWeightHistoryProvider =
    StreamProvider<List<WeightMeasurement>>((Ref ref) {
      final User? user = ref.watch(authStateChangesProvider).value;
      final EvidenceBriefPeriod period = ref.watch(evidenceBriefPeriodProvider);
      if (user == null) {
        return Stream<List<WeightMeasurement>>.value(
          const <WeightMeasurement>[],
        );
      }
      return ref
          .watch(measurementsRepositoryProvider)
          .watchWeightHistoryInRange(
            user.uid,
            startInclusive: period.queryStartInclusive,
            endExclusive: period.queryEndExclusive,
          );
    });

/// Period-bounded BP history (existing measurements composite index).
final evidenceBriefBloodPressureHistoryProvider =
    StreamProvider<List<BloodPressureMeasurement>>((Ref ref) {
      final User? user = ref.watch(authStateChangesProvider).value;
      final EvidenceBriefPeriod period = ref.watch(evidenceBriefPeriodProvider);
      if (user == null) {
        return Stream<List<BloodPressureMeasurement>>.value(
          const <BloodPressureMeasurement>[],
        );
      }
      return ref
          .watch(measurementsRepositoryProvider)
          .watchBloodPressureHistoryInRange(
            user.uid,
            startInclusive: period.queryStartInclusive,
            endExclusive: period.queryEndExclusive,
          );
    });

EvidenceBriefSectionLoad _loadFromAsync<T>({
  required AsyncValue<T> value,
  required bool Function(T data) isEmpty,
}) {
  if (_stillBooting(value)) return const EvidenceBriefSectionLoad.loading();
  if (value.hasError) {
    return EvidenceBriefSectionLoad.failed(value.error!);
  }
  final T? data = value.value;
  if (data == null) return const EvidenceBriefSectionLoad.empty();
  return isEmpty(data)
      ? const EvidenceBriefSectionLoad.empty()
      : const EvidenceBriefSectionLoad.ready();
}

EvidenceBriefSectionLoad _combineLoads(List<EvidenceBriefSectionLoad> loads) {
  if (loads.any((EvidenceBriefSectionLoad l) => l.isFailed)) {
    final Object error = loads
        .firstWhere((EvidenceBriefSectionLoad l) => l.isFailed)
        .error!;
    return EvidenceBriefSectionLoad.failed(error);
  }
  if (loads.any((EvidenceBriefSectionLoad l) => l.isLoading)) {
    return const EvidenceBriefSectionLoad.loading();
  }
  if (loads.every((EvidenceBriefSectionLoad l) => l.isEmpty)) {
    return const EvidenceBriefSectionLoad.empty();
  }
  return const EvidenceBriefSectionLoad.ready();
}

/// Assembles Evidence Brief with per-section load integrity.
final evidenceBriefProvider = Provider<EvidenceBrief>((Ref ref) {
  final EvidenceBriefPeriod period = ref.watch(evidenceBriefPeriodProvider);
  final String notes = ref.watch(evidenceBriefNotesProvider);
  final DateTime asOf = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );

  final AsyncValue<ConditionRecord> conditionsAsync = ref.watch(
    conditionsProvider,
  );
  final AsyncValue<AllergyRecord> allergiesAsync = ref.watch(allergiesProvider);
  final AsyncValue<MedicationRecord> medicationsAsync = ref.watch(
    medicationsProvider,
  );
  final AsyncValue<List<WeightMeasurement>> weightsAsync = ref.watch(
    evidenceBriefWeightHistoryProvider,
  );
  final AsyncValue<List<BloodPressureMeasurement>> bpAsync = ref.watch(
    evidenceBriefBloodPressureHistoryProvider,
  );
  final AsyncValue<List<MedicalReport>> reportsAsync = ref.watch(
    reportsProvider,
  );
  final AsyncValue<List<DailyDoseLog>> doseLogsAsync = ref.watch(
    evidenceBriefDoseLogsProvider,
  );
  final AsyncValue<List<DailyHabitLog>> habitLogsAsync = ref.watch(
    evidenceBriefHabitLogsProvider,
  );
  final AsyncValue<HabitPreferences> prefsAsync = ref.watch(
    habitPreferencesProvider,
  );

  final EvidenceBriefSectionLoad contextLoad =
      _combineLoads(<EvidenceBriefSectionLoad>[
        _loadFromAsync<ConditionRecord>(
          value: conditionsAsync,
          isEmpty: (ConditionRecord r) =>
              !r.hasAnswered && r.conditions.isEmpty,
        ),
        _loadFromAsync<AllergyRecord>(
          value: allergiesAsync,
          isEmpty: (AllergyRecord r) => !r.hasAnswered && r.allergies.isEmpty,
        ),
        _loadFromAsync<MedicationRecord>(
          value: medicationsAsync,
          isEmpty: (MedicationRecord r) =>
              !r.hasAnswered && r.medications.isEmpty,
        ),
      ]);

  final EvidenceBriefSectionLoad measurementsLoad =
      _combineLoads(<EvidenceBriefSectionLoad>[
        _loadFromAsync<List<WeightMeasurement>>(
          value: weightsAsync,
          isEmpty: (List<WeightMeasurement> items) => items.isEmpty,
        ),
        _loadFromAsync<List<BloodPressureMeasurement>>(
          value: bpAsync,
          isEmpty: (List<BloodPressureMeasurement> items) => items.isEmpty,
        ),
      ]);

  final EvidenceBriefSectionLoad reportsLoad =
      _loadFromAsync<List<MedicalReport>>(
        value: reportsAsync,
        isEmpty: (List<MedicalReport> items) =>
            reportsInPeriod(items, period).isEmpty,
      );

  // Medicine depends on dose logs + current schedule (medications).
  final EvidenceBriefSectionLoad medicineLoad =
      _combineLoads(<EvidenceBriefSectionLoad>[
        _loadFromAsync<List<DailyDoseLog>>(
          value: doseLogsAsync,
          isEmpty: (List<DailyDoseLog> logs) => logs.isEmpty,
        ),
        _loadFromAsync<MedicationRecord>(
          value: medicationsAsync,
          isEmpty: (_) => false,
        ),
      ]);

  final EvidenceBriefSectionLoad lifestyleLoad =
      _combineLoads(<EvidenceBriefSectionLoad>[
        _loadFromAsync<List<DailyHabitLog>>(
          value: habitLogsAsync,
          isEmpty: (List<DailyHabitLog> logs) => logs.isEmpty,
        ),
        _loadFromAsync<HabitPreferences>(
          value: prefsAsync,
          isEmpty: (_) => false,
        ),
      ]);

  final ConditionRecord conditions =
      conditionsAsync.value ?? ConditionRecord.empty;
  final AllergyRecord allergies = allergiesAsync.value ?? AllergyRecord.empty;
  final MedicationRecord medications =
      medicationsAsync.value ?? MedicationRecord.empty;
  final List<WeightMeasurement> weights =
      weightsAsync.value ?? const <WeightMeasurement>[];
  final List<BloodPressureMeasurement> bloodPressures =
      bpAsync.value ?? const <BloodPressureMeasurement>[];
  final List<MedicalReport> reports =
      reportsAsync.value ?? const <MedicalReport>[];
  final List<DailyDoseLog> doseLogs =
      doseLogsAsync.value ?? const <DailyDoseLog>[];
  final List<DailyHabitLog> habitLogs =
      habitLogsAsync.value ?? const <DailyHabitLog>[];
  final DailySchedule schedule = ref.watch(dailyScheduleProvider);
  final List<HabitItem> activeHabits = ref.watch(activeHabitsProvider);

  final List<MedicalReport> periodReports = reportsLoad.isShareable
      ? reportsInPeriod(reports, period)
      : const <MedicalReport>[];

  final EvidenceBriefRoutineSection routine =
      medicineLoad.isShareable || lifestyleLoad.isShareable
      ? buildRoutineSection(
          period: period,
          doseLogs: medicineLoad.isShareable
              ? doseLogs
              : const <DailyDoseLog>[],
          habitLogs: lifestyleLoad.isShareable
              ? habitLogs
              : const <DailyHabitLog>[],
          dosesPerDay: schedule.doses.length,
          activeHabits: activeHabits,
        )
      : const EvidenceBriefRoutineSection(
          medicine: null,
          lifestyle: null,
          noMedicinesConfigured: false,
          noActiveHabits: false,
          caveats: <String>[
            'Medicine expected doses use your current medicine schedule, not a '
                'historical prescription record.',
            'Routine figures are self-reported logs, not a clinical adherence score.',
            'Medicine and lifestyle are separate — there is no combined score.',
          ],
        );

  // Refine medicine/lifestyle empty vs ready from assembled routine.
  EvidenceBriefSectionLoad refinedMedicine = medicineLoad;
  if (medicineLoad.isShareable) {
    if (routine.noMedicinesConfigured) {
      refinedMedicine = const EvidenceBriefSectionLoad.empty();
    } else if (routine.medicine != null && routine.medicine!.hasData) {
      refinedMedicine = const EvidenceBriefSectionLoad.ready();
    } else {
      refinedMedicine = const EvidenceBriefSectionLoad.empty();
    }
  }

  EvidenceBriefSectionLoad refinedLifestyle = lifestyleLoad;
  if (lifestyleLoad.isShareable) {
    if (routine.noActiveHabits) {
      refinedLifestyle = const EvidenceBriefSectionLoad.empty();
    } else if (routine.lifestyle != null && routine.lifestyle!.hasData) {
      refinedLifestyle = const EvidenceBriefSectionLoad.ready();
    } else {
      refinedLifestyle = const EvidenceBriefSectionLoad.empty();
    }
  }

  EvidenceBriefSectionLoad refinedContext = contextLoad;
  if (contextLoad.isShareable) {
    refinedContext =
        (!contextLoad.isFailed &&
            (conditions.hasAnswered ||
                allergies.hasAnswered ||
                medications.hasAnswered ||
                conditions.conditions.isNotEmpty ||
                allergies.allergies.isNotEmpty ||
                medications.medications.isNotEmpty))
        ? const EvidenceBriefSectionLoad.ready()
        : const EvidenceBriefSectionLoad.empty();
  }

  EvidenceBriefSectionLoad refinedMeasurements = measurementsLoad;
  if (measurementsLoad.isShareable) {
    refinedMeasurements = weights.isEmpty && bloodPressures.isEmpty
        ? const EvidenceBriefSectionLoad.empty()
        : const EvidenceBriefSectionLoad.ready();
  }

  EvidenceBriefSectionLoad refinedReports = reportsLoad;
  if (reportsLoad.isShareable) {
    refinedReports = periodReports.isEmpty
        ? const EvidenceBriefSectionLoad.empty()
        : const EvidenceBriefSectionLoad.ready();
  }

  return EvidenceBrief(
    period: period,
    context: EvidenceBriefContextSection(
      conditions: conditions.conditions
          .map(
            (UserCondition c) => EvidenceBriefContextItem(
              label: c.displayName,
              detail: c.detailSummary,
            ),
          )
          .toList(growable: false),
      allergies: allergies.allergies
          .map(
            (UserAllergy a) => EvidenceBriefContextItem(
              label: a.displayName,
              detail: a.detailSummary,
            ),
          )
          .toList(growable: false),
      medicines: medications.medications
          .map(
            (UserMedication m) => EvidenceBriefContextItem(
              label: m.displayName,
              detail: m.scheduleSummary,
            ),
          )
          .toList(growable: false),
      conditionsAnswered: conditions.hasAnswered,
      allergiesAnswered: allergies.hasAnswered,
      medicinesAnswered: medications.hasAnswered,
      noKnownConditions: conditions.noKnownConditions,
      noKnownAllergies: allergies.noKnownAllergies,
      takesNoMedication: medications.takesNoMedication,
      asOf: asOf,
    ),
    measurements: EvidenceBriefMeasurementsSection(
      weights: refinedMeasurements.isShareable
          ? weights
          : const <WeightMeasurement>[],
      bloodPressures: refinedMeasurements.isShareable
          ? bloodPressures
          : const <BloodPressureMeasurement>[],
    ),
    reports: EvidenceBriefReportsSection(
      reports: periodReports
          .map((MedicalReport r) => EvidenceBriefReportItem(report: r))
          .toList(growable: false),
    ),
    routine: routine,
    notes: notes,
    createdAt: asOf,
    contextLoad: refinedContext,
    measurementsLoad: refinedMeasurements,
    reportsLoad: refinedReports,
    medicineLoad: refinedMedicine,
    lifestyleLoad: refinedLifestyle,
  );
});

/// Canonical share text for the current brief + selection (preview == share).
final evidenceBriefShareTextProvider = Provider<String>((Ref ref) {
  final EvidenceBrief brief = ref.watch(evidenceBriefProvider);
  final EvidenceBriefShareSelection selection = ref.watch(
    evidenceBriefShareSelectionProvider,
  );
  if (!selection.isShareableFor(brief)) return '';
  return formatEvidenceBriefText(brief, selection: selection);
});

/// True when every included data-backed section is trustworthy.
final evidenceBriefCanShareProvider = Provider<bool>((Ref ref) {
  final EvidenceBrief brief = ref.watch(evidenceBriefProvider);
  final EvidenceBriefShareSelection selection = ref.watch(
    evidenceBriefShareSelectionProvider,
  );
  return selection.isShareableFor(brief);
});

typedef EvidenceBriefShareInvoker =
    Future<ShareResultStatus> Function(String text);

/// Injectable share boundary — tests mock this; production uses share_plus.
final evidenceBriefShareInvokerProvider = Provider<EvidenceBriefShareInvoker>((
  Ref ref,
) {
  return (String text) async {
    final ShareResult result = await SharePlus.instance.share(
      ShareParams(text: text, subject: 'TARU Evidence Brief'),
    );
    return result.status;
  };
});

/// Opens the OS share sheet with the same text as Share Preview.
final shareEvidenceBriefProvider =
    Provider<Future<ShareResultStatus> Function()>((Ref ref) {
      return () async {
        final EvidenceBrief brief = ref.read(evidenceBriefProvider);
        final EvidenceBriefShareSelection selection = ref.read(
          evidenceBriefShareSelectionProvider,
        );
        if (!selection.isShareableFor(brief)) {
          throw StateError(
            'Turn off any section that could not load before sharing.',
          );
        }
        final String text = ref.read(evidenceBriefShareTextProvider);
        if (text.isEmpty) {
          throw StateError('Nothing selected to share yet.');
        }
        return ref.read(evidenceBriefShareInvokerProvider)(text);
      };
    });

/// Retries failed Evidence Brief data sources without restarting the app.
void retryEvidenceBriefSection(WidgetRef ref, EvidenceBriefSectionId id) {
  switch (id) {
    case EvidenceBriefSectionId.currentContext:
      ref.invalidate(conditionsProvider);
      ref.invalidate(allergiesProvider);
      ref.invalidate(medicationsProvider);
    case EvidenceBriefSectionId.measurements:
      ref.invalidate(evidenceBriefWeightHistoryProvider);
      ref.invalidate(evidenceBriefBloodPressureHistoryProvider);
    case EvidenceBriefSectionId.reports:
      ref.invalidate(reportsProvider);
    case EvidenceBriefSectionId.medicineRoutine:
      ref.invalidate(evidenceBriefDoseLogsProvider);
      ref.invalidate(medicationsProvider);
    case EvidenceBriefSectionId.lifestyleRoutine:
      ref.invalidate(evidenceBriefHabitLogsProvider);
      ref.invalidate(habitPreferencesProvider);
    case EvidenceBriefSectionId.notes:
      break;
  }
}

bool _stillBooting<T>(AsyncValue<T> value) =>
    value.isLoading && !value.hasValue && !value.hasError;
