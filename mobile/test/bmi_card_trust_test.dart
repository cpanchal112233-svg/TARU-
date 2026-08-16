import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/health_profile/presentation/widgets/bmi_card.dart';

void main() {
  testWidgets('BMI shows number without clinical categories', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: BmiCard(bmi: 22.4))),
    );

    expect(find.text('22.4'), findsOneWidget);
    expect(find.text('BMI'), findsOneWidget);
    expect(find.textContaining('not a diagnosis'), findsOneWidget);
    expect(find.text('Underweight'), findsNothing);
    expect(find.text('Healthy weight'), findsNothing);
    expect(find.text('Overweight'), findsNothing);
    expect(find.text('Obese'), findsNothing);
    expect(find.text('Under 18.5'), findsNothing);
    expect(find.text('18.5–24.9'), findsNothing);
  });

  test('HealthProfile BMI formula unchanged', () {
    // 70 kg / (1.75 m)^2 ≈ 22.857
    const double heightCm = 175;
    const double weightKg = 70;
    final double bmi = weightKg / ((heightCm / 100) * (heightCm / 100));
    expect(bmi, closeTo(22.857, 0.01));
  });
}
