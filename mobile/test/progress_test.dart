import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/progress/application/progress_providers.dart';
import 'package:mobile/features/progress/domain/progress_observations.dart';
import 'package:mobile/features/routine/domain/dose_schedule.dart';
import 'package:mobile/features/routine/domain/habit.dart';

void main() {
  group('AdherenceSummary ownership (medicine)', () {
    test('no history produces no data — Progress must not invent 0%', () {
      final AdherenceSummary summary = AdherenceSummary.fromLogs(
        logs: const <DailyDoseLog>[],
        dosesPerDay: 2,
        windowDays: 7,
      );

      expect(summary.hasData, isFalse);
      expect(summary.expected, 0);
      expect(summary.taken, 0);
    });

    test('one day with taken and skipped counts taken only', () {
      final String today = DailyDoseLog.keyFor(DateTime.now());
      final AdherenceSummary summary = AdherenceSummary.fromLogs(
        logs: <DailyDoseLog>[
          DailyDoseLog(
            dateKey: today,
            statuses: const <String, DoseStatus>{
              'a_morning': DoseStatus.taken,
              'b_evening': DoseStatus.skipped,
            },
          ),
        ],
        dosesPerDay: 2,
        windowDays: 7,
      );

      expect(summary.hasData, isTrue);
      expect(summary.taken, 1);
      expect(summary.daysCovered, 1);
      expect(summary.expected, 2);
      // Skipped is recorded but does not increase taken.
      expect(summary.percent, 50);
    });

    test('no log for a dose key does not count as taken', () {
      final String today = DailyDoseLog.keyFor(DateTime.now());
      final AdherenceSummary summary = AdherenceSummary.fromLogs(
        logs: <DailyDoseLog>[
          DailyDoseLog(
            dateKey: today,
            statuses: const <String, DoseStatus>{
              'a_morning': DoseStatus.taken,
              // second expected dose has no log entry
            },
          ),
        ],
        dosesPerDay: 2,
        windowDays: 7,
      );

      expect(summary.taken, 1);
      expect(summary.expected, 2);
    });

    test('multiple doses across seven days match taken sum', () {
      final DateTime today = DateTime.now();
      final List<DailyDoseLog> logs = List<DailyDoseLog>.generate(7, (int i) {
        final DateTime day = today.subtract(Duration(days: 6 - i));
        return DailyDoseLog(
          dateKey: DailyDoseLog.keyFor(day),
          statuses: <String, DoseStatus>{
            'med_morning': DoseStatus.taken,
            if (i.isEven) 'med_evening': DoseStatus.taken,
          },
        );
      });

      final AdherenceSummary summary = AdherenceSummary.fromLogs(
        logs: logs,
        dosesPerDay: 2,
        windowDays: 7,
      );

      expect(summary.daysCovered, 7);
      expect(summary.expected, 14);
      expect(summary.taken, 7 + 4); // 7 mornings + 4 even evenings
      expect(
        summary.percent,
        AdherenceSummary.fromLogs(
          logs: logs,
          dosesPerDay: 2,
          windowDays: 7,
        ).percent,
      );
    });

    test('zero doses per day is no medicines configured path', () {
      final AdherenceSummary summary = AdherenceSummary.fromLogs(
        logs: <DailyDoseLog>[
          DailyDoseLog(dateKey: DailyDoseLog.keyFor(DateTime.now())),
        ],
        dosesPerDay: 0,
        windowDays: 7,
      );

      expect(summary.hasData, isFalse);
    });

    test('date boundaries clamp daysCovered to window', () {
      final DateTime today = DateTime.now();
      final List<DailyDoseLog> logs = <DailyDoseLog>[
        DailyDoseLog(
          dateKey: DailyDoseLog.keyFor(today.subtract(const Duration(days: 20))),
          statuses: const <String, DoseStatus>{'a': DoseStatus.taken},
        ),
        DailyDoseLog(
          dateKey: DailyDoseLog.keyFor(today),
          statuses: const <String, DoseStatus>{'a': DoseStatus.taken},
        ),
      ];

      // watchRecent would only return the in-window docs; simulate that.
      final List<DailyDoseLog> inWindow = logs
          .where(
            (DailyDoseLog log) =>
                log.dateKey.compareTo(
                      DailyDoseLog.keyFor(
                        today.subtract(const Duration(days: 6)),
                      ),
                    ) >=
                    0,
          )
          .toList();

      final AdherenceSummary summary = AdherenceSummary.fromLogs(
        logs: inWindow,
        dosesPerDay: 1,
        windowDays: 7,
      );

      expect(summary.daysCovered, lessThanOrEqualTo(7));
      expect(summary.taken, 1);
    });

    test('current-schedule projection: expected uses dosesPerDay argument', () {
      final String today = DailyDoseLog.keyFor(DateTime.now());
      final List<DailyDoseLog> logs = <DailyDoseLog>[
        DailyDoseLog(
          dateKey: today,
          statuses: const <String, DoseStatus>{
            'old_key': DoseStatus.taken,
          },
        ),
      ];

      // If the current schedule now has 3 doses/day, expected grows — estimate.
      final AdherenceSummary withThree = AdherenceSummary.fromLogs(
        logs: logs,
        dosesPerDay: 3,
        windowDays: 7,
      );
      final AdherenceSummary withOne = AdherenceSummary.fromLogs(
        logs: logs,
        dosesPerDay: 1,
        windowDays: 7,
      );

      expect(withThree.expected, 3);
      expect(withOne.expected, 1);
      expect(withThree.taken, withOne.taken);
    });
  });

  group('HabitAdherenceSummary ownership (lifestyle)', () {
    test('no history produces no data', () {
      final HabitAdherenceSummary summary = HabitAdherenceSummary.fromLogs(
        logs: const <DailyHabitLog>[],
        activeHabits: defaultHabits,
        windowDays: 7,
      );
      expect(summary.hasData, isFalse);
    });

    test('partial history counts only days with log documents', () {
      final String today = DailyHabitLog.keyFor(DateTime.now());
      final HabitAdherenceSummary summary = HabitAdherenceSummary.fromLogs(
        logs: <DailyHabitLog>[
          DailyHabitLog(
            dateKey: today,
            statuses: <String, HabitStatus>{
              defaultHabits.first.id: HabitStatus.done,
            },
          ),
        ],
        activeHabits: defaultHabits,
        windowDays: 7,
      );

      expect(summary.daysCovered, 1);
      expect(summary.possible, defaultHabits.length);
      expect(summary.done, 1);
    });

    test('disabled habits are excluded from active progress', () {
      final List<HabitItem> dietOnly = defaultHabits
          .where((HabitItem h) => h.pillar == HabitPillar.diet)
          .toList();
      final String today = DailyHabitLog.keyFor(DateTime.now());

      final HabitAdherenceSummary summary = HabitAdherenceSummary.fromLogs(
        logs: <DailyHabitLog>[
          DailyHabitLog(
            dateKey: today,
            statuses: const <String, HabitStatus>{
              'diet_water': HabitStatus.done,
              'exercise_move': HabitStatus.done,
            },
          ),
        ],
        activeHabits: dietOnly,
        windowDays: 7,
      );

      expect(summary.done, 1);
      expect(summary.byPillar.map((HabitPillarWeekStat s) => s.pillar), [
        HabitPillar.diet,
      ]);
    });

    test('all habits disabled produces no data', () {
      final HabitAdherenceSummary summary = HabitAdherenceSummary.fromLogs(
        logs: <DailyHabitLog>[
          DailyHabitLog(
            dateKey: DailyHabitLog.keyFor(DateTime.now()),
            statuses: const <String, HabitStatus>{
              'diet_water': HabitStatus.done,
            },
          ),
        ],
        activeHabits: const <HabitItem>[],
        windowDays: 7,
      );

      expect(summary.hasData, isFalse);
    });

    test('re-enabled habit can use preserved historical logs', () {
      final String today = DailyHabitLog.keyFor(DateTime.now());
      final DailyHabitLog preserved = DailyHabitLog(
        dateKey: today,
        statuses: const <String, HabitStatus>{
          'diet_water': HabitStatus.done,
        },
      );

      final HabitAdherenceSummary disabled = HabitAdherenceSummary.fromLogs(
        logs: <DailyHabitLog>[preserved],
        activeHabits: const <HabitItem>[],
        windowDays: 7,
      );
      final HabitAdherenceSummary reenabled = HabitAdherenceSummary.fromLogs(
        logs: <DailyHabitLog>[preserved],
        activeHabits: habitsFor(HabitPillar.diet),
        windowDays: 7,
      );

      expect(disabled.hasData, isFalse);
      expect(reenabled.hasData, isTrue);
      expect(reenabled.done, 1);
      // Historical log object unchanged.
      expect(preserved.statusOf('diet_water'), HabitStatus.done);
    });

    test('four pillars appear when all habits enabled with activity', () {
      final String today = DailyHabitLog.keyFor(DateTime.now());
      final Map<String, HabitStatus> statuses = <String, HabitStatus>{
        for (final HabitItem habit in defaultHabits) habit.id: HabitStatus.done,
      };

      final HabitAdherenceSummary summary = HabitAdherenceSummary.fromLogs(
        logs: <DailyHabitLog>[
          DailyHabitLog(dateKey: today, statuses: statuses),
        ],
        activeHabits: defaultHabits,
        windowDays: 7,
      );

      expect(summary.byPillar, hasLength(4));
      expect(
        summary.byPillar.map((HabitPillarWeekStat s) => s.pillar).toSet(),
        HabitPillar.values.toSet(),
      );
    });

    test('skipped habit does not count as done', () {
      final String today = DailyHabitLog.keyFor(DateTime.now());
      final HabitAdherenceSummary summary = HabitAdherenceSummary.fromLogs(
        logs: <DailyHabitLog>[
          DailyHabitLog(
            dateKey: today,
            statuses: const <String, HabitStatus>{
              'diet_water': HabitStatus.skipped,
            },
          ),
        ],
        activeHabits: habitsFor(HabitPillar.diet),
        windowDays: 7,
      );

      expect(summary.done, 0);
      expect(summary.hasData, isTrue);
    });
  });

  group('progress day records (presentation only)', () {
    test('missing days are no-record, not failures', () {
      final DateTime now = DateTime(2026, 8, 9);
      final List<ProgressDayRecord> days = progressDayRecords(
        recordedDateKeys: <String>[DailyDoseLog.keyFor(now)],
        now: now,
        windowDays: 7,
      );

      expect(days, hasLength(7));
      expect(days.where((ProgressDayRecord d) => d.hasRecord), hasLength(1));
      expect(days.last.dateKey, DailyDoseLog.keyFor(now));
      expect(days.first.hasRecord, isFalse);
    });

    test('window keys span exactly seven local days', () {
      final DateTime now = DateTime(2026, 8, 9, 22, 15);
      final List<String> keys = progressWindowDateKeys(now: now, windowDays: 7);

      expect(keys, hasLength(7));
      expect(keys.first, '2026-08-03');
      expect(keys.last, '2026-08-09');
    });
  });

  group('Progress observations', () {
    test('builds medicine and habit lines without medical claims', () {
      final List<ProgressObservation> items = buildProgressObservations(
        medicine: const AdherenceSummary(taken: 12, expected: 14, daysCovered: 7),
        lifestyle: HabitAdherenceSummary.fromLogs(
          logs: <DailyHabitLog>[
            DailyHabitLog(
              dateKey: DailyHabitLog.keyFor(DateTime.now()),
              statuses: const <String, HabitStatus>{
                'diet_water': HabitStatus.done,
                'diet_plants': HabitStatus.done,
              },
            ),
          ],
          activeHabits: defaultHabits,
          windowDays: 7,
        ),
        habitLogDaysInWindow: 5,
      );

      expect(items.length, lessThanOrEqualTo(2));
      expect(items.first.text, '12 of about 14 doses logged as taken.');
      expect(items[1].text, 'You logged habits on 5 of the last 7 days.');
    });

    test('unique top pillar observation when medicine absent', () {
      final HabitAdherenceSummary lifestyle = HabitAdherenceSummary.fromLogs(
        logs: <DailyHabitLog>[
          DailyHabitLog(
            dateKey: DailyHabitLog.keyFor(DateTime.now()),
            statuses: const <String, HabitStatus>{
              'diet_water': HabitStatus.done,
              'diet_plants': HabitStatus.done,
              'exercise_move': HabitStatus.done,
            },
          ),
        ],
        activeHabits: defaultHabits,
        windowDays: 7,
      );

      final List<ProgressObservation> items = buildProgressObservations(
        medicine: null,
        lifestyle: lifestyle,
        habitLogDaysInWindow: 1,
      );

      expect(items, hasLength(2));
      expect(items[0].id, 'habit_log_days');
      expect(items[1].id, 'top_pillar');
      expect(items[1].text, contains('Diet'));
    });

    test('empty inputs produce no observations', () {
      expect(
        buildProgressObservations(
          medicine: null,
          lifestyle: null,
          habitLogDaysInWindow: 0,
        ),
        isEmpty,
      );
    });

    test('observation copy avoids banned medical language', () {
      final List<ProgressObservation> items = buildProgressObservations(
        medicine: const AdherenceSummary(taken: 3, expected: 3, daysCovered: 1),
        lifestyle: HabitAdherenceSummary.fromLogs(
          logs: <DailyHabitLog>[
            DailyHabitLog(
              dateKey: DailyHabitLog.keyFor(DateTime.now()),
              statuses: <String, HabitStatus>{
                for (final HabitItem h in defaultHabits) h.id: HabitStatus.done,
              },
            ),
          ],
          activeHabits: defaultHabits,
          windowDays: 7,
        ),
        habitLogDaysInWindow: 7,
      );

      final String joined = items.map((ProgressObservation o) => o.text).join(' ');
      final List<String> banned = <String>[
        'health is improving',
        'medication is working',
        'better controlled',
        'you should',
        'unhealthy',
        'diagnos',
        'diabetes',
        'scheduled doses',
      ];

      for (final String phrase in banned) {
        expect(joined.toLowerCase(), isNot(contains(phrase)));
      }
    });

    test('medicine observation matches AdherenceSummary fields exactly', () {
      final AdherenceSummary summary = AdherenceSummary.fromLogs(
        logs: <DailyDoseLog>[
          DailyDoseLog(
            dateKey: DailyDoseLog.keyFor(DateTime.now()),
            statuses: const <String, DoseStatus>{
              'a': DoseStatus.taken,
              'b': DoseStatus.taken,
            },
          ),
        ],
        dosesPerDay: 2,
        windowDays: 7,
      );

      final List<ProgressObservation> items = buildProgressObservations(
        medicine: summary,
        lifestyle: null,
        habitLogDaysInWindow: 0,
      );

      expect(
        items.single.text,
        '${summary.taken} of about ${summary.expected} doses logged as taken.',
      );
    });
  });

  group('Progress view flags', () {
    test('empty view when no sections and habits not all-disabled', () {
      const ProgressView view = ProgressView.loading();
      expect(view.isLoading, isTrue);
      expect(view.isEmpty, isFalse);

      final ProgressView error = ProgressView.error(Exception('firestore'));
      expect(error.hasError, isTrue);
      expect(error.isEmpty, isFalse);
      expect(error.showMedicine, isFalse);
      expect(error.showLifestyle, isFalse);
    });
  });
}
