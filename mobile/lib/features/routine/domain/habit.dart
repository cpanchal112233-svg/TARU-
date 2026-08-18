import 'package:flutter/foundation.dart';

/// The four lifestyle pillars Phase 6 adds on top of medicines.
enum HabitPillar {
  diet('Diet', 'Food and drink'),
  exercise('Exercise', 'Movement'),
  sleep('Sleep', 'Rest'),
  mindfulness('Mindfulness', 'Calm');

  const HabitPillar(this.label, this.subtitle);

  final String label;
  final String subtitle;
}

/// When a habit naturally belongs in the day. Used for Routine layout only —
/// not a notification schedule.
enum HabitSlot {
  morning('Morning', 'Start the day'),
  day('Day', 'Through the afternoon'),
  evening('Evening', 'Wind down');

  const HabitSlot(this.label, this.subtitle);

  final String label;
  final String subtitle;
}

/// Done / skipped mirrors medicine doses so a quiet day can be marked without
/// looking like a failure streak.
enum HabitStatus {
  done('Done'),
  skipped('Skipped');

  const HabitStatus(this.label);

  final String label;
}

/// One concrete daily action. Stable [id] keys Firestore fields.
@immutable
class HabitItem {
  const HabitItem({
    required this.id,
    required this.pillar,
    required this.slot,
    required this.title,
    required this.detail,
  });

  final String id;
  final HabitPillar pillar;
  final HabitSlot slot;
  final String title;
  final String detail;
}

/// The default checklist. Kept short so it sits beside medicines without
/// turning Routine into a second job.
const List<HabitItem> defaultHabits = <HabitItem>[
  HabitItem(
    id: 'diet_water',
    pillar: HabitPillar.diet,
    slot: HabitSlot.morning,
    title: 'Drink water through the day',
    detail: 'Keep a bottle nearby and finish most of it.',
  ),
  HabitItem(
    id: 'diet_plants',
    pillar: HabitPillar.diet,
    slot: HabitSlot.day,
    title: 'Eat fruit or vegetables',
    detail: 'At least one meal with plants on the plate.',
  ),
  HabitItem(
    id: 'exercise_move',
    pillar: HabitPillar.exercise,
    slot: HabitSlot.day,
    title: 'Move for 20 minutes',
    detail: 'A walk, stairs, stretch, or any activity that raises your pulse.',
  ),
  HabitItem(
    id: 'exercise_break',
    pillar: HabitPillar.exercise,
    slot: HabitSlot.day,
    title: 'Break up long sitting',
    detail: 'Stand and move for a minute or two a few times today.',
  ),
  HabitItem(
    id: 'sleep_wind_down',
    pillar: HabitPillar.sleep,
    slot: HabitSlot.evening,
    title: 'Wind down before bed',
    detail: 'Dim screens and slow the evening for a clearer night.',
  ),
  HabitItem(
    id: 'sleep_hours',
    pillar: HabitPillar.sleep,
    slot: HabitSlot.evening,
    title: 'Protect a sleep window',
    detail: 'Aim for a bedtime that leaves you enough hours tonight.',
  ),
  HabitItem(
    id: 'mind_quiet',
    pillar: HabitPillar.mindfulness,
    slot: HabitSlot.morning,
    title: 'Take five quiet minutes',
    detail: 'Breathe, sit still, or step outside without your phone.',
  ),
  HabitItem(
    id: 'mind_gratitude',
    pillar: HabitPillar.mindfulness,
    slot: HabitSlot.evening,
    title: 'Note one okay thing',
    detail: 'Something small that went alright today counts.',
  ),
];

HabitItem? habitById(String id) {
  for (final HabitItem habit in defaultHabits) {
    if (habit.id == id) return habit;
  }
  return null;
}

List<HabitItem> habitsFor(HabitPillar pillar) => defaultHabits
    .where((HabitItem habit) => habit.pillar == pillar)
    .toList(growable: false);

List<HabitItem> habitsInSlot(HabitSlot slot, List<HabitItem> habits) => habits
    .where((HabitItem habit) => habit.slot == slot)
    .toList(growable: false);

/// Which catalog habits the user wants on their daily list.
///
/// Missing entries default to enabled so existing users keep the full
/// checklist until they choose otherwise.
@immutable
class HabitPreferences {
  const HabitPreferences({this.enabledById = const <String, bool>{}});

  static const HabitPreferences allEnabled = HabitPreferences();

  final Map<String, bool> enabledById;

  bool isEnabled(String habitId) => enabledById[habitId] ?? true;

  List<HabitItem> get activeHabits => defaultHabits
      .where((HabitItem habit) => isEnabled(habit.id))
      .toList(growable: false);

  HabitPreferences copyWithEnabled(String habitId, bool enabled) {
    final Map<String, bool> next = Map<String, bool>.from(enabledById);
    next[habitId] = enabled;
    return HabitPreferences(enabledById: next);
  }

  Map<String, dynamic> toMap() {
    final Map<String, bool> enabled = <String, bool>{};
    for (final HabitItem habit in defaultHabits) {
      enabled[habit.id] = isEnabled(habit.id);
    }
    return <String, dynamic>{'enabled': enabled};
  }

