import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/routine/application/habit_providers.dart';
import 'package:mobile/features/routine/application/routine_in_flight.dart';
import 'package:mobile/features/routine/domain/dose_schedule.dart';
import 'package:mobile/features/routine/domain/habit.dart';
import 'package:mobile/core/reliability/user_facing_error.dart';

void main() {
  test('medicine write success records once', () async {
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);
    final RoutineInFlight guard = container.read(routineInFlightProvider.notifier);
    int writes = 0;

    await performRoutineWrite(
      guard: guard,
      token: RoutineInFlight.dose('med_morning'),
      action: () async {
        writes += 1;
      },
      onError: (Object _) => fail('should not fail'),
    );

    expect(writes, 1);
    expect(guard.isBusy(RoutineInFlight.dose('med_morning')), isFalse);
  });

  test('medicine write failure shows safe feedback and allows retry', () async {
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);
    final RoutineInFlight guard = container.read(routineInFlightProvider.notifier);
    Object? shown;
    int writes = 0;

    await performRoutineWrite(
      guard: guard,
      token: RoutineInFlight.dose('med_morning'),
      action: () async {
        writes += 1;
        throw StateError('WEIGHT_123_DO_NOT_SEND');
      },
      onError: (Object error) {
        shown = userFacingErrorMessage(error);
      },
    );

    expect(writes, 1);
    expect(shown, kGenericOperationFailed);
    expect('$shown', isNot(contains('WEIGHT_123_DO_NOT_SEND')));
    expect(guard.isBusy(RoutineInFlight.dose('med_morning')), isFalse);

    await performRoutineWrite(
      guard: guard,
      token: RoutineInFlight.dose('med_morning'),
      action: () async {
        writes += 1;
      },
      onError: (Object _) => fail('retry should succeed'),
    );
    expect(writes, 2);
  });

  test('duplicate same-dose action is blocked while in flight', () async {
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);
    final RoutineInFlight guard = container.read(routineInFlightProvider.notifier);
    final Completer<void> gate = Completer<void>();
    int writes = 0;

    final Future<void> first = performRoutineWrite(
      guard: guard,
      token: RoutineInFlight.dose('med_morning'),
      action: () async {
        writes += 1;
        await gate.future;
      },
      onError: (Object _) => fail('should not fail'),
    );

    await Future<void>.delayed(Duration.zero);
    expect(guard.isBusy(RoutineInFlight.dose('med_morning')), isTrue);

    await performRoutineWrite(
      guard: guard,
      token: RoutineInFlight.dose('med_morning'),
      action: () async {
        writes += 1;
      },
      onError: (Object _) => fail('duplicate should not run'),
    );

    expect(writes, 1);
    gate.complete();
    await first;
    expect(writes, 1);
  });

  test('lifestyle habit write uses per-habit granularity', () async {
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);
    final RoutineInFlight guard = container.read(routineInFlightProvider.notifier);
    final Completer<void> gate = Completer<void>();
    int habitA = 0;
    int habitB = 0;

    final Future<void> first = performRoutineWrite(
      guard: guard,
      token: RoutineInFlight.habit('diet_water'),
      action: () async {
        habitA += 1;
        await gate.future;
      },
      onError: (Object _) => fail('should not fail'),
    );
    await Future<void>.delayed(Duration.zero);

    await performRoutineWrite(
      guard: guard,
      token: RoutineInFlight.habit('mind_quiet'),
      action: () async {
        habitB += 1;
      },
      onError: (Object _) => fail('other habit should run'),
    );

    expect(habitA, 1);
    expect(habitB, 1);
    gate.complete();
    await first;
  });

  test('Phase 7 calculations remain independent with no combined score', () {
    const AdherenceSummary medicine = AdherenceSummary(
      taken: 3,
      expected: 6,
      daysCovered: 2,
    );
    const HabitAdherenceSummary lifestyle = HabitAdherenceSummary(
      done: 4,
      possible: 8,
      daysCovered: 2,
      byPillar: <HabitPillarWeekStat>[],
    );
    expect(medicine.percent, 50);
    expect(lifestyle.percent, 50);
    expect(TodayRoutineProgress(
      dosesTaken: 2,
      dosesTotal: 3,
      habitsDone: 4,
      habitsTotal: 6,
    ).summaryLine, 'Medicines 2/3 · Habits 4/6');
  });
}
