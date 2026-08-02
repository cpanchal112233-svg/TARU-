import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../health_profile/domain/medication.dart';
import '../../application/reminder_providers.dart';
import '../../domain/dose_schedule.dart';

/// Switches the daily medicine reminders on or off.
///
/// One notification per time of day, listing what is due, rather than one per
/// tablet — a person on five morning medicines should be nudged once, not five
/// times, or they will turn the whole thing off.
class RemindersTile extends ConsumerWidget {
  const RemindersTile({super.key, required this.times});

  final List<DoseTime> times;

  Future<void> _onChanged(
    BuildContext context,
    WidgetRef ref,
    bool wantsOn,
  ) async {
    final RemindersController controller = ref.read(
      remindersControllerProvider.notifier,
    );

    if (!wantsOn) {
      await controller.disable();
      return;
    }

    final bool granted = await controller.enable();

    if (granted || !context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Reminders need notification permission. '
          'You can turn it on in your phone settings.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isOn = ref.watch(remindersControllerProvider).value ?? false;

    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: SwitchListTile(
        value: isOn,
        onChanged: (bool value) => _onChanged(context, ref, value),
        secondary: Icon(
          isOn ? Icons.notifications_active : Icons.notifications_none,
          color: isOn ? Colors.blue : Colors.grey.shade500,
        ),
        title: const Text(
          'Remind me',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          isOn ? _scheduleSummary() : 'Get a nudge when a dose is due.',
          style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  String _scheduleSummary() {
    if (times.isEmpty) return 'No doses scheduled yet.';

    return 'Daily at ${times.map((DoseTime time) => time.clockLabel).join(', ')}.';
  }
}
