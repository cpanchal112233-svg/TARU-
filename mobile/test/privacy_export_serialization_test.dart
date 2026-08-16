import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/privacy/data/health_export_service.dart';
import 'package:mobile/features/privacy/domain/purge_mode.dart';

void main() {
  group('Phase 10 privacy domain', () {
    test('purge mode wire values', () {
      expect(PurgeMode.health.wireValue, 'health');
      expect(PurgeMode.account.wireValue, 'account');
    });

    test('export timestamp stamp format', () {
      final String stamp = HealthExportService.debugTimestampStamp(
        DateTime(2026, 8, 9, 12, 5, 7),
      );
      expect(stamp, matches(RegExp(r'^\d{8}-\d{6}$')));
    });
  });

  group('Phase 11 measurement export serialization', () {
    test('weight export row preserves Phase 10 shape', () {
      final DateTime at = DateTime.utc(2026, 8, 1, 10, 30);
      final Map<String, dynamic> row =
          HealthExportService.serializeWeightExportRow('w1', <String, dynamic>{
            'type': 'weight',
            'valueKg': 72.4,
            'source': 'manual',
            'recordedAt': Timestamp.fromDate(at),
          });

      expect(row.keys.toSet(), <String>{
        'id',
        'type',
        'valueKg',
        'source',
        'recordedAt',
      });
      expect(row['id'], 'w1');
      expect(row['type'], 'weight');
      expect(row['valueKg'], 72.4);
      expect(row['source'], 'manual');
      expect(row['recordedAt'], at.toUtc().toIso8601String());
      expect(row.containsKey('category'), isFalse);
    });

    test('blood pressure export row is canonical mmHg without pulse', () {
      final DateTime at = DateTime.utc(2026, 8, 2, 8, 0);
      final Map<String, dynamic> row =
          HealthExportService.serializeBloodPressureExportRow(
            'bp1',
            <String, dynamic>{
              'type': 'blood_pressure',
              'systolicMmHg': 120,
              'diastolicMmHg': 80,
              'source': 'manual',
              'recordedAt': Timestamp.fromDate(at),
              'pulseBpm': 72, // must not be copied even if present
            },
          );

      expect(row.keys.toSet(), <String>{
        'id',
        'type',
        'systolicMmHg',
        'diastolicMmHg',
        'source',
        'recordedAt',
      });
      expect(row['systolicMmHg'], 120);
      expect(row['diastolicMmHg'], 80);
      expect(row['recordedAt'], at.toUtc().toIso8601String());
      expect(row.containsKey('pulseBpm'), isFalse);
      expect(row.containsKey('category'), isFalse);
      expect(row.containsKey('interpretation'), isFalse);
    });

    test('empty BP history serializes as empty list representation', () {
      expect(const <Map<String, dynamic>>[], isEmpty);
    });
  });
}
