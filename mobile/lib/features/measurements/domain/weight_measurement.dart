import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Discriminator for weight documents in `users/{uid}/measurements`.
///
/// Sibling typed documents (e.g. blood pressure) share the collection but
/// use their own shapes — not an untyped values bag.
const String measurementTypeWeight = 'weight';

/// How a measurement entered TARU. Phase 8 only writes [manual].
const String measurementSourceManual = 'manual';

/// One intentional weight recording.
@immutable
class WeightMeasurement {
  const WeightMeasurement({
    required this.id,
    required this.valueKg,
    required this.recordedAt,
    this.source = measurementSourceManual,
  });

  final String id;
  final double valueKg;
  final DateTime recordedAt;
  final String source;

  Map<String, dynamic> toMap({required Timestamp recordedAtTimestamp}) {
    return <String, dynamic>{
      'type': measurementTypeWeight,
      'valueKg': valueKg,
      'source': source,
      'recordedAt': recordedAtTimestamp,
    };
  }

  /// Returns null when the document is not a usable weight measurement.
  static WeightMeasurement? fromMap(String id, Map<String, dynamic>? map) {
    if (map == null) return null;
    if (map['type'] != measurementTypeWeight) return null;

    final Object? rawValue = map['valueKg'];
    final double? valueKg = switch (rawValue) {
      final num n => n.toDouble(),
      _ => null,
    };
    if (valueKg == null) return null;

    final Object? rawAt = map['recordedAt'];
    final DateTime? recordedAt = switch (rawAt) {
      final Timestamp t => t.toDate(),
      final DateTime d => d,
      _ => null,
    };
    if (recordedAt == null) return null;

    final Object? rawSource = map['source'];
    final String source = rawSource is String && rawSource.isNotEmpty
        ? rawSource
        : measurementSourceManual;

    return WeightMeasurement(
      id: id,
      valueKg: valueKg,
      recordedAt: recordedAt,
      source: source,
    );
  }
}

/// Structural bounds matching Health Profile weight validation (typo catch).
bool isPlausibleWeightKg(double kilograms) =>
    kilograms >= 2 && kilograms <= 400;

/// True when [next] is a non-null intentional change from [previous].
bool isIntentionalNewWeight({
  required double? previous,
  required double? next,
}) {
  if (next == null) return false;
  if (previous == null) return true;
  return (previous - next).abs() > 0.0001;
}
