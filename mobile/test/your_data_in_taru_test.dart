import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/constants/app_public_links.dart';
import 'package:mobile/features/privacy/domain/your_data_inventory.dart';
import 'package:mobile/features/privacy/presentation/pages/privacy_data_screen.dart';
import 'package:mobile/features/privacy/presentation/pages/your_data_in_taru_screen.dart';

void main() {
  test('inventory categories match current product surfaces', () {
    final Set<String> titles = YourDataInventory.categories
        .map((YourDataCategory c) => c.title)
        .toSet();
    expect(
      titles,
      containsAll(<String>[
        'Account',
        'Health profile',
        'Measurements',
        'Routine',
        'Reports',
        'Evidence Brief',
        'Crash diagnostics',
      ]),
    );
    expect(titles.contains('Analytics'), isFalse);
    expect(titles.contains('HealthKit'), isFalse);
  });

  test('Evidence Brief is generated and not cloud-persisted', () {
    final YourDataCategory brief = YourDataInventory.categories.firstWhere(
      (YourDataCategory c) => c.title == 'Evidence Brief',
    );
    expect(brief.location.toLowerCase(), contains('generated'));
    expect(brief.location.toLowerCase(), contains('not stored'));
    expect(
      brief.bullets.any(
        (String b) => b.toLowerCase().contains('not saved to the cloud'),
      ),
      isTrue,
    );
    expect(
      YourDataInventory.doesNotDo.any(
        (String p) =>
            p.contains('Evidence Brief') && p.contains('clinical assessment'),
      ),
      isTrue,
    );
  });

  test('crash diagnostics described as opt-in default off', () {
    final YourDataCategory crash = YourDataInventory.categories.firstWhere(
      (YourDataCategory c) => c.title == 'Crash diagnostics',
    );
    final String joined = '${crash.bullets.join(' ')} ${crash.location}';
    expect(joined.toLowerCase(), contains('optional'));
    expect(joined.toLowerCase(), contains('default is off'));
  });

  test('does not claim Analytics use; states Analytics is unused', () {
    expect(
      YourDataInventory.doesNotDo.any(
        (String p) => p.contains('does not use Firebase Analytics'),
      ),
      isTrue,
    );
    final String blob = YourDataInventory.categories
        .expand((YourDataCategory c) => c.bullets)
        .join(' ');
    expect(blob.toLowerCase().contains('firebase analytics'), isFalse);
  });

  test('inventory never exposes internal Firebase paths or UIDs', () {
    final String blob = <String>[
      YourDataInventory.intro,
      ...YourDataInventory.categories.expand(
        (YourDataCategory c) => <String>[
          c.title,
          c.source,
          c.location,
          ...c.bullets,
        ],
      ),
      ...YourDataInventory.doesNotDo,
    ].join('\n');
    expect(blob.contains('users/'), isFalse);
    expect(blob.toLowerCase().contains('firestore'), isFalse);
    expect(blob.contains('europe-west2'), isFalse);
    expect(blob.contains('purgeUserData'), isFalse);
    expect(RegExp(r'\buid\b', caseSensitive: false).hasMatch(blob), isFalse);
    expect(
      RegExp(r'users/\{?uid\}?', caseSensitive: false).hasMatch(blob),
      isFalse,
    );
  });

  testWidgets('Your data screen shows categories and control links', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: YourDataInTaruScreen()),
      ),
    );

    expect(find.text('Your data in TARU'), findsWidgets);
    expect(find.text('Account'), findsOneWidget);
    expect(find.text('Evidence Brief'), findsOneWidget);
    expect(find.text('Crash diagnostics'), findsOneWidget);
    expect(
      find.textContaining('does not use Firebase Analytics'),
      findsOneWidget,
    );
    expect(find.text('Export my health data'), findsOneWidget);
    expect(find.text('Delete my health data'), findsOneWidget);
    expect(find.text('Delete TARU account'), findsOneWidget);
    expect(find.textContaining('users/'), findsNothing);
    expect(find.textContaining('Firestore'), findsNothing);

    await tester.ensureVisible(find.text('Export my health data'));
    await tester.tap(find.text('Export my health data'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(PrivacyDataScreen), findsOneWidget);
    expect(find.text('Your data in TARU'), findsWidgets);
  });

  testWidgets('200% text keeps Your data operable', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        child: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
          child: const MaterialApp(home: YourDataInTaruScreen()),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Your data in TARU'), findsWidgets);
    await tester.ensureVisible(find.text('Delete TARU account'));
    expect(find.text('Delete TARU account'), findsOneWidget);
  });

  test('public feedback destination remains unconfigured by default', () {
    expect(AppPublicLinks.hasFeedbackDestination, isFalse);
    expect(AppPublicLinks.feedbackLaunchUri(), isNull);
  });
}
