import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/measurements/domain/blood_pressure_measurement.dart';
import 'package:mobile/features/measurements/domain/measurement_chart_points.dart';
import 'package:mobile/features/measurements/domain/weight_measurement.dart';

void main() {
  group('weightChartPoints', () {
    test('one reading -> one point; raw value preserved', () {
      final DateTime at = DateTime.utc(2026, 8, 1, 12);
      final List<MeasurementChartPoint> points = weightChartPoints(<
        WeightMeasurement
      >[
        WeightMeasurement(id: 'a', valueKg: 70.5, recordedAt: at),
      ]);
      expect(points, hasLength(1));
      expect(points.single.value, 70.5);
      expect(points.single.recordedAt, at);
    });

    test('chronological ascending; same-day retained; no synthetic days', () {
      final DateTime morning = DateTime.utc(2026, 8, 1, 8);
      final DateTime evening = DateTime.utc(2026, 8, 1, 20);
      final DateTime nextDay = DateTime.utc(2026, 8, 3, 9);

      final List<MeasurementChartPoint> points = weightChartPoints(<
        WeightMeasurement
      >[
        WeightMeasurement(id: 'c', valueKg: 72, recordedAt: nextDay),
        WeightMeasurement(id: 'b', valueKg: 71, recordedAt: evening),
        WeightMeasurement(id: 'a', valueKg: 70, recordedAt: morning),
      ]);

      expect(points.map((MeasurementChartPoint p) => p.value).toList(), <double>[
        70,
        71,
        72,
      ]);
      expect(points, hasLength(3));
      // Gap day 2 is not fabricated.
      expect(
        points.map((MeasurementChartPoint p) => p.recordedAt.day).toSet(),
        <int>{1, 3},
      );
    });
  });

  group('bloodPressureChartSeries', () {
    test('one reading -> paired points at same x; exact mmHg', () {
      final DateTime at = DateTime.utc(2026, 8, 1, 12);
      final BloodPressureChartSeries series = bloodPressureChartSeries(<
        BloodPressureMeasurement
      >[
        BloodPressureMeasurement(
          id: 'bp',
          systolicMmHg: 128,
          diastolicMmHg: 84,
          recordedAt: at,
        ),
      ]);

      expect(series.systolic, hasLength(1));
      expect(series.diastolic, hasLength(1));
      expect(series.systolic.single.value, 128);
      expect(series.diastolic.single.value, 84);
      expect(series.systolic.single.recordedAt, at);
      expect(series.diastolic.single.recordedAt, at);
    });

    test('chronological; same-day retained; no synthetic observations', () {
      final DateTime a = DateTime.utc(2026, 8, 1, 8);
      final DateTime b = DateTime.utc(2026, 8, 1, 18);
      final BloodPressureChartSeries series = bloodPressureChartSeries(<
        BloodPressureMeasurement
      >[
        BloodPressureMeasurement(
          id: '2',
          systolicMmHg: 130,
          diastolicMmHg: 85,
          recordedAt: b,
        ),
        BloodPressureMeasurement(
          id: '1',
          systolicMmHg: 120,
          diastolicMmHg: 80,
          recordedAt: a,
        ),
      ]);

      expect(
        series.systolic.map((MeasurementChartPoint p) => p.value).toList(),
        <double>[120, 130],
      );
      expect(series.systolic, hasLength(2));
      expect(series.diastolic, hasLength(2));
    });
  });
}
