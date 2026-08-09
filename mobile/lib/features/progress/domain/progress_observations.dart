import 'package:flutter/foundation.dart';

import '../../routine/domain/dose_schedule.dart';
import '../../routine/domain/habit.dart';

/// One short, factual Progress line. Templates only — no AI, no advice.
@immutable
class ProgressObservation {
  const ProgressObservation({required this.id, required this.text});

  final String id;
  final String text;
}

/// Builds at most two observations from existing summaries and log counts.
///
/// Medicine expected doses come from [AdherenceSummary], which projects from
/// the current schedule — copy says "about", never "prescribed historically".
List<ProgressObservation> buildProgressObservations({
  required AdherenceSummary? medicine,
  required HabitAdherenceSummary? lifestyle,
  required int habitLogDaysInWindow,
}) {
  final List<ProgressObservation> out = <ProgressObservation>[];

  if (medicine != null && medicine.hasData) {
    out.add(
      ProgressObservation(
        id: 'medicine_taken',
        text:
            '${medicine.taken} of about ${medicine.expected} doses logged as taken.',
      ),
    );
  }

  if (out.length < 2 && habitLogDaysInWindow > 0) {
    out.add(
      ProgressObservation(
        id: 'habit_log_days',
        text:
            'You logged habits on $habitLogDaysInWindow of the last 7 days.',
      ),
    );
  }

  if (out.length < 2 && lifestyle != null && lifestyle.hasData) {
    final HabitPillar? top = _uniqueTopPillar(lifestyle.byPillar);
    if (top != null) {
      out.add(
        ProgressObservation(
          id: 'top_pillar',
          text:
              '${top.label} was the most frequently completed lifestyle '
              'pillar this week.',
        ),
      );
    }
  }

  return List<ProgressObservation>.unmodifiable(out);
}

HabitPillar? _uniqueTopPillar(List<HabitPillarWeekStat> pillars) {
  if (pillars.isEmpty) return null;

  HabitPillarWeekStat? best;
  var tie = false;

  for (final HabitPillarWeekStat stat in pillars) {
    if (stat.done <= 0) continue;
    if (best == null || stat.done > best.done) {
      best = stat;
      tie = false;
    } else if (stat.done == best.done) {
      tie = true;
    }
  }

  if (best == null || tie) return null;
  return best.pillar;
}
