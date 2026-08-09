import 'package:flutter/foundation.dart';

import 'blood_pressure_measurement.dart';
import 'weight_measurement.dart';

/// One raw chart observation. No interpolation or synthetic dates.
@immutable
class MeasurementChartPoint {
  const MeasurementChartPoint({
    required this.recordedAt,
    required this.value,
  });

  final DateTime recordedAt;
  final double value;
}

/// Builds chronological raw weight points (oldest → newest) for charting.
///
/// [weights] may arrive newest-first from Firestore; output is ascending time.
List<MeasurementChartPoint> weightChartPoints(
  List<WeightMeasurement> weights,
) {
  final List<WeightMeasurement> ordered = List<WeightMeasurement>.of(weights)
    ..sort((WeightMeasurement a, WeightMeasurement b) {
      final int time = a.recordedAt.compareTo(b.recordedAt);
      if (time != 0) return time;
      return a.id.compareTo(b.id);
    });

  return List<MeasurementChartPoint>.unmodifiable(
    ordered.map(
      (WeightMeasurement m) => MeasurementChartPoint(
        recordedAt: m.recordedAt,
        value: m.valueKg,
      ),
    ),
  );
}

/// Paired BP chart series at identical timestamps.
@immutable
class BloodPressureChartSeries {
  const BloodPressureChartSeries({
    required this.systolic,
    required this.diastolic,
  });

  final List<MeasurementChartPoint> systolic;
  final List<MeasurementChartPoint> diastolic;
}

/// Builds chronological raw BP points (oldest → newest) for dual-series charts.
BloodPressureChartSeries bloodPressureChartSeries(
  List<BloodPressureMeasurement> readings,
) {
  final List<BloodPressureMeasurement> ordered =
      List<BloodPressureMeasurement>.of(readings)
        ..sort((BloodPressureMeasurement a, BloodPressureMeasurement b) {
          final int time = a.recordedAt.compareTo(b.recordedAt);
          if (time != 0) return time;
          return a.id.compareTo(b.id);
        });

  return BloodPressureChartSeries(
    systolic: List<MeasurementChartPoint>.unmodifiable(
      ordered.map(
        (BloodPressureMeasurement m) => MeasurementChartPoint(
          recordedAt: m.recordedAt,
          value: m.systolicMmHg.toDouble(),
        ),
      ),
    ),
    diastolic: List<MeasurementChartPoint>.unmodifiable(
      ordered.map(
        (BloodPressureMeasurement m) => MeasurementChartPoint(
          recordedAt: m.recordedAt,
          value: m.diastolicMmHg.toDouble(),
        ),
      ),
    ),
  );
}
