import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../health_profile/application/medications_providers.dart';
import '../../health_profile/domain/medication.dart';
import '../../routine/application/habit_providers.dart';
import '../../routine/application/routine_providers.dart';
import '../../routine/domain/dose_schedule.dart';
import '../../routine/domain/habit.dart';
import '../domain/progress_observations.dart';

/// What the Progress tab should show. Composes existing routine providers —
/// does not recalculate adherence percentages.
@immutable
class ProgressView {
  const ProgressView._({
    required this.isLoading,
    required this.error,
    required this.medicine,
    required this.lifestyle,
    required this.noMedicinesConfigured,
    required this.allHabitsDisabled,
    required this.medicineDayRecords,
    required this.lifestyleDayRecords,
    required this.observations,
  });

  const ProgressView.loading()
    : this._(
        isLoading: true,
        error: null,
        medicine: null,
        lifestyle: null,
        noMedicinesConfigured: false,
        allHabitsDisabled: false,
        medicineDayRecords: const <ProgressDayRecord>[],
        lifestyleDayRecords: const <ProgressDayRecord>[],
        observations: const <ProgressObservation>[],
      );

  const ProgressView.error(Object error)
    : this._(
        isLoading: false,
        error: error,
        medicine: null,
        lifestyle: null,
        noMedicinesConfigured: false,
        allHabitsDisabled: false,
        medicineDayRecords: const <ProgressDayRecord>[],
        lifestyleDayRecords: const <ProgressDayRecord>[],
        observations: const <ProgressObservation>[],
      );

  final bool isLoading;
  final Object? error;

  /// Authoritative medicine summary; null / !hasData → omit section.
  final AdherenceSummary? medicine;

  /// Authoritative lifestyle summary; null / !hasData → omit section.
  final HabitAdherenceSummary? lifestyle;

  final bool noMedicinesConfigured;
  final bool allHabitsDisabled;

  /// Oldest → newest local calendar days in the 7-day window.
  final List<ProgressDayRecord> medicineDayRecords;
  final List<ProgressDayRecord> lifestyleDayRecords;

  final List<ProgressObservation> observations;

  bool get hasError => error != null;

  bool get showMedicine => medicine != null && medicine!.hasData;

  bool get showLifestyle => lifestyle != null && lifestyle!.hasData;

  bool get isEmpty =>
      !isLoading &&
      !hasError &&
      !showMedicine &&
      !showLifestyle &&
      !allHabitsDisabled;

  /// No active habits and nothing else to show — explain, don't invent 0%.
  bool get showInactiveHabitsHint =>
      !isLoading &&
      !hasError &&
      allHabitsDisabled &&
      !showMedicine &&
      !showLifestyle;
}

/// Presentation-only: whether a calendar day has any recorded statuses.
@immutable
class ProgressDayRecord {
  const ProgressDayRecord({required this.dateKey, required this.hasRecord});

  final String dateKey;
  final bool hasRecord;
}

/// Builds the seven local calendar day keys for the adherence window
/// (oldest → newest), matching repository `watchRecent` windowing.
List<String> progressWindowDateKeys({
  DateTime? now,
  int windowDays = adherenceWindowDays,
}) {
  final DateTime today = now ?? DateTime.now();
  final DateTime start = DateTime(
    today.year,
    today.month,
    today.day,
  ).subtract(Duration(days: windowDays - 1));

  return List<String>.generate(windowDays, (int index) {
    final DateTime day = start.add(Duration(days: index));
    return DailyDoseLog.keyFor(day);
  });
}

/// Record / no-record flags for each day in the window (presentation only).
List<ProgressDayRecord> progressDayRecords({
  required Iterable<String> recordedDateKeys,
  DateTime? now,
  int windowDays = adherenceWindowDays,
}) {
  final Set<String> recorded = recordedDateKeys.toSet();
  return progressWindowDateKeys(now: now, windowDays: windowDays)
      .map(
        (String key) =>
            ProgressDayRecord(dateKey: key, hasRecord: recorded.contains(key)),
      )
      .toList(growable: false);
}

final progressViewProvider = Provider<ProgressView>((ref) {
  final AsyncValue<List<DailyDoseLog>> doseLogsAsync = ref.watch(
    recentDoseLogsProvider,
  );
  final AsyncValue<List<DailyHabitLog>> habitLogsAsync = ref.watch(
    recentHabitLogsProvider,
  );
  final AsyncValue<HabitPreferences> prefsAsync = ref.watch(
    habitPreferencesProvider,
  );
  final AsyncValue<MedicationRecord> medsAsync = ref.watch(medicationsProvider);

  if (_stillBooting(doseLogsAsync) ||
      _stillBooting(habitLogsAsync) ||
      _stillBooting(prefsAsync) ||
      _stillBooting(medsAsync)) {
    return const ProgressView.loading();
  }

  final Object? error =
      doseLogsAsync.error ??
      habitLogsAsync.error ??
      prefsAsync.error ??
      medsAsync.error;
  if (error != null) {
    return ProgressView.error(error);
  }

  final List<DailyDoseLog> doseLogs = doseLogsAsync.value ?? const [];
  final List<DailyHabitLog> habitLogs = habitLogsAsync.value ?? const [];
  final List<HabitItem> active = ref.watch(activeHabitsProvider);
  final DailySchedule schedule = ref.watch(dailyScheduleProvider);

  final AdherenceSummary? medicine = ref.watch(adherenceProvider);
  final HabitAdherenceSummary? lifestyle = ref.watch(habitAdherenceProvider);

  final AdherenceSummary? medicineForView = medicine != null && medicine.hasData
      ? medicine
      : null;
  final HabitAdherenceSummary? lifestyleForView =
      lifestyle != null && lifestyle.hasData ? lifestyle : null;

  final List<ProgressObservation> observations = buildProgressObservations(
    medicine: medicineForView,
    lifestyle: lifestyleForView,
    habitLogDaysInWindow: habitLogs.length,
  );

  return ProgressView._(
    isLoading: false,
    error: null,
    medicine: medicineForView,
    lifestyle: lifestyleForView,
    noMedicinesConfigured: schedule.doses.isEmpty,
    allHabitsDisabled: active.isEmpty,
    medicineDayRecords: progressDayRecords(
      recordedDateKeys: doseLogs
          .where((DailyDoseLog log) => log.statuses.isNotEmpty)
          .map((DailyDoseLog log) => log.dateKey),
    ),
    lifestyleDayRecords: progressDayRecords(
      recordedDateKeys: habitLogs
          .where((DailyHabitLog log) => log.statuses.isNotEmpty)
          .map((DailyHabitLog log) => log.dateKey),
    ),
    observations: observations,
  );
});

bool _stillBooting<T>(AsyncValue<T> value) =>
    value.isLoading && !value.hasValue && !value.hasError;
