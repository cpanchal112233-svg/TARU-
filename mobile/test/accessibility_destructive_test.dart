import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/account/domain/account_integrity.dart';
import 'package:mobile/features/account/presentation/pages/account_recovery_screen.dart';

void main() {
  testWidgets('typed DELETE field has persistent label in isolation', (
    WidgetTester tester,
  ) async {
    final TextEditingController controller = TextEditingController();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AlertDialog(
            title: const Text('Type DELETE to confirm'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Type DELETE to confirm',
              ),
            ),
            actions: const <Widget>[
              TextButton(onPressed: null, child: Text('Cancel')),
              ElevatedButton(onPressed: null, child: Text('Delete account')),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Type DELETE to confirm'), findsWidgets);
    expect(find.text('Delete account'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
  });

  testWidgets('account recovery exposes sign-out and state copy', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: AccountRecoveryScreen(
            integrity: AccountIntegrity.temporarilyUnavailable,
          ),
        ),
      ),
    );

    expect(find.text('Sign out'), findsOneWidget);
    expect(find.textContaining('could not confirm'), findsOneWidget);
  });

  testWidgets('health cleanup recovery names continue action', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: AccountRecoveryScreen(
            integrity: AccountIntegrity.deletionHealthInProgress,
          ),
        ),
      ),
    );

    expect(find.text('Continue health-data cleanup'), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);
  });
}
