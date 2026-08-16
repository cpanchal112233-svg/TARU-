import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/health_profile/domain/medication.dart';
import 'package:mobile/features/routine/domain/dose_schedule.dart';
import 'package:mobile/features/routine/domain/habit.dart';
import 'package:mobile/features/routine/presentation/widgets/dose_row.dart';
import 'package:mobile/features/routine/presentation/widgets/habit_section.dart';

void main() {
  final ScheduledDose dose = ScheduledDose(
    medication: const UserMedication(
      ingredient: MedicationIngredient.paracetamol,
    ),
    time: DoseTime.morning,
  );

  const HabitItem habit = HabitItem(
    id: 'test_habit',
    pillar: HabitPillar.diet,
    slot: HabitSlot.morning,
    title: 'Drink water',
    detail: 'A glass with breakfast',
  );

  Future<void> pumpDose(
    WidgetTester tester, {
    required DoseStatus? status,
    required bool busy,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DoseRow(
            dose: dose,
            status: status,
            busy: busy,
            onSetStatus: (_) {},
          ),
        ),
      ),
    );
  }

  Future<void> pumpHabit(
    WidgetTester tester, {
    required HabitStatus? status,
    required bool busy,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HabitRow(
            habit: habit,
            status: status,
            accent: Colors.orange,
            busy: busy,
            onSetStatus: (_) {},
          ),
        ),
      ),
    );
  }

  testWidgets('medicine not recorded: primary and Skip are separate', (
    WidgetTester tester,
  ) async {
    await pumpDose(tester, status: null, busy: false);

    expect(
      find.bySemanticsLabel('Paracetamol, not recorded as taken'),
      findsOneWidget,
    );
    expect(find.widgetWithText(TextButton, 'Skip'), findsOneWidget);
    expect(find.bySemanticsLabel('Skip'), findsOneWidget);

    // Distinct nodes: primary label is not the Skip button text.
    final SemanticsNode primary = tester.getSemantics(
      find.bySemanticsLabel('Paracetamol, not recorded as taken'),
    );
    final SemanticsNode skip = tester.getSemantics(
      find.bySemanticsLabel('Skip'),
    );
    expect(identical(primary, skip), isFalse);
    expect(primary.id == skip.id, isFalse);
  });

  testWidgets('medicine taken: factual state and Skip remain separate', (
    WidgetTester tester,
  ) async {
    await pumpDose(tester, status: DoseStatus.taken, busy: false);

    expect(
      find.bySemanticsLabel('Paracetamol, recorded as taken'),
      findsOneWidget,
    );
    expect(find.widgetWithText(TextButton, 'Skip'), findsOneWidget);
    expect(find.bySemanticsLabel('Skip'), findsOneWidget);
  });

  testWidgets('medicine skipped: factual state and Skipped action separate', (
    WidgetTester tester,
  ) async {
    await pumpDose(tester, status: DoseStatus.skipped, busy: false);

    expect(
      find.bySemanticsLabel('Paracetamol, recorded as skipped'),
      findsOneWidget,
    );
    expect(find.widgetWithText(TextButton, 'Skipped'), findsOneWidget);
    expect(find.bySemanticsLabel('Skipped'), findsOneWidget);
  });

  testWidgets('medicine busy: Saving primary, no Skip mutation control', (
    WidgetTester tester,
  ) async {
    await pumpDose(tester, status: null, busy: true);

    expect(find.bySemanticsLabel('Paracetamol, Saving'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Skip'), findsNothing);
    expect(find.widgetWithText(TextButton, 'Skipped'), findsNothing);
  });

  testWidgets('habit not recorded: primary and Skip are separate', (
    WidgetTester tester,
  ) async {
    await pumpHabit(tester, status: null, busy: false);

    expect(
      find.bySemanticsLabel('Drink water, not recorded as done'),
      findsOneWidget,
    );
    expect(find.widgetWithText(TextButton, 'Skip'), findsOneWidget);
    expect(find.bySemanticsLabel('Skip'), findsOneWidget);

    final SemanticsNode primary = tester.getSemantics(
      find.bySemanticsLabel('Drink water, not recorded as done'),
    );
    final SemanticsNode skip = tester.getSemantics(
      find.bySemanticsLabel('Skip'),
    );
    expect(primary.id == skip.id, isFalse);
  });

  testWidgets('habit done: factual state and Skip remain separate', (
    WidgetTester tester,
  ) async {
    await pumpHabit(tester, status: HabitStatus.done, busy: false);

    expect(
      find.bySemanticsLabel('Drink water, recorded as done'),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Skip'), findsOneWidget);
  });

  testWidgets('habit skipped: factual state and Skipped separate', (
    WidgetTester tester,
  ) async {
    await pumpHabit(tester, status: HabitStatus.skipped, busy: false);

    expect(
      find.bySemanticsLabel('Drink water, recorded as skipped'),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Skipped'), findsOneWidget);
  });

  testWidgets('habit busy: Saving primary, no Skip control', (
    WidgetTester tester,
  ) async {
    await pumpHabit(tester, status: null, busy: true);

    expect(find.bySemanticsLabel('Drink water, Saving'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Skip'), findsNothing);
  });
}
