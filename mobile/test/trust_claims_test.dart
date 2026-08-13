import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/onboarding/data/onboarding_data.dart';

void main() {
  test('onboarding present-tense copy avoids unshipped AI claims', () {
    final String all = onboardingPages
        .map((OnboardingModel p) => '${p.title}\n${p.description}')
        .join('\n')
        .toLowerCase();

    expect(all.contains('ai-powered'), isFalse);
    expect(all.contains('ai recommendation'), isFalse);
    expect(all.contains('diet plan'), isFalse);
    expect(all.contains('personalized insight'), isFalse);
    expect(all.contains('explanation'), isFalse);
    expect(all.contains('predict'), isFalse);

    expect(all.contains('organize') || all.contains('together'), isTrue);
    expect(all.contains('export') || all.contains('delete'), isTrue);
  });

  test('signup has no AI-powered claim', () {
    final String source = File(
      'lib/features/auth/presentation/pages/signup_screen.dart',
    ).readAsStringSync();
    expect(source.contains('AI-powered'), isFalse);
  });

  test('reports empty copy no longer promises explanations', () {
    final String source = File(
      'lib/features/reports/presentation/pages/reports_screen.dart',
    ).readAsStringSync();
    expect(source.contains('explanations in plain'), isFalse);
    expect(source.contains('come next'), isFalse);
    expect(source.contains('review it before saving'), isTrue);
  });

  test('home hero no longer claims understand and improve health', () {
    final String source = File(
      'lib/features/home/presentation/pages/home_screen.dart',
    ).readAsStringSync();
    expect(source.contains('understand and improve your health'), isFalse);
    expect(source.contains('Health Journey Starts Here'), isFalse);
  });

  test('completeness no longer promises advice that fits you', () {
    final String source = File(
      'lib/features/health_profile/presentation/widgets/'
      'health_profile_completeness_card.dart',
    ).readAsStringSync();
    expect(source.contains('give advice that fits you'), isFalse);
  });

  test('adherence cards no longer use threshold traffic-light grades', () {
    for (final String path in <String>[
      'lib/features/routine/presentation/widgets/adherence_card.dart',
      'lib/features/routine/presentation/widgets/habit_adherence_card.dart',
      'lib/features/progress/presentation/pages/progress_screen.dart',
    ]) {
      final String source = File(path).readAsStringSync();
      expect(source.contains('percent >= 80'), isFalse, reason: path);
      expect(source.contains('percent >= 50'), isFalse, reason: path);
    }
  });

  test('privacy actions remain distinct', () {
    final String source = File(
      'lib/features/privacy/presentation/pages/privacy_data_screen.dart',
    ).readAsStringSync();
    expect(source.contains('Delete my health data'), isTrue);
    expect(source.contains('Delete TARU account'), isTrue);
    expect(source.contains('keep your TARU login'), isTrue);
  });
}
