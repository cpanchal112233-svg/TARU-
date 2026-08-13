import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/reminder_service.dart';
import '../domain/dose_schedule.dart';
import 'routine_providers.dart';

final reminderServiceProvider = Provider<ReminderService>(
  (ref) => ReminderService(),
);

/// Whether medication reminders are switched on, kept on the device because it
/// is a per-device choice: the same person may want them on their phone and
/// not on a shared tablet.
class RemindersController extends AsyncNotifier<bool> {
  static const String _key = 'medication_reminders_enabled';

  @override
  Future<bool> build() async {
    // Keep notifications in step with the medicine list, even when the user
    // edits a dose from Profile and never opens the Routine tab.
    ref.listen<DailySchedule>(dailyScheduleProvider, (_, _) {
      refresh();
    });

    final SharedPreferences prefs = await SharedPreferences.getInstance();

    final bool enabled = prefs.getBool(_key) ?? false;
    if (!enabled) return false;

    try {
      final bool allowed = await ref
          .read(reminderServiceProvider)
          .notificationsCurrentlyAllowed();
      if (!allowed) {
        await ref.read(reminderServiceProvider).cancelAll();
        return false;
      }

      await _applySchedule();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Returns false when the user declined the system permission, so the caller
  /// can explain why the switch stayed off.
  Future<bool> enable() async {
    try {
      final bool granted = await ref
          .read(reminderServiceProvider)
          .requestPermission();
      if (!granted) return false;

      final bool allowed = await ref
          .read(reminderServiceProvider)
          .notificationsCurrentlyAllowed();
      if (!allowed) return false;

      await _persist(true);
      await _applySchedule();

      state = const AsyncValue.data(true);

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> disable() async {
    await _persist(false);
    await ref.read(reminderServiceProvider).cancelAll();

    state = const AsyncValue.data(false);
  }

  /// Re-reads the schedule and rewrites the reminders, so changing a medicine's
  /// times takes effect without the user thinking about notifications at all.
  Future<void> refresh() async {
    if (state.value != true) return;

    await _applySchedule();
  }

  Future<void> _applySchedule() async {
    final DailySchedule schedule = ref.read(dailyScheduleProvider);

    await ref.read(reminderServiceProvider).schedule(schedule);
  }

  Future<void> _persist(bool enabled) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_key, enabled);
  }
}

final remindersControllerProvider =
    AsyncNotifierProvider<RemindersController, bool>(RemindersController.new);

/// One optional evening nudge for lifestyle habits. Device-local, like
/// medicine reminders — not a second notification management system.
class LifestyleRemindersController extends AsyncNotifier<bool> {
  static const String _key = 'lifestyle_reminders_enabled';

  @override
  Future<bool> build() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool enabled = prefs.getBool(_key) ?? false;
    if (!enabled) return false;

    try {
      final bool allowed = await ref
          .read(reminderServiceProvider)
          .notificationsCurrentlyAllowed();
      if (!allowed) {
        await ref.read(reminderServiceProvider).cancelLifestyleReminder();
        return false;
      }

      await ref.read(reminderServiceProvider).scheduleLifestyleReminder();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> enable() async {
    try {
      final bool granted = await ref
          .read(reminderServiceProvider)
          .requestPermission();
      if (!granted) return false;

      final bool allowed = await ref
          .read(reminderServiceProvider)
          .notificationsCurrentlyAllowed();
      if (!allowed) return false;

      await _persist(true);
      await ref.read(reminderServiceProvider).scheduleLifestyleReminder();
      state = const AsyncValue.data(true);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> disable() async {
    await _persist(false);
    await ref.read(reminderServiceProvider).cancelLifestyleReminder();
    state = const AsyncValue.data(false);
  }

  Future<void> _persist(bool enabled) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, enabled);
  }
}

final lifestyleRemindersControllerProvider =
    AsyncNotifierProvider<LifestyleRemindersController, bool>(
      LifestyleRemindersController.new,
    );
