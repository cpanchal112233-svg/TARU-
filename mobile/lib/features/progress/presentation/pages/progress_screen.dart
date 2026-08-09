import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../health_profile/application/medications_providers.dart';
import '../../../measurements/presentation/widgets/latest_weight_card.dart';
import '../../../routine/application/habit_providers.dart';
import '../../../routine/application/routine_providers.dart';
import '../../../routine/domain/dose_schedule.dart';
import '../../../routine/domain/habit.dart';
import '../../../routine/presentation/widgets/habit_section.dart';
import '../../application/progress_providers.dart';
import '../../domain/progress_observations.dart';

/// Reviews the last 7 days of recorded medicine and lifestyle activity.
///
/// Composes existing adherence providers — does not invent a health score or
/// a second adherence formula.
class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key, this.onSelectTab});

  /// Switches the parent [MainShell] tab. Routine is index 2.
  final ValueChanged<int>? onSelectTab;

  static const int routineTabIndex = 2;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ProgressView view = ref.watch(progressViewProvider);

    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: AppBar(
        title: const Text('Progress'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: _buildBody(context, ref, view),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, ProgressView view) {
    if (view.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (view.hasError) {
      return _ErrorState(
        onRetry: () {
          ref.invalidate(recentDoseLogsProvider);
          ref.invalidate(recentHabitLogsProvider);
          ref.invalidate(habitPreferencesProvider);
          ref.invalidate(medicationsProvider);
        },
      );
    }

    if (view.isEmpty) {
      return Column(
        children: [
          Expanded(
            child: _EmptyState(
              onOpenRoutine: () => onSelectTab?.call(routineTabIndex),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: LatestWeightCard(),
          ),
        ],
      );
    }

    if (view.showInactiveHabitsHint) {
      return Column(
        children: [
          Expanded(
            child: _InactiveHabitsState(
              onOpenRoutine: () => onSelectTab?.call(routineTabIndex),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: LatestWeightCard(),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        Text(
          'Last 7 days',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Colors.grey.shade900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Review of what you recorded in TARU — not a medical assessment.',
          style: TextStyle(
            fontSize: 14,
            height: 1.4,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 20),
        if (view.showMedicine) ...[
          _MedicineSection(
            summary: view.medicine!,
            dayRecords: view.medicineDayRecords,
          ),
          const SizedBox(height: 16),
        ],
        if (view.showLifestyle) ...[
          _LifestyleSection(
            summary: view.lifestyle!,
            dayRecords: view.lifestyleDayRecords,
          ),
          const SizedBox(height: 16),
        ],
        if (view.allHabitsDisabled && view.showMedicine) ...[
          _HintCard(
            text:
                'No lifestyle habits are currently active. Turn habits on in '
                'Routine to track them here.',
          ),
          const SizedBox(height: 16),
        ],
        if (view.observations.isNotEmpty) ...[
          _ObservationsSection(observations: view.observations),
          const SizedBox(height: 16),
        ],
        const LatestWeightCard(),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => onSelectTab?.call(routineTabIndex),
          child: const Text('Open Routine'),
        ),
      ],
    );
  }
}

class _MedicineSection extends StatelessWidget {
  const _MedicineSection({required this.summary, required this.dayRecords});

  final AdherenceSummary summary;
  final List<ProgressDayRecord> dayRecords;

  @override
  Widget build(BuildContext context) {
    final Color accent = _accentFor(summary.percent);

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Medicines',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade900,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                '${summary.percent}%',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: accent,
                ),
              ),
              const Spacer(),
              Text(
                summary.daysCovered == 1
                    ? 'From 1 day of tracking'
                    : 'From ${summary.daysCovered} days of tracking',
                style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
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
          const SizedBox(height: 12),
          Text(
            '${summary.taken} of about ${summary.expected} doses logged as taken.',
            style: TextStyle(
              fontSize: 13.5,
              height: 1.4,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Expected doses use your current medicine schedule, not a '
            'historical prescription record.',
            style: TextStyle(
              fontSize: 12.5,
              height: 1.4,
              color: Colors.grey.shade600,
            ),
          ),
          if (dayRecords.any((ProgressDayRecord d) => d.hasRecord)) ...[
            const SizedBox(height: 14),
            _DayStrip(days: dayRecords, label: 'Days with a medicine record'),
          ],
        ],
      ),
    );
  }
}

class _LifestyleSection extends StatelessWidget {
  const _LifestyleSection({required this.summary, required this.dayRecords});

  final HabitAdherenceSummary summary;
  final List<ProgressDayRecord> dayRecords;

  @override
  Widget build(BuildContext context) {
    final Color accent = _accentFor(summary.percent);

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lifestyle',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${summary.percent}% of enabled habits logged as done across '
            '${summary.daysCovered} '
            '${summary.daysCovered == 1 ? 'day' : 'days'} '
            'with a record.',
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
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
          if (summary.byPillar.isNotEmpty) ...[
            const SizedBox(height: 16),
            for (final HabitPillarWeekStat stat in summary.byPillar)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
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
          if (dayRecords.any((ProgressDayRecord d) => d.hasRecord)) ...[
            const SizedBox(height: 8),
            _DayStrip(days: dayRecords, label: 'Days with a lifestyle record'),
          ],
        ],
      ),
    );
  }
}

