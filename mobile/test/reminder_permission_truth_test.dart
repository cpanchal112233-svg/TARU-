import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/routine/application/reminder_providers.dart';
import 'package:mobile/features/routine/application/routine_providers.dart';
import 'package:mobile/features/routine/data/reminder_service.dart';
import 'package:mobile/features/routine/domain/dose_schedule.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeReminderService extends ReminderService {
  _FakeReminderService({required this.allowed, this.throwOnCheck = false})
    : super(
        notificationsAllowed: () async {
          if (throwOnCheck) {
            throw StateError('permission check failed');
          }
          return allowed;
        },
      );

  final bool allowed;
  final bool throwOnCheck;
  int cancelCount = 0;
  int scheduleCount = 0;

  @override
  Future<void> cancelAll() async {
    cancelCount += 1;
  }

  @override
  Future<void> schedule(DailySchedule schedule) async {
    scheduleCount += 1;
  }

  @override
  Future<bool> requestPermission() async => allowed;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('preference ON and OS permission ON is enabled', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'medication_reminders_enabled': true,
    });
    final _FakeReminderService service = _FakeReminderService(allowed: true);
    final ProviderContainer container = ProviderContainer(
      overrides: [
        reminderServiceProvider.overrideWithValue(service),
        dailyScheduleProvider.overrideWithValue(DailySchedule.empty),
      ],
    );
    addTearDown(container.dispose);

    final bool enabled = await container.read(
      remindersControllerProvider.future,
    );
    expect(enabled, isTrue);
    expect(service.scheduleCount, 1);
  });

  test('preference ON and OS permission revoked is not active', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'medication_reminders_enabled': true,
    });
    final _FakeReminderService service = _FakeReminderService(allowed: false);
    final ProviderContainer container = ProviderContainer(
      overrides: [
        reminderServiceProvider.overrideWithValue(service),
        dailyScheduleProvider.overrideWithValue(DailySchedule.empty),
      ],
    );
    addTearDown(container.dispose);

    final bool enabled = await container.read(
      remindersControllerProvider.future,
    );
    expect(enabled, isFalse);
    expect(service.cancelCount, 1);
    expect(service.scheduleCount, 0);
  });

  test('re-check failure does not claim enabled', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'medication_reminders_enabled': true,
    });
    final _FakeReminderService service = _FakeReminderService(
      allowed: true,
      throwOnCheck: true,
    );
    final ProviderContainer container = ProviderContainer(
      overrides: [
        reminderServiceProvider.overrideWithValue(service),
        dailyScheduleProvider.overrideWithValue(DailySchedule.empty),
      ],
    );
    addTearDown(container.dispose);

    final bool enabled = await container.read(
      remindersControllerProvider.future,
    );
    expect(enabled, isFalse);
  });
}
