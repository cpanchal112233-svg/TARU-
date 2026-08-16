import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/progress/application/progress_providers.dart';

class _DayStripSample extends StatelessWidget {
  const _DayStripSample({required this.days});

  final List<ProgressDayRecord> days;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final ProgressDayRecord day in days)
          Expanded(
            child: Semantics(
              label: day.hasRecord
                  ? '${_weekdayName(day.dateKey)}, activity recorded'
                  : '${_weekdayName(day.dateKey)}, no activity recorded',
              child: const SizedBox(height: 24),
            ),
          ),
      ],
    );
  }

  String _weekdayName(String dateKey) {
    final DateTime? date = DateTime.tryParse(dateKey);
    if (date == null) return 'Day';
    const List<String> names = <String>[
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return names[date.weekday - 1];
  }
}

void main() {
  testWidgets('progress day strip exposes day and record state', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: _DayStripSample(
            days: <ProgressDayRecord>[
              ProgressDayRecord(dateKey: '2026-08-10', hasRecord: true),
              ProgressDayRecord(dateKey: '2026-08-11', hasRecord: false),
            ],
          ),
        ),
      ),
    );

    expect(find.bySemanticsLabel('Monday, activity recorded'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Tuesday, no activity recorded'),
      findsOneWidget,
    );
  });
}
