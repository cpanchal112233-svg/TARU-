import 'package:flutter/material.dart';

import '../../domain/habit.dart';

IconData habitPillarIcon(HabitPillar pillar) {
  switch (pillar) {
    case HabitPillar.diet:
      return Icons.restaurant_outlined;
    case HabitPillar.exercise:
      return Icons.directions_walk_outlined;
    case HabitPillar.sleep:
      return Icons.bedtime_outlined;
    case HabitPillar.mindfulness:
      return Icons.self_improvement_outlined;
  }
}

Color habitPillarColor(HabitPillar pillar) {
  switch (pillar) {
    case HabitPillar.diet:
      return const Color(0xffC2410C);
    case HabitPillar.exercise:
      return const Color(0xff15803D);
    case HabitPillar.sleep:
      return const Color(0xff1D4ED8);
    case HabitPillar.mindfulness:
      return const Color(0xff7C3AED);
  }
}

IconData habitSlotIcon(HabitSlot slot) {
  switch (slot) {
    case HabitSlot.morning:
      return Icons.wb_sunny_outlined;
    case HabitSlot.day:
      return Icons.wb_twilight_outlined;
    case HabitSlot.evening:
      return Icons.nights_stay_outlined;
  }
}

/// Habits for one part of the day (Morning / Day / Evening).
class HabitSlotSection extends StatelessWidget {
  const HabitSlotSection({
    super.key,
    required this.slot,
    required this.habits,
    required this.log,
    required this.onSetStatus,
  });

  final HabitSlot slot;
  final List<HabitItem> habits;
  final DailyHabitLog? log;
  final void Function(String habitId, HabitStatus? status) onSetStatus;

  @override
  Widget build(BuildContext context) {
    if (habits.isEmpty) return const SizedBox.shrink();

    final int done = habits
        .where((HabitItem h) => log?.statusOf(h.id) == HabitStatus.done)
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(habitSlotIcon(slot), size: 18, color: Colors.grey.shade700),
            const SizedBox(width: 8),
            Text(
              slot.label.toUpperCase(),
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              slot.subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
            const Spacer(),
            Text(
              '$done / ${habits.length}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (final HabitItem habit in habits)
          HabitRow(
            habit: habit,
            status: log?.statusOf(habit.id),
            accent: habitPillarColor(habit.pillar),
            onSetStatus: (HabitStatus? status) => onSetStatus(habit.id, status),
          ),
      ],
    );
  }
}

class HabitRow extends StatelessWidget {
  const HabitRow({
    super.key,
    required this.habit,
    required this.status,
    required this.accent,
    required this.onSetStatus,
  });

  final HabitItem habit;
  final HabitStatus? status;
  final Color accent;
  final ValueChanged<HabitStatus?> onSetStatus;

  @override
  Widget build(BuildContext context) {
    final bool isDone = status == HabitStatus.done;
    final bool isSkipped = status == HabitStatus.skipped;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDone ? accent.withValues(alpha: 0.45) : Colors.grey.shade200,
        ),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: ListTile(
          contentPadding: const EdgeInsets.fromLTRB(12, 4, 8, 4),
          onTap: () => onSetStatus(isDone ? null : HabitStatus.done),
          leading: Icon(
            isDone
                ? Icons.check_circle
                : isSkipped
                ? Icons.remove_circle_outline
                : Icons.circle_outlined,
            color: isDone
                ? accent
                : isSkipped
                ? Colors.grey.shade500
                : accent.withValues(alpha: 0.55),
            size: 28,
          ),
          title: Text(
            habit.title,
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w600,
              color: isSkipped ? Colors.grey.shade600 : Colors.black87,
              decoration: isSkipped ? TextDecoration.lineThrough : null,
            ),
          ),
          subtitle: Text(
            '${habit.pillar.label} · ${habit.detail}',
            style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700),
          ),
          trailing: TextButton(
            onPressed: () =>
                onSetStatus(isSkipped ? null : HabitStatus.skipped),
            child: Text(isSkipped ? 'Skipped' : 'Skip'),
          ),
        ),
      ),
    );
  }
}
