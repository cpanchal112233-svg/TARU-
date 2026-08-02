import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../health_profile/domain/medication.dart';
import '../../../health_profile/presentation/pages/medications_screen.dart';
import '../../application/reminder_providers.dart';
import '../../application/routine_providers.dart';
import '../../domain/dose_schedule.dart';
import '../widgets/adherence_card.dart';
import '../widgets/reminders_tile.dart';

/// Today's medicines, as a checklist.
///
/// The list is derived from the medications the user already recorded, so there
/// is nothing separate to set up: choosing "twice a day, morning and bedtime"
/// on a medicine is what puts it here.
class RoutineScreen extends ConsumerWidget {
  const RoutineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Touch the reminders controller so its schedule listener is alive for the
    // whole session, not only after the user first flips the switch.
    ref.watch(remindersControllerProvider);

    final DailySchedule schedule = ref.watch(dailyScheduleProvider);
    final AsyncValue<DailyDoseLog> log = ref.watch(todayDoseLogProvider);

    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: AppBar(
        title: const Text('Routine'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: schedule.isEmpty
          ? const _NothingScheduled()
          : _buildList(context, ref, schedule, log.value),
    );
  }

  Widget _buildList(
    BuildContext context,
    WidgetRef ref,
    DailySchedule schedule,
    DailyDoseLog? log,
  ) {
    final int taken = schedule.doses
        .where(
          (ScheduledDose dose) => log?.statusOf(dose.key) == DoseStatus.taken,
        )
        .length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        if (schedule.doses.isNotEmpty) ...[
          _TodayHeader(taken: taken, total: schedule.doses.length),
          const SizedBox(height: 12),
          RemindersTile(times: schedule.activeTimes),
        ],

        for (final DoseTime time in schedule.activeTimes) ...[
          const SizedBox(height: 18),
          _TimeLabel(time: time),
          const SizedBox(height: 8),
          for (final ScheduledDose dose in schedule.at(time))
            _DoseRow(
              dose: dose,
              status: log?.statusOf(dose.key),
              onSetStatus: (DoseStatus? status) =>
                  ref.read(setDoseStatusProvider)(dose.key, status),
            ),
        ],

        if (schedule.doses.isNotEmpty) ...[
          const SizedBox(height: 24),
          const AdherenceCard(),
        ],

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
  const _TodayHeader({required this.taken, required this.total});

  final int taken;
  final int total;

  @override
  Widget build(BuildContext context) {
    final bool allDone = taken == total;

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
            allDone ? 'All done for today' : 'Today\'s medicines',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            allDone
                ? 'Every dose is ticked off. Nicely kept.'
                : '$taken of $total doses taken so far.',
            style: const TextStyle(color: Colors.white, fontSize: 14.5),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : taken / total,
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
    return _InfoPanel(
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
    return _InfoPanel(
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

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({
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

class _NothingScheduled extends StatelessWidget {
  const _NothingScheduled();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.medication_outlined,
                size: 48,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'No medicines to track yet',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Add what you take and when, and today\'s doses will appear '
              'here as a checklist you can tick off.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15.5,
                height: 1.45,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const MedicationsScreen(),
                ),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Add your medicines'),
            ),
          ],
        ),
      ),
    );
  }
}
