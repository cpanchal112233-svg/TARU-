import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/routine/application/habit_providers.dart';
import 'package:mobile/features/routine/data/reminder_service.dart';
import 'package:mobile/features/routine/domain/habit.dart';

/// Behavioural verification for Phase 6 polish — domain/progress contracts
/// that Home and Routine both rely on.
void main() {
  group('habit catalogue (code-owned)', () {
    test('exactly eight habits with unique ids covering all pillars/slots', () {
      expect(defaultHabits, hasLength(8));
      expect(defaultHabits.map((h) => h.id).toSet(), hasLength(8));
      for (final HabitPillar pillar in HabitPillar.values) {
        expect(habitsFor(pillar), isNotEmpty);
      }
      for (final HabitSlot slot in HabitSlot.values) {
        expect(habitsInSlot(slot, defaultHabits), isNotEmpty);
      }
    });
  });

  group('habit preferences defaults and toggles', () {
    test('new / missing prefs document enables all eight', () {
      expect(HabitPreferences.fromMap(null).activeHabits, hasLength(8));
      expect(HabitPreferences.fromMap(<String, dynamic>{}).activeHabits, hasLength(8));
      expect(HabitPreferences.allEnabled.activeHabits, hasLength(8));
    });

    test('disabling one habit shrinks active list and progress denominator', () {
      final HabitPreferences prefs =
          HabitPreferences.allEnabled.copyWithEnabled('diet_water', false);

      expect(prefs.activeHabits, hasLength(7));
      expect(prefs.activeHabits.any((h) => h.id == 'diet_water'), isFalse);

      final DailyHabitLog log = DailyHabitLog(
        dateKey: '2026-08-09',
        statuses: <String, HabitStatus>{
          'diet_water': HabitStatus.done,
          'diet_plants': HabitStatus.done,
        },
      );

      // Historical done on a disabled habit must not count toward today.
      expect(log.doneCountFor(prefs.activeHabits), 1);

      final TodayRoutineProgress progress = TodayRoutineProgress(
        dosesTaken: 0,
        dosesTotal: 0,
        habitsDone: log.doneCountFor(prefs.activeHabits),
        habitsTotal: prefs.activeHabits.length,
      );
      expect(progress.summaryLine, 'Medicines 0/0 · Habits 1/7');
    });

    test('disabling multiple habits updates denominator', () {
      HabitPreferences prefs = HabitPreferences.allEnabled;
      for (final String id in <String>[
        'diet_water',
        'exercise_move',
        'mind_quiet',
      ]) {
        prefs = prefs.copyWithEnabled(id, false);
      }
      expect(prefs.activeHabits, hasLength(5));
    });

    test('disabling all habits is safe (no divide-by-zero)', () {
      HabitPreferences prefs = HabitPreferences.allEnabled;
      for (final HabitItem habit in defaultHabits) {
        prefs = prefs.copyWithEnabled(habit.id, false);
      }
      expect(prefs.activeHabits, isEmpty);

      final HabitAdherenceSummary summary = HabitAdherenceSummary.fromLogs(
        logs: <DailyHabitLog>[
          DailyHabitLog(
            dateKey: DailyHabitLog.keyFor(DateTime.now()),
            statuses: <String, HabitStatus>{
              'diet_water': HabitStatus.done,
            },
          ),
        ],
        activeHabits: prefs.activeHabits,
        windowDays: 7,
      );

      expect(summary.hasData, isFalse);
      expect(summary.rate, 0);
      expect(summary.percent, 0);
      expect(summary.byPillar, isEmpty);

      const TodayRoutineProgress progress = TodayRoutineProgress(
        dosesTaken: 1,
        dosesTotal: 2,
        habitsDone: 0,
        habitsTotal: 0,
      );
      expect(progress.total, 2);
      expect(progress.summaryLine, 'Medicines 1/2 · Habits 0/0');
    });

    test('re-enabling a habit restores it; historical done still readable', () {
      final HabitPreferences disabled =
          HabitPreferences.allEnabled.copyWithEnabled('sleep_hours', false);
      final HabitPreferences reenabled =
          disabled.copyWithEnabled('sleep_hours', true);

      expect(reenabled.isEnabled('sleep_hours'), isTrue);
      expect(reenabled.activeHabits, hasLength(8));

      final DailyHabitLog historical = DailyHabitLog(
        dateKey: '2026-08-01',
        statuses: <String, HabitStatus>{
          'sleep_hours': HabitStatus.done,
        },
      );

      // Prefs mutation never clears the log map.
      expect(historical.statusOf('sleep_hours'), HabitStatus.done);
      expect(historical.doneCountFor(reenabled.activeHabits), 1);
    });

    test('prefs toMap only stores enabled map — not habit catalogue text', () {
      final Map<String, dynamic> map = HabitPreferences.allEnabled
          .copyWithEnabled('exercise_break', false)
          .toMap();

      expect(map.keys, <String>['enabled']);
      expect(map['enabled'], isA<Map>());
      final Map<dynamic, dynamic> enabled = map['enabled'] as Map;
      expect(enabled.containsKey('exercise_break'), isTrue);
      expect(enabled['exercise_break'], isFalse);
      expect(map.containsKey('title'), isFalse);
      expect(map.containsKey('habits'), isFalse);
    });
  });

  group('progress source of truth', () {
    test('Home summaryLine matches approved format', () {
      expect(
        const TodayRoutineProgress(
          dosesTaken: 2,
          dosesTotal: 3,
          habitsDone: 4,
          habitsTotal: 6,
        ).summaryLine,
        'Medicines 2/3 · Habits 4/6',
      );
    });

    test('zero medicines still formats cleanly', () {
      expect(
        const TodayRoutineProgress(
          dosesTaken: 0,
          dosesTotal: 0,
          habitsDone: 4,
          habitsTotal: 6,
        ).summaryLine,
        'Medicines 0/0 · Habits 4/6',
      );
    });
  });

  group('weekly pillar summary', () {
    test('separates diet / exercise / sleep / mindfulness for active habits', () {
      final HabitAdherenceSummary summary = HabitAdherenceSummary.fromLogs(
        logs: <DailyHabitLog>[
          DailyHabitLog(
            dateKey: DailyHabitLog.keyFor(DateTime.now()),
            statuses: <String, HabitStatus>{
              'diet_water': HabitStatus.done,
              'diet_plants': HabitStatus.done,
              'exercise_move': HabitStatus.done,
              'sleep_wind_down': HabitStatus.skipped,
              'mind_quiet': HabitStatus.done,
            },
          ),
        ],
        activeHabits: defaultHabits,
        windowDays: 7,
      );

      expect(summary.byPillar.map((s) => s.pillar), containsAll(<HabitPillar>[
        HabitPillar.diet,
        HabitPillar.exercise,
        HabitPillar.sleep,
        HabitPillar.mindfulness,
      ]));

      HabitPillarWeekStat pillar(HabitPillar p) =>
          summary.byPillar.firstWhere((s) => s.pillar == p);

      expect(pillar(HabitPillar.diet).done, 2);
      expect(pillar(HabitPillar.exercise).done, 1);
      expect(pillar(HabitPillar.sleep).done, 0);
      expect(pillar(HabitPillar.mindfulness).done, 1);
    });

    test('disabled pillars drop out of the week breakdown', () {
      HabitPreferences prefs = HabitPreferences.allEnabled;
      for (final HabitItem habit in habitsFor(HabitPillar.sleep)) {
        prefs = prefs.copyWithEnabled(habit.id, false);
      }

      final HabitAdherenceSummary summary = HabitAdherenceSummary.fromLogs(
        logs: <DailyHabitLog>[
          DailyHabitLog(
            dateKey: DailyHabitLog.keyFor(DateTime.now()),
            statuses: <String, HabitStatus>{
              'sleep_hours': HabitStatus.done,
              'diet_water': HabitStatus.done,
            },
          ),
        ],
        activeHabits: prefs.activeHabits,
        windowDays: 7,
      );

      expect(
        summary.byPillar.any((s) => s.pillar == HabitPillar.sleep),
        isFalse,
      );
      expect(
        summary.byPillar.any((s) => s.pillar == HabitPillar.diet),
        isTrue,
      );
    });
  });

  group('time-of-day grouping', () {
    test('morning / day / evening partitions are disjoint and complete', () {
      final Set<String> morning = habitsInSlot(
        HabitSlot.morning,
        defaultHabits,
      ).map((h) => h.id).toSet();
      final Set<String> day = habitsInSlot(
        HabitSlot.day,
        defaultHabits,
      ).map((h) => h.id).toSet();
      final Set<String> evening = habitsInSlot(
        HabitSlot.evening,
        defaultHabits,
      ).map((h) => h.id).toSet();

      expect(morning.intersection(day), isEmpty);
      expect(day.intersection(evening), isEmpty);
      expect(morning.intersection(evening), isEmpty);
      expect(
        {...morning, ...day, ...evening},
        defaultHabits.map((h) => h.id).toSet(),
      );
    });
  });

  group('notifications architecture contracts', () {
    test('medicine cancelAll id range cannot include lifestyle id', () {
      const int medicineBase = 5000;
      final Set<int> medicineIds = <int>{
        for (int i = 0; i < 4; i++) medicineBase + i,
      };

      expect(medicineIds.contains(ReminderService.lifestyleReminderId), isFalse);
      expect(ReminderService.lifestyleReminderHour, 19);
    });
  });
}
