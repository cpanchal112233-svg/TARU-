import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/application/auth_providers.dart';
import 'package:mobile/features/auth/data/auth_service.dart';
import 'package:mobile/features/auth/presentation/pages/login_screen.dart';
import 'package:mobile/features/auth/presentation/widgets/auth_button.dart';
import 'package:mobile/features/health_profile/presentation/widgets/bmi_card.dart';
import 'package:mobile/features/routine/domain/habit.dart';
import 'package:mobile/features/routine/presentation/widgets/habit_section.dart';

class _NoopAuthService extends AuthService {}

void main() {
  testWidgets('login meets labeled tap target guideline', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authServiceProvider.overrideWith((Ref ref) => _NoopAuthService()),
        ],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  });

  testWidgets('habit row meets android tap target guideline', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HabitRow(
            habit: const HabitItem(
              id: 'h1',
              pillar: HabitPillar.sleep,
              slot: HabitSlot.evening,
              title: 'Wind down',
              detail: 'Quiet time',
            ),
            status: HabitStatus.done,
            accent: Colors.blue,
            onSetStatus: (_) {},
          ),
        ),
      ),
    );

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  });

  testWidgets('auth button and BMI remain factual without category labels', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: <Widget>[
              AuthButton(text: 'Continue', onPressed: null),
              BmiCard(bmi: 22.4),
            ],
          ),
        ),
      ),
    );

    expect(find.text('BMI'), findsOneWidget);
    expect(find.text('22.4'), findsOneWidget);
    expect(find.text('Underweight'), findsNothing);
    expect(find.text('Healthy weight'), findsNothing);
    expect(find.text('Overweight'), findsNothing);
    expect(find.text('Obese'), findsNothing);
  });
}
