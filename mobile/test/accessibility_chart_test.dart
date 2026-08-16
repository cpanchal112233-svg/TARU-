import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/measurements/domain/measurement_chart_points.dart';
import 'package:mobile/features/measurements/presentation/widgets/raw_measurement_chart.dart';

void main() {
  testWidgets('chart summary points users to the exact list below', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: <Widget>[
              RawMeasurementChart(
                semanticsLabel:
                    'Weight chart. Exact measurements are listed below.',
                series: <RawChartSeries>[
                  RawChartSeries(
                    color: Colors.blue,
                    points: <MeasurementChartPoint>[
                      MeasurementChartPoint(
                        recordedAt: DateTime(2026, 8, 1),
                        value: 70,
                      ),
                      MeasurementChartPoint(
                        recordedAt: DateTime(2026, 8, 8),
                        value: 71,
                      ),
                    ],
                  ),
                ],
              ),
              const ListTile(title: Text('70.0 kg')),
              const ListTile(title: Text('71.0 kg')),
            ],
          ),
        ),
      ),
    );

    expect(
      find.bySemanticsLabel(
        'Weight chart. Exact measurements are listed below.',
      ),
      findsOneWidget,
    );
    expect(find.text('70.0 kg'), findsOneWidget);
    expect(find.text('71.0 kg'), findsOneWidget);
  });
}
