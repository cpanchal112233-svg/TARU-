import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/constants/strings.dart';
import 'package:mobile/features/auth/application/auth_providers.dart';
import 'package:mobile/features/auth/data/auth_service.dart';
import 'package:mobile/features/auth/presentation/pages/login_screen.dart';
import 'package:mobile/features/auth/presentation/widgets/auth_button.dart';

class _SlowAuthService extends AuthService {
  final Completer<UserCredential> completer = Completer<UserCredential>();
  int loginCalls = 0;

  @override
  Future<UserCredential> login({
    required String email,
    required String password,
  }) {
    loginCalls += 1;
    return completer.future;
  }
}

void main() {
  testWidgets('login action is genuinely disabled while loading', (
    WidgetTester tester,
  ) async {
    final _SlowAuthService fake = _SlowAuthService();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authServiceProvider.overrideWith((Ref ref) => fake),
        ],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    await tester.enterText(find.byType(TextFormField).at(0), 'user@example.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'password');
    await tester.tap(find.widgetWithText(ElevatedButton, AppStrings.login));
    await tester.pump();

    expect(fake.loginCalls, 1);
    final AuthButton button = tester.widget<AuthButton>(find.byType(AuthButton));
    expect(button.onPressed, isNull);
    expect(find.text('Logging in...'), findsOneWidget);

    await tester.tap(find.byType(AuthButton));
    await tester.pump();
    expect(fake.loginCalls, 1);
  });
}