  factory HabitPreferences.fromMap(Map<String, dynamic>? map) {
    if (map == null) return allEnabled;

    final Object? raw = map['enabled'];
    if (raw is! Map) return allEnabled;

    final Map<String, bool> enabled = <String, bool>{};
    raw.forEach((Object? key, Object? value) {
      if (key is String && value is bool) {
        enabled[key] = value;
      }
    });

    return HabitPreferences(enabledById: enabled);
  }
}

/// Today's ticks for lifestyle habits.
@immutable
class DailyHabitLog {
  const DailyHabitLog({
    required this.dateKey,
    this.statuses = const <String, HabitStatus>{},
  });

  final String dateKey;
  final Map<String, HabitStatus> statuses;

  HabitStatus? statusOf(String habitId) => statuses[habitId];

  int doneCountFor(Iterable<HabitItem> habits) {
    int count = 0;
    for (final HabitItem habit in habits) {
      if (statuses[habit.id] == HabitStatus.done) count += 1;
    }
    return count;
  }

  int get doneCount =>
      statuses.values.where((HabitStatus s) => s == HabitStatus.done).length;

  static String keyFor(DateTime date) {
    final String y = date.year.toString().padLeft(4, '0');
    final String m = date.month.toString().padLeft(2, '0');
    final String d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  factory DailyHabitLog.fromMap(String dateKey, Map<String, dynamic> map) {
    final Object? raw = map['statuses'];
    final Map<String, HabitStatus> statuses = <String, HabitStatus>{};

    if (raw is Map) {
      raw.forEach((Object? key, Object? value) {
        if (key is! String || value is! String) return;
        for (final HabitStatus status in HabitStatus.values) {
          if (status.name == value) {
            statuses[key] = status;
            break;
          }
        }
      });
    }

    return DailyHabitLog(dateKey: dateKey, statuses: statuses);
  }
}

@immutable
class HabitPillarWeekStat {
  const HabitPillarWeekStat({
    required this.pillar,
    required this.done,
    required this.possible,
  });

  final HabitPillar pillar;
  final int done;
  final int possible;

  double get rate => possible == 0 ? 0 : done / possible;

  int get percent => (rate * 100).round();
}

/// Seven-day habit completion for enabled habits only, with a light per-pillar
/// breakdown. Counts from the first day that has a log so a brand-new user is
/// not shown a misleadingly low percentage.
@immutable
class HabitAdherenceSummary {
  const HabitAdherenceSummary({
    required this.done,
    required this.possible,
    required this.daysCovered,
    required this.byPillar,
  });

  final int done;
  final int possible;
  final int daysCovered;
  final List<HabitPillarWeekStat> byPillar;

  bool get hasData => daysCovered > 0 && possible > 0;

  double get rate => possible == 0 ? 0 : done / possible;

  int get percent => (rate * 100).round();

  factory HabitAdherenceSummary.fromLogs({
    required List<DailyHabitLog> logs,
    required List<HabitItem> activeHabits,
    required int windowDays,
    required DateTime asOf,
  }) {
    if (activeHabits.isEmpty || logs.isEmpty) {
      return const HabitAdherenceSummary(
        done: 0,
        possible: 0,
        daysCovered: 0,
        byPillar: <HabitPillarWeekStat>[],
      );
    }

    final List<DailyHabitLog> sorted = List<DailyHabitLog>.from(logs)
      ..sort(
        (DailyHabitLog a, DailyHabitLog b) => a.dateKey.compareTo(b.dateKey),
      );

    final DateTime asOfDay = DateTime(asOf.year, asOf.month, asOf.day);
    final String today = DailyHabitLog.keyFor(asOfDay);
    final DateTime windowStart = asOfDay.subtract(
      Duration(days: windowDays - 1),
    );
    final String windowStartKey = DailyHabitLog.keyFor(windowStart);

    final List<DailyHabitLog> inWindow = sorted
        .where(
          (DailyHabitLog log) =>
              log.dateKey.compareTo(windowStartKey) >= 0 &&
              log.dateKey.compareTo(today) <= 0,
        )
        .toList();

    if (inWindow.isEmpty) {
      return const HabitAdherenceSummary(
        done: 0,
        possible: 0,
        daysCovered: 0,
        byPillar: <HabitPillarWeekStat>[],
      );
    }

    int done = 0;
    final Map<HabitPillar, int> pillarDone = <HabitPillar, int>{
      for (final HabitPillar pillar in HabitPillar.values) pillar: 0,
    };
    final Map<HabitPillar, int> pillarPossible = <HabitPillar, int>{
      for (final HabitPillar pillar in HabitPillar.values) pillar: 0,
    };

    for (final HabitItem habit in activeHabits) {
      pillarPossible[habit.pillar] =
          (pillarPossible[habit.pillar] ?? 0) + inWindow.length;
    }

    for (final DailyHabitLog log in inWindow) {
      for (final HabitItem habit in activeHabits) {
        if (log.statusOf(habit.id) == HabitStatus.done) {
          done += 1;
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
      possible: activeHabits.length * inWindow.length,
      daysCovered: inWindow.length,
      byPillar: byPillar,
    );
  }
}
