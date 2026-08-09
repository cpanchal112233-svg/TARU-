import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../health_profile/domain/medication.dart';
import '../../../health_profile/presentation/pages/medications_screen.dart';
import '../../application/habit_providers.dart';
import '../../application/reminder_providers.dart';
import '../../application/routine_providers.dart';
import '../../domain/dose_schedule.dart';
import '../../domain/habit.dart';
import '../widgets/adherence_card.dart';
import '../widgets/habit_adherence_card.dart';
import '../widgets/habit_section.dart';
import '../widgets/lifestyle_reminders_tile.dart';
import '../widgets/manage_habits_sheet.dart';
import '../widgets/reminders_tile.dart';

/// Today's medicines and lifestyle checklist.
///
/// Medicines still come from the health profile schedule. Diet, exercise,
/// sleep and mindfulness are a short daily checklist on top of that, grouped
/// by morning / day / evening.
class RoutineScreen extends ConsumerWidget {
  const RoutineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Keep both reminder controllers alive for the session.
    ref.watch(remindersControllerProvider);
    ref.watch(lifestyleRemindersControllerProvider);

    final DailySchedule schedule = ref.watch(dailyScheduleProvider);
    final AsyncValue<DailyDoseLog> doseLog = ref.watch(todayDoseLogProvider);
    final AsyncValue<DailyHabitLog> habitLog = ref.watch(todayHabitLogProvider);
    final TodayRoutineProgress progress = ref.watch(
      todayRoutineProgressProvider,
    );
    final List<HabitItem> activeHabits = ref.watch(activeHabitsProvider);

    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: AppBar(
        title: const Text('Routine'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: () => showManageHabitsSheet(context),
            child: const Text('Habits'),
          ),
        ],
      ),
      body: _RoutineBody(
        schedule: schedule,
        doseLog: doseLog.value,
        habitLog: habitLog.value,
        progress: progress,
        activeHabits: activeHabits,
      ),
    );
  }
}

class _RoutineBody extends ConsumerWidget {
  const _RoutineBody({
    required this.schedule,
    required this.doseLog,
    required this.habitLog,
    required this.progress,
    required this.activeHabits,
  });

  final DailySchedule schedule;
  final DailyDoseLog? doseLog;
  final DailyHabitLog? habitLog;
  final TodayRoutineProgress progress;
  final List<HabitItem> activeHabits;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        _TodayHeader(progress: progress),
        const SizedBox(height: 12),

        if (schedule.doses.isNotEmpty)
          RemindersTile(times: schedule.activeTimes)
        else
          const _AddMedicinesCard(),

        const SizedBox(height: 10),
        const LifestyleRemindersTile(),

        if (schedule.doses.isNotEmpty) ...[
          const SizedBox(height: 22),
          _SectionTitle(
            title: 'Medicines',
            detail:
                '${progress.dosesTaken} of ${progress.dosesTotal} taken',
          ),
          for (final DoseTime time in schedule.activeTimes) ...[
            const SizedBox(height: 14),
            _TimeLabel(time: time),
            const SizedBox(height: 8),
            for (final ScheduledDose dose in schedule.at(time))
              _DoseRow(
                dose: dose,
                status: doseLog?.statusOf(dose.key),
                onSetStatus: (DoseStatus? status) =>
                    ref.read(setDoseStatusProvider)(dose.key, status),
              ),
          ],
        ],

        const SizedBox(height: 26),
        _SectionTitle(
          title: 'Daily habits',
          detail: activeHabits.isEmpty
              ? 'None selected'
              : '${progress.habitsDone} of ${progress.habitsTotal} done',
        ),
        const SizedBox(height: 6),
        Text(
          'Morning, day and evening — only the habits you keep on.',
          style: TextStyle(
            fontSize: 13.5,
            height: 1.4,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => showManageHabitsSheet(context),
            icon: const Icon(Icons.tune, size: 18),
            label: const Text('Choose habits'),
          ),
        ),

        if (activeHabits.isEmpty)
          _EmptyHabitsCard(onManage: () => showManageHabitsSheet(context))
        else ...[
          for (final HabitSlot slot in HabitSlot.values) ...[
            const SizedBox(height: 10),
            HabitSlotSection(
              slot: slot,
              habits: habitsInSlot(slot, activeHabits),
              log: habitLog,
              onSetStatus: (String habitId, HabitStatus? status) =>
                  ref.read(setHabitStatusProvider)(habitId, status),
            ),
          ],
        ],

        if (schedule.doses.isNotEmpty) ...[
          const SizedBox(height: 16),
          const AdherenceCard(),
        ],
        const SizedBox(height: 12),
        const HabitAdherenceCard(),

        if (schedule.needTimes.isNotEmpty) ...[
          const SizedBox(height: 24),
          _MedicinesNeedingTimes(medications: schedule.needTimes),
        ],

        if (schedule.notDaily.isNotEmpty) ...[
          const SizedBox(height: 24),
          _NotDailyList(medications: schedule.notDaily),
        ],
      ],
    );
  }
}

class _TodayHeader extends StatelessWidget {
  const _TodayHeader({required this.progress});

  final TodayRoutineProgress progress;

