import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/constants/app_public_links.dart';
import 'package:mobile/features/auth/application/auth_providers.dart';
import 'package:mobile/features/auth/data/auth_service.dart';
import 'package:mobile/features/auth/presentation/pages/forgot_password_screen.dart';
import 'package:mobile/features/profile/presentation/pages/help_support_screen.dart';

class _FakeAuthService extends AuthService {
  _FakeAuthService({this.onReset});

  final Future<void> Function(String email)? onReset;
  int resetCalls = 0;
  String? lastEmail;
  FirebaseAuthException? throwAuth;

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    resetCalls += 1;
    lastEmail = email.trim();
    if (throwAuth != null) throw throwAuth!;
    if (onReset != null) await onReset!(email);
  }
}

void main() {
  testWidgets('forgot password validates blank and malformed email', (
    WidgetTester tester,
  ) async {
    final _FakeAuthService fake = _FakeAuthService();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authServiceProvider.overrideWith((ref) => fake),
        ],
        child: const MaterialApp(home: ForgotPasswordScreen()),
      ),
    );

    await tester.tap(find.text('Send Reset Link'));
    await tester.pump();
    expect(find.text('Please enter your email.'), findsOneWidget);
    expect(fake.resetCalls, 0);

    await tester.enterText(find.byType(TextFormField), 'not-an-email');
    await tester.tap(find.text('Send Reset Link'));
    await tester.pump();
    expect(find.text('Please enter a valid email address.'), findsOneWidget);
    expect(fake.resetCalls, 0);
  });

  testWidgets('forgot password success is privacy-safe and trims email', (
    WidgetTester tester,
  ) async {
    final _FakeAuthService fake = _FakeAuthService();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authServiceProvider.overrideWith((ref) => fake),
        ],
        child: const MaterialApp(
          home: ForgotPasswordScreen(initialEmail: '  a@b.co  '),
        ),
      ),
    );

    expect(find.text('  a@b.co  '), findsOneWidget);
    await tester.tap(find.text('Send Reset Link'));
    await tester.pumpAndSettle();

    expect(fake.resetCalls, 1);
    expect(fake.lastEmail, 'a@b.co');
    expect(
      find.textContaining('If an account exists for that email'),
      findsWidgets,
    );
  });

  testWidgets('forgot password blocks duplicate taps while loading', (
    WidgetTester tester,
  ) async {
    final Completer<void> gate = Completer<void>();
    final _FakeAuthService fake = _FakeAuthService(
      onReset: (_) => gate.future,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authServiceProvider.overrideWith((ref) => fake),
        ],
        child: const MaterialApp(home: ForgotPasswordScreen()),
      ),
    );
    await tester.enterText(find.byType(TextFormField), 'user@example.com');
    await tester.tap(find.text('Send Reset Link'));
    await tester.pump();
    expect(find.text('Sending…'), findsOneWidget);
    await tester.tap(find.text('Sending…'));
    await tester.pump();
    expect(fake.resetCalls, 1);
    gate.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('forgot password maps network errors without raw exception', (
    WidgetTester tester,
  ) async {
    final _FakeAuthService fake = _FakeAuthService()
      ..throwAuth = FirebaseAuthException(code: 'network-request-failed');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authServiceProvider.overrideWith((ref) => fake),
        ],
        child: const MaterialApp(home: ForgotPasswordScreen()),
      ),
    );
    await tester.enterText(find.byType(TextFormField), 'user@example.com');
    await tester.tap(find.text('Send Reset Link'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Network error'), findsOneWidget);
    expect(find.textContaining('FirebaseAuthException'), findsNothing);
  });

  testWidgets('user-not-found still shows privacy-safe success', (
    WidgetTester tester,
  ) async {
    final _FakeAuthService fake = _FakeAuthService()
      ..throwAuth = FirebaseAuthException(code: 'user-not-found');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authServiceProvider.overrideWith((ref) => fake),
        ],
        child: const MaterialApp(home: ForgotPasswordScreen()),
      ),
    );
    await tester.enterText(find.byType(TextFormField), 'missing@example.com');
    await tester.tap(find.text('Send Reset Link'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('If an account exists for that email'),
      findsWidgets,
    );
  });

  test('login has no Google or Apple buttons', () {
    final String source = File(
      'lib/features/auth/presentation/pages/login_screen.dart',
    ).readAsStringSync();
    expect(source.contains('Continue with Google'), isFalse);
    expect(source.contains('Continue with Apple'), isFalse);
    expect(source.contains('SocialLoginButton'), isFalse);
  });

  test('profile has no phone verification stub', () {
    final String source = File(
      'lib/features/profile/presentation/pages/profile_screen.dart',
    ).readAsStringSync();
    expect(source.contains('Phone verification will be implemented'), isFalse);
    expect(source.contains('changePhoneNumber'), isFalse);
    expect(source.contains('Help & support'), isTrue);
  });

  testWidgets('help hides unconfigured support and legal actions', (
    WidgetTester tester,
  ) async {
    expect(AppPublicLinks.hasSupportEmail, isFalse);
    expect(AppPublicLinks.hasPrivacyPolicyUrl, isFalse);
    expect(AppPublicLinks.hasTermsOfUseUrl, isFalse);

    await tester.pumpWidget(const MaterialApp(home: HelpSupportScreen()));
    expect(find.text('Contact support'), findsNothing);
    expect(find.text('Privacy Policy'), findsNothing);
    expect(find.text('Terms of Use'), findsNothing);
    expect(find.text('Privacy & data'), findsOneWidget);
    expect(find.textContaining('does not diagnose'), findsOneWidget);
  });
}
