import 'package:flutter/foundation.dart';

import '../../routine/domain/dose_schedule.dart';

/// How the user picks a factual recording window for Evidence Brief.
enum EvidenceBriefPeriodPreset { last7, last30, last90, custom }

/// Inclusive local-calendar period for "what I recorded".
///
/// Matches existing TARU local-date semantics (no timezone redesign).
@immutable
class EvidenceBriefPeriod {
  const EvidenceBriefPeriod({
    required this.preset,
    required this.start,
    required this.end,
  });

  final EvidenceBriefPeriodPreset preset;

  /// Inclusive local calendar start (time-of-day ignored for membership).
  final DateTime start;

  /// Inclusive local calendar end (time-of-day ignored for membership).
  final DateTime end;

  /// Inclusive local window: today + the previous (days - 1) calendar days.
  ///
  /// Example: Last 7 days on 16 Aug = 10 Aug through 16 Aug inclusive.
  factory EvidenceBriefPeriod.lastDays(int days, {DateTime? now}) {
    assert(days >= 1, 'days must be >= 1');
    final DateTime today = _calendarDay(now ?? DateTime.now());
    final DateTime start = today.subtract(Duration(days: days - 1));
    final EvidenceBriefPeriodPreset preset = switch (days) {
      7 => EvidenceBriefPeriodPreset.last7,
      30 => EvidenceBriefPeriodPreset.last30,
      90 => EvidenceBriefPeriodPreset.last90,
      _ => EvidenceBriefPeriodPreset.custom,
    };
    return EvidenceBriefPeriod(preset: preset, start: start, end: today);
  }

  /// Inclusive custom range. Returns null when [end] is before [start].
  static EvidenceBriefPeriod? tryCustom({
    required DateTime start,
    required DateTime end,
  }) {
    final DateTime a = _calendarDay(start);
    final DateTime b = _calendarDay(end);
    if (b.isBefore(a)) return null;
    return EvidenceBriefPeriod(
      preset: EvidenceBriefPeriodPreset.custom,
      start: a,
      end: b,
    );
  }

  /// Inclusive custom range. Throws [ArgumentError] if end is before start.
  factory EvidenceBriefPeriod.custom({
    required DateTime start,
    required DateTime end,
  }) {
    final EvidenceBriefPeriod? period = tryCustom(start: start, end: end);
    if (period == null) {
      throw ArgumentError('Custom range end must be on or after start.');
    }
    return period;
  }

  int get dayCount => end.difference(start).inDays + 1;

  String get startKey => DailyDoseLog.keyFor(start);

  String get endKey => DailyDoseLog.keyFor(end);

  bool containsDateKey(String dateKey) =>
      dateKey.compareTo(startKey) >= 0 && dateKey.compareTo(endKey) <= 0;

  /// Instant membership using local calendar day of [instant].
  bool containsInstant(DateTime instant) {
    final String key = DailyDoseLog.keyFor(instant);
    return containsDateKey(key);
  }

  /// Days from [start] through today (inclusive), for repository window reads.
  int daysBackFromToday({DateTime? now}) {
    final DateTime today = _calendarDay(now ?? DateTime.now());
    if (start.isAfter(today)) return 1;
    return today.difference(start).inDays + 1;
  }

  /// Inclusive local start-of-day for Firestore `recordedAt >=` queries.
  DateTime get queryStartInclusive =>
      DateTime(start.year, start.month, start.day);

  /// Exclusive local start-of-day after [end] for Firestore `recordedAt <`.
  ///
  /// Keeps the user-facing end day fully inclusive without 23:59:59.999 hacks.
  DateTime get queryEndExclusive {
    final DateTime endDay = DateTime(end.year, end.month, end.day);
    return endDay.add(const Duration(days: 1));
  }

  String get label {
    return switch (preset) {
      EvidenceBriefPeriodPreset.last7 => 'Last 7 days',
      EvidenceBriefPeriodPreset.last30 => 'Last 30 days',
      EvidenceBriefPeriodPreset.last90 => 'Last 90 days',
      EvidenceBriefPeriodPreset.custom =>
        '${_formatDay(start)} – ${_formatDay(end)}',
    };
  }

  static DateTime _calendarDay(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static String _formatDay(DateTime date) {
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}
