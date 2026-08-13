import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/health_profile/application/health_profile_providers.dart';
import 'package:mobile/features/health_profile/domain/health_profile.dart';
import 'package:mobile/features/measurements/application/measurements_providers.dart';
import 'package:mobile/features/measurements/domain/blood_pressure_measurement.dart';
import 'package:mobile/features/measurements/domain/weight_measurement.dart';
import 'package:mobile/features/measurements/presentation/pages/blood_pressure_history_screen.dart';
import 'package:mobile/features/measurements/presentation/pages/weight_history_screen.dart';

void main() {
  testWidgets('start tracking duplicate tap is blocked', (WidgetTester tester) async {
    final Completer<void> gate = Completer<void>();
    int starts = 0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          healthProfileProvider.overrideWith(
            (Ref ref) => Stream<HealthProfile>.value(
              const HealthProfile(weightKg: 70),
            ),
          ),
          weightHistoryProvider.overrideWith(
            (Ref ref) => Stream<List<WeightMeasurement>>.value(
              const <WeightMeasurement>[],
            ),
          ),
          recordWeightProvider.overrideWith((Ref ref) {
            return (double valueKg, {DateTime? recordedAt}) async {
              starts += 1;
              await gate.future;
            };
          }),
        ],
        child: const MaterialApp(home: WeightHistoryScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('Start tracking with your current weight'));
    await tester.pump();
    await tester.tap(find.byType(FilledButton).first);
    await tester.pump();

    expect(starts, 1);
    final FilledButton button = tester.widget<FilledButton>(
      find.byType(FilledButton).first,
    );
    expect(button.onPressed, isNull);

    gate.complete();
    await tester.pump();
  });

  testWidgets('weight delete duplicate action is blocked', (WidgetTester tester) async {
    final Completer<void> gate = Completer<void>();
    int deletes = 0;
    final WeightMeasurement item = WeightMeasurement(
      id: 'w1',
      valueKg: 70,
      recordedAt: DateTime.utc(2026, 1, 1),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          healthProfileProvider.overrideWith(
            (Ref ref) => Stream<HealthProfile>.value(HealthProfile.empty),
          ),
          weightHistoryProvider.overrideWith(
            (Ref ref) => Stream<List<WeightMeasurement>>.value(
              <WeightMeasurement>[item],
            ),
          ),
          deleteWeightMeasurementProvider.overrideWith((Ref ref) {
            return (String id) async {
              deletes += 1;
              await gate.future;
            };
          }),
        ],
        child: const MaterialApp(home: WeightHistoryScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pump();

    expect(deletes, 1);
    await tester.tap(find.byTooltip('Delete'));
    await tester.pump();
    expect(deletes, 1);

    gate.complete();
    await tester.pump();
  });

  testWidgets('blood pressure delete duplicate action is blocked', (
    WidgetTester tester,
  ) async {
    final Completer<void> gate = Completer<void>();
    int deletes = 0;
    final BloodPressureMeasurement item = BloodPressureMeasurement(
      id: 'bp1',
      systolicMmHg: 120,
      diastolicMmHg: 80,
      recordedAt: DateTime.utc(2026, 1, 1),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bloodPressureHistoryProvider.overrideWith(
            (Ref ref) => Stream<List<BloodPressureMeasurement>>.value(
              <BloodPressureMeasurement>[item],
            ),
          ),
          deleteBloodPressureMeasurementProvider.overrideWith((Ref ref) {
            return (String id) async {
              deletes += 1;
              await gate.future;
            };
          }),
        ],
        child: const MaterialApp(home: BloodPressureHistoryScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pump();

    expect(deletes, 1);
    await tester.tap(find.byTooltip('Delete'));
    await tester.pump();
    expect(deletes, 1);
    gate.complete();
    await tester.pump();
  });
}