  @override
  Widget build(BuildContext context) {
    final bool allDone =
        progress.hasAnything && progress.completed == progress.total;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: allDone ? const Color(0xff16A34A) : Colors.blue,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            allDone ? 'All done for today' : 'Today\'s routine',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            allDone
                ? 'Medicines and habits are ticked off. Nicely kept.'
                : progress.summaryLine,
            style: const TextStyle(color: Colors.white, fontSize: 14.5),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress.total == 0
                  ? 0
                  : progress.completed / progress.total,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ],
      ),
    );
  }

}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.detail});

  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const Spacer(),
        Text(
          detail,
          style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}

class _EmptyHabitsCard extends StatelessWidget {
  const _EmptyHabitsCard({required this.onManage});

  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'No lifestyle habits selected',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Turn a few back on to keep diet, movement, sleep or calm on '
            'today\'s list.',
            style: TextStyle(
              fontSize: 13.5,
              height: 1.4,
              color: Colors.grey.shade700,
            ),
          ),
          TextButton(onPressed: onManage, child: const Text('Choose habits')),
        ],
      ),
    );
  }
}

class _AddMedicinesCard extends StatelessWidget {
  const _AddMedicinesCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.medication_outlined, color: Colors.blue.shade400),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Add medicines to track today\'s doses alongside these habits.',
              style: TextStyle(
                fontSize: 13.5,
                height: 1.35,
                color: Colors.grey.shade800,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const MedicationsScreen(),
              ),
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _TimeLabel extends StatelessWidget {
  const _TimeLabel({required this.time});

  final DoseTime time;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          time.label.toUpperCase(),
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'around ${time.clockLabel}',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
      ],
    );
  }
}

class _DoseRow extends StatelessWidget {
  const _DoseRow({
    required this.dose,
    required this.status,
    required this.onSetStatus,
  });

  final ScheduledDose dose;
  final DoseStatus? status;
  final ValueChanged<DoseStatus?> onSetStatus;

  @override
  Widget build(BuildContext context) {
    final bool isTaken = status == DoseStatus.taken;
    final bool isSkipped = status == DoseStatus.skipped;

    final String? subtitle = _subtitleFor(dose.medication);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isTaken
              ? const Color(0xff16A34A).withValues(alpha: 0.5)
              : Colors.grey.shade200,
        ),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: ListTile(
          contentPadding: const EdgeInsets.fromLTRB(12, 4, 8, 4),
          onTap: () => onSetStatus(isTaken ? null : DoseStatus.taken),
          leading: Icon(
            isTaken
                ? Icons.check_circle
                : isSkipped
                ? Icons.remove_circle_outline
                : Icons.circle_outlined,
            color: isTaken
                ? const Color(0xff16A34A)
                : isSkipped
                ? Colors.grey.shade500
                : Colors.blue.shade300,
            size: 28,
          ),
          title: Text(
            dose.medication.displayName,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isSkipped ? Colors.grey.shade600 : Colors.black87,
              decoration: isSkipped ? TextDecoration.lineThrough : null,
            ),
          ),
          subtitle: subtitle == null
              ? null
              : Text(
                  subtitle,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
          trailing: TextButton(
            onPressed: () => onSetStatus(isSkipped ? null : DoseStatus.skipped),
            child: Text(isSkipped ? 'Skipped' : 'Skip'),
          ),
        ),
      ),
    );
  }

  static String? _subtitleFor(UserMedication medication) {
    final List<String> parts = [
      ?medication.doseSummary,
      if (medication.foodTiming != null &&
          medication.foodTiming != FoodTiming.noPreference)
        medication.foodTiming!.label,
    ];

    return parts.isEmpty ? null : parts.join('  •  ');
  }
}

class _MedicinesNeedingTimes extends StatelessWidget {
  const _MedicinesNeedingTimes({required this.medications});

  final List<UserMedication> medications;

  @override
  Widget build(BuildContext context) {
    return _InfoBox(
      icon: Icons.schedule,
      accent: const Color(0xffB45309),
      title: 'Waiting on times',
      body:
          '${_names(medications)} '
          '${medications.length == 1 ? 'has' : 'have'} no times set, so TARU '
          'cannot tell you when they are due.',
      actionLabel: 'Set times',
      onAction: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const MedicationsScreen()),
      ),
    );
  }

  static String _names(List<UserMedication> medications) => medications
      .map((UserMedication medication) => medication.displayName)
      .join(', ');
}

class _NotDailyList extends StatelessWidget {
  const _NotDailyList({required this.medications});

  final List<UserMedication> medications;

  @override
  Widget build(BuildContext context) {
    return _InfoBox(
      icon: Icons.event_repeat,
      accent: Colors.blueGrey,
      title: 'Not on a daily schedule',
      body: medications
          .map(
            (UserMedication medication) =>
                '${medication.displayName}'
                '${medication.frequency == null ? '' : ' — ${medication.frequency!.label.toLowerCase()}'}',
          )
          .join('\n'),
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({
    required this.icon,
    required this.accent,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final Color accent;
  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: accent),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.45,
              color: Colors.grey.shade800,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 10),
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}
