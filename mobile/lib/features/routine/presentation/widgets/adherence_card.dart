import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/routine_providers.dart';
import '../../domain/dose_schedule.dart';

/// How much of the last week's medicine was actually taken.
///
/// Deliberately understated: it is an estimate built from ticks the user
/// remembered to make, so it is framed as a record of what was logged rather
/// than a clinical adherence score to feel judged by.
class AdherenceCard extends ConsumerWidget {
  const AdherenceCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AdherenceSummary? summary = ref.watch(adherenceProvider);

    if (summary == null || !summary.hasData) return const SizedBox.shrink();

    final Color accent = summary.percent >= 80
        ? const Color(0xff16A34A)
        : summary.percent >= 50
        ? const Color(0xffD97706)
        : const Color(0xffB3261E);

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
          Row(
            children: [
              Text(
                summary.daysCovered == 1
                    ? 'TODAY'
                    : 'LAST ${summary.daysCovered} DAYS',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: Colors.grey.shade600,
                ),
              ),
              const Spacer(),
              Text(
                '${summary.percent}%',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: summary.rate,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${summary.taken} of about ${summary.expected} doses ticked off, '
            'counting from when you started tracking.',
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
