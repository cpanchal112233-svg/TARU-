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
}
