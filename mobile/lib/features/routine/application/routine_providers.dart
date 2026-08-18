import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/firebase_providers.dart';
import '../../auth/application/auth_providers.dart';
import '../../health_profile/application/medications_providers.dart';
import '../../health_profile/domain/medication.dart';
import '../data/dose_log_repository.dart';
import '../domain/dose_schedule.dart';

/// How many days the adherence summary looks back over.
const int adherenceWindowDays = 7;

final doseLogRepositoryProvider = Provider<DoseLogRepository>(
  (ref) => DoseLogRepository(ref.watch(firestoreProvider)),
);

/// Today's date key. Read at build time, so a session left open overnight
/// keeps yesterday's list until the app is reopened.
final todayKeyProvider = Provider<String>(
  (ref) => DailyDoseLog.keyFor(DateTime.now()),
);

final dailyScheduleProvider = Provider<DailySchedule>((ref) {
  final MedicationRecord? record = ref.watch(medicationsProvider).value;

  if (record == null) return DailySchedule.empty;

  return DailySchedule.from(record);
});

final todayDoseLogProvider = StreamProvider<DailyDoseLog>((ref) {
  final User? user = ref.watch(authStateChangesProvider).value;
  final String dateKey = ref.watch(todayKeyProvider);

  if (user == null) {
    return Stream<DailyDoseLog>.value(DailyDoseLog(dateKey: dateKey));
  }

  return ref.watch(doseLogRepositoryProvider).watchDay(user.uid, dateKey);
});

final recentDoseLogsProvider = StreamProvider<List<DailyDoseLog>>((ref) {
  final User? user = ref.watch(authStateChangesProvider).value;

  if (user == null) return Stream<List<DailyDoseLog>>.value(const []);

  return ref
      .watch(doseLogRepositoryProvider)
      .watchRecent(user.uid, days: adherenceWindowDays);
});

final adherenceProvider = Provider<AdherenceSummary?>((ref) {
  final List<DailyDoseLog>? logs = ref.watch(recentDoseLogsProvider).value;

  if (logs == null) return null;

  final DailySchedule schedule = ref.watch(dailyScheduleProvider);

  if (schedule.doses.isEmpty) return null;

  return AdherenceSummary.fromLogs(
    logs: logs,
    dosesPerDay: schedule.doses.length,
    windowDays: adherenceWindowDays,
    asOf: DateTime.now(),
  );
});

final setDoseStatusProvider =
    Provider<Future<void> Function(String, DoseStatus?)>((ref) {
      return (String doseKey, DoseStatus? status) async {
        final User? user = ref.read(authStateChangesProvider).value;

        if (user == null) {
          throw StateError('Cannot record a dose while signed out.');
        }

        await ref
            .read(doseLogRepositoryProvider)
            .setStatus(user.uid, ref.read(todayKeyProvider), doseKey, status);
      };
    });
