import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/application/auth_providers.dart';
import 'package:mobile/features/auth/data/auth_service.dart';
import 'package:mobile/features/auth/presentation/pages/forgot_password_screen.dart';
import 'package:mobile/features/auth/presentation/pages/login_screen.dart';
import 'package:mobile/features/auth/presentation/pages/signup_screen.dart';
import 'package:mobile/features/auth/presentation/widgets/auth_button.dart';
import 'package:mobile/features/profile/presentation/pages/reauthentication_screen.dart';

class _NoopAuthService extends AuthService {}

class _SlowAuthService extends AuthService {
  final Completer<UserCredential> completer = Completer<UserCredential>();

  @override
  Future<UserCredential> login({
    required String email,
    required String password,
  }) {
    return completer.future;
  }
}

InputDecoration _decorationOf(WidgetTester tester, Finder field) {
  final InputDecorator decorator = tester.widget<InputDecorator>(
    find.descendant(of: field, matching: find.byType(InputDecorator)),
  );
  return decorator.decoration;
}

void main() {
  Future<void> pumpLogin(WidgetTester tester, {AuthService? auth}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authServiceProvider.overrideWith(
            (Ref ref) => auth ?? _NoopAuthService(),
          ),
        ],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );
  }

  testWidgets('login email and password have persistent labels', (
    WidgetTester tester,
  ) async {
    await pumpLogin(tester);

    final Finder email = find.byType(TextFormField).at(0);
    final Finder password = find.byType(TextFormField).at(1);
    expect(_decorationOf(tester, email).labelText, 'Email address');
    expect(_decorationOf(tester, password).labelText, 'Password');

    await tester.enterText(email, 'a@b.com');
    await tester.enterText(password, 'secret1');
    await tester.pump();

    expect(_decorationOf(tester, email).labelText, 'Email address');
    expect(_decorationOf(tester, password).labelText, 'Password');
  });

  testWidgets('login show and hide password actions are labeled', (
    WidgetTester tester,
  ) async {
    await pumpLogin(tester);

    expect(find.byTooltip('Show password'), findsOneWidget);
    await tester.tap(find.byTooltip('Show password'));
    await tester.pump();
    expect(find.byTooltip('Hide password'), findsOneWidget);
  });

  testWidgets('login loading keeps an understandable button label', (
    WidgetTester tester,
  ) async {
    final _SlowAuthService slow = _SlowAuthService();
    await pumpLogin(tester, auth: slow);
    await tester.enterText(find.byType(TextFormField).at(0), 'a@b.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'password');
    await tester.tap(find.byType(AuthButton));
    await tester.pump();

    expect(find.text('Logging in'), findsOneWidget);
    slow.completer.completeError(Exception('stop'));
    await tester.pump();
  });

  testWidgets('signup password fields and visibility are labeled', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authServiceProvider.overrideWith((Ref ref) => _NoopAuthService()),
        ],
        child: const MaterialApp(home: SignupScreen()),
      ),
    );

    expect(
      _decorationOf(tester, find.byType(TextFormField).at(1)).labelText,
      'Email address',
    );
    expect(
      _decorationOf(tester, find.byType(TextFormField).at(2)).labelText,
      'Password',
    );
    expect(
      _decorationOf(tester, find.byType(TextFormField).at(3)).labelText,
      'Confirm password',
    );
    expect(find.byTooltip('Show password'), findsNWidgets(2));
  });

  testWidgets('forgot password email field has persistent label', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authServiceProvider.overrideWith((Ref ref) => _NoopAuthService()),
        ],
        child: const MaterialApp(home: ForgotPasswordScreen()),
      ),
    );

    expect(
      _decorationOf(tester, find.byType(TextFormField)).labelText,
      'Email address',
    );
    expect(find.text('Send Reset Link'), findsOneWidget);
  });

  testWidgets('reauth password field and visibility are labeled', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: ReauthenticationScreen(action: 'delete account')),
    );

    expect(
      _decorationOf(tester, find.byType(TextFormField)).labelText,
      'Current password',
    );
    expect(find.byTooltip('Show password'), findsOneWidget);
  });
}
