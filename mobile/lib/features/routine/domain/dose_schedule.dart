import 'package:flutter/foundation.dart';

import '../../health_profile/domain/medication.dart';

/// What happened to a dose the user was due to take.
///
/// A dose with no status yet is simply outstanding: silence is not the same as
/// a missed dose, since the time may not have come round yet.
enum DoseStatus {
  taken('Taken'),
  skipped('Skipped');

  const DoseStatus(this.label);

  final String label;
}

/// The hour each part of the day means, used to order the list and to decide
/// when a reminder should fire.
///
/// These are sensible defaults rather than user settings; making them
/// adjustable is a later step, and the ordering here is what matters most.
extension DoseTimeSchedule on DoseTime {
  int get hour {
    switch (this) {
      case DoseTime.morning:
        return 8;
      case DoseTime.afternoon:
        return 13;
      case DoseTime.evening:
        return 18;
      case DoseTime.bedtime:
        return 22;
    }
  }

  String get clockLabel {
    final int display = hour > 12 ? hour - 12 : hour;
    final String suffix = hour >= 12 ? 'pm' : 'am';

    return '$display $suffix';
  }
}

/// One medicine due at one time of day.
@immutable
class ScheduledDose {
  const ScheduledDose({required this.medication, required this.time});

  final UserMedication medication;
  final DoseTime time;

  /// Stable identifier for this dose within a day.
  ///
  /// Built from the medicine rather than its position, so reordering the list
  /// or adding another medicine never reassigns yesterday's ticks. Anything
  /// that is not a letter or digit is stripped, since the key is used as a
  /// Firestore field name.
  String get key {
    final String name = medication.displayName.toLowerCase().replaceAll(
      RegExp('[^a-z0-9]'),
      '',
    );

    return '${medication.ingredient.name}_${name}_${time.name}';
  }
}

/// The medicines due today, and the ones that could not be scheduled.
@immutable
class DailySchedule {
  const DailySchedule({
    required this.doses,
    required this.needTimes,
    required this.notDaily,
  });

  factory DailySchedule.from(MedicationRecord record) {
    final List<ScheduledDose> doses = [];
    final List<UserMedication> needTimes = [];
    final List<UserMedication> notDaily = [];

    for (final UserMedication medication in record.medications) {
      final MedicationFrequency? frequency = medication.frequency;

      if (frequency == null || !frequency.isDaily) {
        notDaily.add(medication);
        continue;
      }

      if (medication.doseTimes.isEmpty) {
        needTimes.add(medication);
        continue;
      }

      for (final DoseTime time in medication.doseTimes) {
        doses.add(ScheduledDose(medication: medication, time: time));
      }
    }

    doses.sort((ScheduledDose a, ScheduledDose b) {
      final int byTime = a.time.hour.compareTo(b.time.hour);

      if (byTime != 0) return byTime;

      return a.medication.displayName.compareTo(b.medication.displayName);
    });

    return DailySchedule(
      doses: doses,
      needTimes: needTimes,
      notDaily: notDaily,
    );
  }

  static const DailySchedule empty = DailySchedule(
    doses: <ScheduledDose>[],
    needTimes: <UserMedication>[],
    notDaily: <UserMedication>[],
  );

  /// Every dose due today, earliest first.
  final List<ScheduledDose> doses;

  /// Daily medicines with no times chosen, so TARU cannot say when they are due.
  final List<UserMedication> needTimes;

  /// Weekly, monthly, alternate-day and as-needed medicines, which do not
  /// belong on a fixed daily checklist.
  final List<UserMedication> notDaily;

  bool get isEmpty => doses.isEmpty && needTimes.isEmpty && notDaily.isEmpty;

  List<ScheduledDose> at(DoseTime time) =>
      doses.where((ScheduledDose dose) => dose.time == time).toList();

  List<DoseTime> get activeTimes {
    final List<DoseTime> times = [];

    for (final DoseTime time in DoseTime.values) {
      if (doses.any((ScheduledDose dose) => dose.time == time)) {
        times.add(time);
      }
    }

    return times;
  }
}

/// What the user ticked off on one day.
@immutable
class DailyDoseLog {
  const DailyDoseLog({
    required this.dateKey,
    this.statuses = const <String, DoseStatus>{},
  });

  factory DailyDoseLog.fromMap(String dateKey, Map<String, dynamic> map) {
    final Object? raw = map['statuses'];

    final Map<String, DoseStatus> statuses = <String, DoseStatus>{};

    if (raw is Map) {
      raw.forEach((Object? key, Object? value) {
        if (key is! String || value is! String) return;

        for (final DoseStatus status in DoseStatus.values) {
          if (status.name == value) statuses[key] = status;
        }
      });
    }

    return DailyDoseLog(dateKey: dateKey, statuses: statuses);
  }

  /// The day this log belongs to, as `yyyy-MM-dd`.
  final String dateKey;

  final Map<String, DoseStatus> statuses;

  DoseStatus? statusOf(String doseKey) => statuses[doseKey];

  int get takenCount => statuses.values
      .where((DoseStatus status) => status == DoseStatus.taken)
      .length;

  static String keyFor(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

/// How much of the recent medicine actually got taken.
///
/// Past days are measured against today's schedule, because TARU only knows
/// the regimen as it stands now. That is an estimate, and the UI says so
/// rather than presenting it as a clinical adherence figure.
@immutable
class AdherenceSummary {
  const AdherenceSummary({
    required this.taken,
    required this.expected,
    required this.daysCovered,
  });

  /// Counts only the days since tracking actually began, capped at the window.
  ///
  /// Measuring a first-time user against a full week would show them a
  /// dispiriting single-digit percentage for doing nothing wrong, which is
  /// both untrue and the fastest way to make someone stop bothering.
  factory AdherenceSummary.fromLogs({
    required List<DailyDoseLog> logs,
    required int dosesPerDay,
    required int windowDays,
  }) {
    if (logs.isEmpty) {
      return const AdherenceSummary(taken: 0, expected: 0, daysCovered: 0);
    }

    int taken = 0;
    String earliest = logs.first.dateKey;

    for (final DailyDoseLog log in logs) {
      taken += log.takenCount;

      if (log.dateKey.compareTo(earliest) < 0) earliest = log.dateKey;
    }

    final DateTime? start = DateTime.tryParse(earliest);
    final DateTime today = DateTime.now();

    final int elapsed = start == null
        ? 1
        : today
                  .difference(DateTime(start.year, start.month, start.day))
                  .inDays +
              1;

    final int daysCovered = elapsed.clamp(1, windowDays);

    return AdherenceSummary(
      taken: taken,
      expected: dosesPerDay * daysCovered,
      daysCovered: daysCovered,
    );
  }

  final int taken;
  final int expected;

  /// How many days this figure is based on, so the UI can say so honestly.
  final int daysCovered;

  bool get hasData => expected > 0;

  double get rate => expected == 0 ? 0 : (taken / expected).clamp(0, 1);

  int get percent => (rate * 100).round();
}
