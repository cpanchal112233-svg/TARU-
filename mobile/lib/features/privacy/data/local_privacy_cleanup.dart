import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../routine/data/reminder_service.dart';

/// Cancels health reminders and removes TARU-owned temp health/export files.
class LocalPrivacyCleanup {
  LocalPrivacyCleanup({ReminderService? reminderService})
    : _reminders = reminderService ?? ReminderService();

  final ReminderService _reminders;

  static const String medicationRemindersKey = 'medication_reminders_enabled';
  static const String lifestyleRemindersKey = 'lifestyle_reminders_enabled';
  static const String onboardingKey = 'has_seen_onboarding';

  /// Cancel notifications first so reminders cannot fire mid-deletion.
  Future<void> cancelHealthNotifications() async {
    await _reminders.cancelAll();
    await _reminders.cancelLifestyleReminder();
  }

  Future<void> disableReminderPreferences() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(medicationRemindersKey, false);
    await prefs.setBool(lifestyleRemindersKey, false);
  }

  /// Best-effort removal of TARU report/export temps. Keeps onboarding flag.
  Future<void> clearTaruTempFiles() async {
    final List<Directory> roots = <Directory>[];
    roots.add(Directory.systemTemp);
    try {
      roots.add(await getTemporaryDirectory());
    } catch (_) {
      // path_provider unavailable in some tests — systemTemp still cleaned.
    }

    for (final Directory root in roots) {
      if (!root.existsSync()) continue;
      for (final FileSystemEntity entity in root.listSync()) {
        final String name = p.basename(entity.path);
        final bool isTaruTemp =
            name.startsWith('taru_export_') ||
            (name.startsWith('taru_') &&
                (name.contains('.') || name.startsWith('taru_export')));
        // Match report downloads (taru_{reportId}_{fileName}) and OCR work
        // dirs (taru_ocr_{reportId}).
        final bool isReportTemp =
            name.startsWith('taru_') && !name.startsWith('taru_export_');
        if (!(isTaruTemp || isReportTemp)) continue;
        try {
          if (entity is File) {
            await entity.delete();
          } else if (entity is Directory) {
            await entity.delete(recursive: true);
          }
        } catch (_) {
          // Best-effort.
        }
      }
    }
  }

  Future<void> runFullLocalCleanup() async {
    await cancelHealthNotifications();
    await disableReminderPreferences();
    await clearTaruTempFiles();
  }
}

/// Launch-time stale temp cleanup (report downloads + export staging).
Future<void> cleanupStaleTaruTempsOnLaunch() async {
  await LocalPrivacyCleanup().clearTaruTempFiles();
}
