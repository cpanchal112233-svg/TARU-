import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../health_profile/domain/medication.dart';
import '../domain/dose_schedule.dart';

/// Schedules the daily "time for your medicine" notifications.
///
/// One repeating notification per time of day rather than per medicine, so
/// someone taking four things at breakfast gets one reminder listing them
/// instead of four buzzes in a row.
class ReminderService {
  ReminderService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  static const String _channelId = 'medication_reminders';

  /// Notification IDs are derived from the time of day, so rescheduling
  /// replaces the previous reminder instead of stacking another one.
  static const int _idBase = 5000;

  bool _isReady = false;

  Future<void> _ensureReady() async {
    if (_isReady) return;

    tz_data.initializeTimeZones();

    try {
      final TimezoneInfo info = await FlutterTimezone.getLocalTimezone();

      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (error) {
      // Falling back to UTC keeps reminders working, just possibly at the
      // wrong hour, which is better than no reminders at all.
      debugPrint('Could not resolve local timezone: $error');
    }

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            'Medication reminders',
            description: 'Reminds you when a dose is due.',
            importance: Importance.high,
          ),
        );

    _isReady = true;
  }

  /// Asks the user for permission to post notifications.
  ///
  /// Returns false when the user declines, so the caller can leave the
  /// reminders switch off rather than pretending it worked.
  Future<bool> requestPermission() async {
    await _ensureReady();

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final bool? granted = await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);

      return granted ?? false;
    }

    final AndroidFlutterLocalNotificationsPlugin? android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    final bool granted =
        await android?.requestNotificationsPermission() ?? false;

    if (granted) await android?.requestExactAlarmsPermission();

    return granted;
  }

  Future<void> cancelAll() async {
    await _ensureReady();

    for (final DoseTime time in DoseTime.values) {
      await _plugin.cancel(id: _idBase + time.index);
    }
  }

  /// Replaces all reminders with one per time of day that has doses due.
  Future<void> schedule(DailySchedule schedule) async {
    await _ensureReady();
    await cancelAll();

    for (final DoseTime time in DoseTime.values) {
      final List<ScheduledDose> doses = schedule.at(time);

      if (doses.isEmpty) continue;

      await _scheduleDaily(
        id: _idBase + time.index,
        hour: time.hour,
        title: 'Time for your ${time.label.toLowerCase()} medicine',
        body: _bodyFor(doses),
      );
    }
  }

  static String _bodyFor(List<ScheduledDose> doses) {
    return doses
        .map((ScheduledDose dose) {
          final UserMedication medication = dose.medication;
          final String? amount = medication.doseSummary;

          return amount == null
              ? medication.displayName
              : '${medication.displayName} $amount';
        })
        .join(', ');
  }

  Future<void> _scheduleDaily({
    required int id,
    required int hour,
    required String title,
    required String body,
  }) async {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);

    tz.TZDateTime next = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
    );

    if (!next.isAfter(now)) next = next.add(const Duration(days: 1));

    const NotificationDetails details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        'Medication reminders',
        channelDescription: 'Reminds you when a dose is due.',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    try {
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: next,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } on PlatformException catch (error) {
      // Android 14 can refuse exact alarms. An approximate reminder is still
      // far better than none, so fall back rather than failing silently.
      debugPrint('Exact reminder rejected, using inexact: ${error.code}');

      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: next,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }
}