class _ObservationsSection extends StatelessWidget {
  const _ObservationsSection({required this.observations});

  final List<ProgressObservation> observations;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Observations',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Based on what you recorded — not medical advice.',
            style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 10),
          for (final ProgressObservation item in observations)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('•  ', style: TextStyle(color: Colors.grey.shade700)),
                  Expanded(
                    child: Text(
                      item.text,
                      style: TextStyle(
                        fontSize: 13.5,
                        height: 1.4,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _DayStrip extends StatelessWidget {
  const _DayStrip({required this.days, required this.label});

  final List<ProgressDayRecord> days;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final ProgressDayRecord day in days)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                    children: [
                      Container(
                        height: 10,
                        decoration: BoxDecoration(
                          color: day.hasRecord
                              ? const Color(0xff16A34A).withValues(alpha: 0.85)
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _weekdayLetter(day.dateKey),
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Filled = a record exists. Empty = no record (not the same as missed).',
          style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500),
        ),
      ],
    );
  }

  String _weekdayLetter(String dateKey) {
    final DateTime? date = DateTime.tryParse(dateKey);
    if (date == null) return '·';
    const List<String> letters = <String>[
      'M',
      'T',
      'W',
      'T',
      'F',
      'S',
      'S',
    ];
    return letters[date.weekday - 1];
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: child,
    );
  }
}

class _HintCard extends StatelessWidget {
  const _HintCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13.5,
          height: 1.4,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onOpenRoutine});

  final VoidCallback onOpenRoutine;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.insights_outlined, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Not enough recorded activity yet',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Use Routine to log medicines and lifestyle habits. Progress '
            'will show what you have recorded over the last 7 days.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: onOpenRoutine,
            child: const Text('Open Routine'),
          ),
        ],
      ),
    );
  }
}

class _InactiveHabitsState extends StatelessWidget {
  const _InactiveHabitsState({required this.onOpenRoutine});

  final VoidCallback onOpenRoutine;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'No lifestyle habits are currently active',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Turn habits on in Routine to track Diet, Exercise, Sleep and '
            'Mindfulness here. Past records stay intact.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: onOpenRoutine,
            child: const Text('Open Routine'),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off_outlined, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Could not load Progress',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Check your connection and try again. TARU will not invent '
            'progress while history is unavailable.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

Color _accentFor(int percent) {
  if (percent >= 80) return const Color(0xff16A34A);
  if (percent >= 50) return const Color(0xffD97706);
  return const Color(0xffB3261E);
}
