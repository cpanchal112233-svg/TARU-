import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/routine/application/habit_providers.dart';
import 'package:mobile/features/routine/domain/habit.dart';
import 'package:mobile/features/routine/data/reminder_service.dart';

void main() {
  group('defaultHabits', () {
    test('covers every pillar and slot with stable unique ids', () {
      expect(defaultHabits, isNotEmpty);

      final Set<String> ids = defaultHabits.map((HabitItem h) => h.id).toSet();
      expect(ids.length, defaultHabits.length);

      for (final HabitPillar pillar in HabitPillar.values) {
        expect(habitsFor(pillar), isNotEmpty);
      }

      for (final HabitSlot slot in HabitSlot.values) {
        expect(habitsInSlot(slot, defaultHabits), isNotEmpty);
      }
    });
  });

  group('HabitPreferences', () {
    test('missing document defaults every catalog habit to enabled', () {
      expect(HabitPreferences.allEnabled.activeHabits, defaultHabits);
      expect(HabitPreferences.fromMap(null).isEnabled('diet_water'), isTrue);
    });

    test('disabled habits drop out of activeHabits', () {
      final HabitPreferences prefs = HabitPreferences.allEnabled
          .copyWithEnabled('diet_water', false)
          .copyWithEnabled('mind_quiet', false);

      expect(prefs.isEnabled('diet_water'), isFalse);
      expect(prefs.activeHabits.length, defaultHabits.length - 2);
      expect(
        prefs.activeHabits.any((HabitItem h) => h.id == 'diet_water'),
        isFalse,
      );
    });

    test('round-trips through toMap/fromMap', () {
      final HabitPreferences original = HabitPreferences.allEnabled
          .copyWithEnabled('exercise_move', false);
      final HabitPreferences restored = HabitPreferences.fromMap(
        original.toMap(),
      );

      expect(restored.isEnabled('exercise_move'), isFalse);
      expect(restored.isEnabled('diet_water'), isTrue);
    });
  });

  group('DailyHabitLog', () {
    test('doneCountFor only counts the supplied habits', () {
      final DailyHabitLog log = DailyHabitLog(
        dateKey: '2026-08-09',
        statuses: <String, HabitStatus>{
          'diet_water': HabitStatus.done,
          'exercise_move': HabitStatus.done,
          'mind_quiet': HabitStatus.skipped,
        },
      );

      final List<HabitItem> active = defaultHabits
          .where((HabitItem h) => h.id != 'exercise_move')
          .toList();

      expect(log.doneCountFor(active), 1);
    });
  });

  group('ReminderService ids', () {
    test('lifestyle reminder id sits outside the medicine id range', () {
      // Medicine IDs are 5000 + DoseTime.index (0..3). Lifestyle must never
      // share that range so cancelAll cannot wipe the evening nudge.
      expect(ReminderService.lifestyleReminderId, greaterThanOrEqualTo(6000));
      expect(
        ReminderService.lifestyleReminderId,
        isNot(inInclusiveRange(5000, 5003)),
      );
    });
  });

  group('TodayRoutineProgress', () {
    test('summaryLine matches the Home / Routine compact format', () {
      const TodayRoutineProgress progress = TodayRoutineProgress(
        dosesTaken: 2,
        dosesTotal: 3,
        habitsDone: 4,
        habitsTotal: 6,
      );

      expect(progress.summaryLine, 'Medicines 2/3 · Habits 4/6');
    });

    test('supports zero medicines and all habits disabled', () {
      const TodayRoutineProgress emptyMeds = TodayRoutineProgress(
        dosesTaken: 0,
        dosesTotal: 0,
        habitsDone: 3,
        habitsTotal: 8,
      );
      const TodayRoutineProgress noHabits = TodayRoutineProgress(
        dosesTaken: 1,
        dosesTotal: 2,
        habitsDone: 0,
        habitsTotal: 0,
      );

      expect(emptyMeds.summaryLine, 'Medicines 0/0 · Habits 3/8');
      expect(noHabits.summaryLine, 'Medicines 1/2 · Habits 0/0');
    });
  });

  group('HabitAdherenceSummary', () {
    test('uses active habits only and reports pillars', () {
      final List<HabitItem> active = defaultHabits
          .where((HabitItem h) => h.pillar == HabitPillar.diet)
          .toList();

      final HabitAdherenceSummary summary = HabitAdherenceSummary.fromLogs(
        logs: <DailyHabitLog>[
          DailyHabitLog(
            dateKey: DailyHabitLog.keyFor(DateTime.now()),
            statuses: <String, HabitStatus>{
              'diet_water': HabitStatus.done,
              'exercise_move': HabitStatus.done,
            },
          ),
        ],
        activeHabits: active,
        windowDays: 7,
        asOf: DateTime.now(),
      );

      expect(summary.hasData, isTrue);
      expect(summary.daysCovered, 1);
      expect(summary.done, 1);
      expect(summary.possible, active.length);
      expect(summary.byPillar, hasLength(1));
      expect(summary.byPillar.first.pillar, HabitPillar.diet);
      expect(summary.byPillar.first.done, 1);
    });

    test('empty active habits produce no data', () {
      final HabitAdherenceSummary summary = HabitAdherenceSummary.fromLogs(
        logs: <DailyHabitLog>[
          DailyHabitLog(dateKey: DailyHabitLog.keyFor(DateTime.now())),
        ],
        activeHabits: const <HabitItem>[],
        windowDays: 7,
        asOf: DateTime.now(),
      );

      expect(summary.hasData, isFalse);
    });
  });
}
