import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/constants/app_public_links.dart';
import 'package:mobile/features/profile/presentation/pages/help_support_screen.dart';

void main() {
  test('feedback URI is subject-only and carries no health payload', () {
    final Uri? uri = AppPublicLinks.feedbackLaunchUri(
      emailOverride: 'feedback@example.com',
    );
    expect(uri, isNotNull);
    expect(uri!.scheme, 'mailto');
    expect(uri.path, 'feedback@example.com');
    expect(uri.query, contains('subject='));
    expect(uri.query, contains(Uri.encodeComponent('TARU product feedback')));
    final String encoded = uri.toString().toLowerCase();
    expect(encoded.contains('medicine'), isFalse);
    expect(encoded.contains('condition'), isFalse);
    expect(encoded.contains('allergy'), isFalse);
    expect(encoded.contains('uid'), isFalse);
    expect(encoded.contains('measurement'), isFalse);
    expect(encoded.contains('evidence'), isFalse);
    expect(encoded.contains('ocr'), isFalse);
    expect(encoded.contains('body='), isFalse);
  });

  test('feedback URL path does not invent body content', () {
    final Uri? uri = AppPublicLinks.feedbackLaunchUri(
      urlOverride: 'https://example.com/feedback',
    );
    expect(uri.toString(), 'https://example.com/feedback');
  });

  testWidgets('unconfigured feedback action is hidden', (
    WidgetTester tester,
  ) async {
    expect(AppPublicLinks.hasFeedbackDestination, isFalse);
    await tester.pumpWidget(const MaterialApp(home: HelpSupportScreen()));
    expect(find.text('Send product feedback'), findsNothing);
    expect(find.text('Contact support'), findsNothing);
    expect(find.textContaining('does not diagnose'), findsOneWidget);
    expect(find.text('Privacy & data'), findsOneWidget);
  });

  testWidgets('configured feedback action is visible and distinct', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: HelpSupportScreen(
          feedbackEmailOverride: 'feedback@example.com',
        ),
      ),
    );
    expect(find.text('Send product feedback'), findsOneWidget);
    expect(find.textContaining('not emergency care'), findsOneWidget);
    expect(find.text('Contact support'), findsNothing);
    expect(find.textContaining('does not diagnose'), findsOneWidget);
  });

  testWidgets('200% text keeps feedback entry operable when configured', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
        child: const MaterialApp(
          home: HelpSupportScreen(
            feedbackEmailOverride: 'feedback@example.com',
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Send product feedback'));
    expect(find.text('Send product feedback'), findsOneWidget);
  });
}
