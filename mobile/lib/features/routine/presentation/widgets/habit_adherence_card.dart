import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/habit_providers.dart';
import '../../domain/habit.dart';
import 'habit_section.dart';

/// Seven-day lifestyle completion with a light per-pillar split.
class HabitAdherenceCard extends ConsumerWidget {
  const HabitAdherenceCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final HabitAdherenceSummary? summary = ref.watch(habitAdherenceProvider);

    if (summary == null || !summary.hasData) {
      return const SizedBox.shrink();
    }

    const Color colour = Color(0xff2563EB);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lifestyle this week',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${summary.percent}% of enabled habits done across '
            '${summary.daysCovered} '
            '${summary.daysCovered == 1 ? 'day' : 'days'} '
            'since you started ticking them.',
            style: TextStyle(
              fontSize: 13.5,
              height: 1.4,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: summary.rate.clamp(0, 1),
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(colour),
            ),
          ),
          if (summary.byPillar.isNotEmpty) ...[
            const SizedBox(height: 14),
            for (final HabitPillarWeekStat stat in summary.byPillar)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      habitPillarIcon(stat.pillar),
                      size: 16,
                      color: habitPillarColor(stat.pillar),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 88,
                      child: Text(
                        stat.pillar.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: stat.rate.clamp(0, 1),
                          minHeight: 6,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            habitPillarColor(stat.pillar),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${stat.percent}%',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}
