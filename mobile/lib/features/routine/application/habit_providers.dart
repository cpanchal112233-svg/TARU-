import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/firebase_providers.dart';
import '../../auth/application/auth_providers.dart';
import '../data/habit_log_repository.dart';
import '../data/habit_preferences_repository.dart';
import '../domain/dose_schedule.dart';
import '../domain/habit.dart';
import 'routine_providers.dart';

final habitLogRepositoryProvider = Provider<HabitLogRepository>(
  (ref) => HabitLogRepository(ref.watch(firestoreProvider)),
);

final habitPreferencesRepositoryProvider = Provider<HabitPreferencesRepository>(
  (ref) => HabitPreferencesRepository(ref.watch(firestoreProvider)),
);

final habitPreferencesProvider = StreamProvider<HabitPreferences>((ref) {
  final User? user = ref.watch(authStateChangesProvider).value;
  if (user == null) {
    return Stream<HabitPreferences>.value(HabitPreferences.allEnabled);
  }
  return ref.watch(habitPreferencesRepositoryProvider).watch(user.uid);
});

/// Catalog habits the user currently wants on today's list.
final activeHabitsProvider = Provider<List<HabitItem>>((ref) {
  final HabitPreferences prefs =
      ref.watch(habitPreferencesProvider).value ?? HabitPreferences.allEnabled;
  return prefs.activeHabits;
});

final todayHabitLogProvider = StreamProvider<DailyHabitLog>((ref) {
  final User? user = ref.watch(authStateChangesProvider).value;
  final String dateKey = ref.watch(todayKeyProvider);

  if (user == null) {
    return Stream<DailyHabitLog>.value(DailyHabitLog(dateKey: dateKey));
  }

  return ref.watch(habitLogRepositoryProvider).watchDay(user.uid, dateKey);
});

final recentHabitLogsProvider = StreamProvider<List<DailyHabitLog>>((ref) {
  final User? user = ref.watch(authStateChangesProvider).value;

  if (user == null) {
    return Stream<List<DailyHabitLog>>.value(const <DailyHabitLog>[]);
  }

  return ref
      .watch(habitLogRepositoryProvider)
      .watchRecent(user.uid, days: adherenceWindowDays);
});

final habitAdherenceProvider = Provider<HabitAdherenceSummary?>((ref) {
  final List<DailyHabitLog>? logs = ref.watch(recentHabitLogsProvider).value;
  if (logs == null) return null;

  final List<HabitItem> active = ref.watch(activeHabitsProvider);

  return HabitAdherenceSummary.fromLogs(
    logs: logs,
    activeHabits: active,
    windowDays: adherenceWindowDays,
  );
});

final setHabitStatusProvider =
    Provider<Future<void> Function(String, HabitStatus?)>((ref) {
      return (String habitId, HabitStatus? status) async {
        final User? user = ref.read(authStateChangesProvider).value;

        if (user == null) {
          throw StateError('Cannot record a habit while signed out.');
        }

        await ref
            .read(habitLogRepositoryProvider)
            .setStatus(user.uid, ref.read(todayKeyProvider), habitId, status);
      };
    });

final setHabitEnabledProvider =
    Provider<Future<void> Function(String habitId, bool enabled)>((ref) {
      return (String habitId, bool enabled) async {
        final User? user = ref.read(authStateChangesProvider).value;

        if (user == null) {
          throw StateError('Cannot save habit preferences while signed out.');
        }

        final HabitPreferences current =
            ref.read(habitPreferencesProvider).value ??
            HabitPreferences.allEnabled;

        await ref
            .read(habitPreferencesRepositoryProvider)
            .save(user.uid, current.copyWithEnabled(habitId, enabled));
      };
    });

/// Compact numbers for Home and Routine headers.
///
/// Single source of truth for "today" medicine + enabled-habit progress so
/// Home and Routine never drift apart.
@immutable
class TodayRoutineProgress {
  const TodayRoutineProgress({
    required this.dosesTaken,
    required this.dosesTotal,
    required this.habitsDone,
    required this.habitsTotal,
  });

  final int dosesTaken;
  final int dosesTotal;
  final int habitsDone;
  final int habitsTotal;

  int get completed => dosesTaken + habitsDone;
  int get total => dosesTotal + habitsTotal;
  bool get hasAnything => total > 0;

  /// Compact Home / header line, e.g. `Medicines 2/3 · Habits 4/6`.
  String get summaryLine =>
      'Medicines $dosesTaken/$dosesTotal · Habits $habitsDone/$habitsTotal';
}

final todayRoutineProgressProvider = Provider<TodayRoutineProgress>((ref) {
  final DailySchedule schedule = ref.watch(dailyScheduleProvider);
  final DailyDoseLog? doseLog = ref.watch(todayDoseLogProvider).value;
  final DailyHabitLog? habitLog = ref.watch(todayHabitLogProvider).value;
  final List<HabitItem> active = ref.watch(activeHabitsProvider);

  final int dosesTaken = schedule.doses
      .where(
        (ScheduledDose dose) =>
            doseLog?.statusOf(dose.key) == DoseStatus.taken,
      )
      .length;

  return TodayRoutineProgress(
    dosesTaken: dosesTaken,
    dosesTotal: schedule.doses.length,
    habitsDone: habitLog?.doneCountFor(active) ?? 0,
    habitsTotal: active.length,
  );
});
