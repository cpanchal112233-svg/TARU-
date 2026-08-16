import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/account/domain/account_integrity.dart';
import 'package:mobile/features/account/presentation/pages/account_recovery_screen.dart';
import 'package:mobile/features/auth/application/auth_providers.dart';
import 'package:mobile/features/auth/data/auth_service.dart';
import 'package:mobile/features/auth/presentation/pages/forgot_password_screen.dart';
import 'package:mobile/features/auth/presentation/pages/login_screen.dart';
import 'package:mobile/features/auth/presentation/pages/signup_screen.dart';
import 'package:mobile/features/auth/presentation/widgets/auth_button.dart';
import 'package:mobile/features/reports/domain/medical_report.dart';
import 'package:mobile/features/reports/domain/report_extraction.dart';
import 'package:mobile/features/reports/presentation/pages/report_text_review_screen.dart';
import 'package:mobile/features/routine/domain/habit.dart';
import 'package:mobile/features/routine/presentation/widgets/habit_section.dart';

class _NoopAuthService extends AuthService {}

Future<void> _assertNoOverflow(WidgetTester tester) async {
  expect(tester.takeException(), isNull);
  final Finder overflow = find.byWidgetPredicate(
    (Widget widget) =>
        widget is ErrorWidget || (widget.toString().contains('OVERFLOWING')),
  );
  expect(overflow, findsNothing);
}

void main() {
  for (final double scale in <double>[1.3, 2.0]) {
    group('text scale $scale', () {
      testWidgets('login primary CTA remains present', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authServiceProvider.overrideWith((Ref ref) => _NoopAuthService()),
            ],
            child: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(scale)),
              child: const MaterialApp(home: LoginScreen()),
            ),
          ),
        );
        await _assertNoOverflow(tester);
        expect(find.byType(AuthButton), findsOneWidget);
        expect(find.text('Email address'), findsOneWidget);
      });

      testWidgets('signup primary CTA remains present', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authServiceProvider.overrideWith((Ref ref) => _NoopAuthService()),
            ],
            child: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(scale)),
              child: const MaterialApp(home: SignupScreen()),
            ),
          ),
        );
        await _assertNoOverflow(tester);
        expect(find.byType(AuthButton), findsOneWidget);
        expect(find.textContaining('Create Account'), findsWidgets);
      });

      testWidgets('forgot password CTA remains present', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authServiceProvider.overrideWith((Ref ref) => _NoopAuthService()),
            ],
            child: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(scale)),
              child: const MaterialApp(home: ForgotPasswordScreen()),
            ),
          ),
        );
        await _assertNoOverflow(tester);
        expect(find.text('Send Reset Link'), findsOneWidget);
      });

      testWidgets('account recovery sign-out remains reachable', (
        WidgetTester tester,
      ) async {
        await tester.binding.setSurfaceSize(const Size(390, 1200));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          ProviderScope(
            child: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(scale)),
              child: const MaterialApp(
                home: AccountRecoveryScreen(
                  integrity: AccountIntegrity.deletionHealthInProgress,
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(find.text('Continue health-data cleanup'), findsOneWidget);
        expect(find.text('Sign out'), findsOneWidget);
      });

      testWidgets('OCR review actions remain present', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(scale)),
              child: MaterialApp(
                home: ReportTextReviewScreen(
                  report: MedicalReport(
                    id: 'r1',
                    title: 'Lab',
                    category: ReportCategory.lab,
                    fileName: 'a.pdf',
                    mimeType: 'application/pdf',
                    storagePath: 'users/x/a.pdf',
                    sizeBytes: 10,
                    uploadedAt: DateTime(2026, 1, 1),
                  ),
                  initialText: 'Reviewed content',
                  method: ReportExtractionMethod.ocr,
                ),
              ),
            ),
          ),
        );
        await _assertNoOverflow(tester);
        expect(find.text('Save'), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);
      });

      testWidgets('habit row remains operable', (WidgetTester tester) async {
        await tester.pumpWidget(
          MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(scale)),
            child: MaterialApp(
              home: Scaffold(
                body: HabitRow(
                  habit: const HabitItem(
                    id: 'h1',
                    pillar: HabitPillar.exercise,
                    slot: HabitSlot.day,
                    title: 'Walk',
                    detail: 'Short walk',
                  ),
                  status: null,
                  accent: Colors.green,
                  onSetStatus: (_) {},
                ),
              ),
            ),
          ),
        );
        await _assertNoOverflow(tester);
        expect(
          find.bySemanticsLabel('Walk, not recorded as done'),
          findsOneWidget,
        );
      });
    });
  }

  testWidgets('typed DELETE confirmation usable at 2.0', (
    WidgetTester tester,
  ) async {
    final TextEditingController controller = TextEditingController();
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
        child: MaterialApp(
          home: Scaffold(
            body: AlertDialog(
              title: const Text('Type DELETE to confirm'),
              content: SingleChildScrollView(
                child: TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    labelText: 'Type DELETE to confirm',
                  ),
                ),
              ),
              actions: const <Widget>[
                TextButton(onPressed: null, child: Text('Cancel')),
                ElevatedButton(onPressed: null, child: Text('Delete account')),
              ],
            ),
          ),
        ),
      ),
    );
    await _assertNoOverflow(tester);
    expect(find.text('Delete account'), findsOneWidget);
  });
}
