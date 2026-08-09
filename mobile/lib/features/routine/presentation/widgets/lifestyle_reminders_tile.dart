import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/reminder_providers.dart';
import '../../data/reminder_service.dart';

/// One optional evening nudge for lifestyle habits.
class LifestyleRemindersTile extends ConsumerWidget {
  const LifestyleRemindersTile({super.key});

  Future<void> _onChanged(
    BuildContext context,
    WidgetRef ref,
    bool wantsOn,
  ) async {
    final LifestyleRemindersController controller = ref.read(
      lifestyleRemindersControllerProvider.notifier,
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
    // Keep the controller alive so a previously enabled reminder is rescheduled.
    ref.watch(lifestyleRemindersControllerProvider);
    final bool isOn =
        ref.watch(lifestyleRemindersControllerProvider).value ?? false;

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
          isOn ? Icons.nightlight_round : Icons.nightlight_outlined,
          color: isOn ? const Color(0xff7C3AED) : Colors.grey.shade500,
        ),
        title: const Text(
          'Evening habit reminder',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          'One gentle nudge around ${ReminderService.lifestyleReminderHour > 12 ? ReminderService.lifestyleReminderHour - 12 : ReminderService.lifestyleReminderHour} '
          '${ReminderService.lifestyleReminderHour >= 12 ? 'pm' : 'am'}.',
          style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
        ),
      ),
    );
  }
}
