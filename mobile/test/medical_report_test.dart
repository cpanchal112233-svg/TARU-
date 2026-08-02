import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/reports/domain/medical_report.dart';

void main() {
  group('MedicalReport', () {
    test('round-trips through toMap/fromMap', () {
      final MedicalReport original = MedicalReport(
        id: 'abc',
        title: 'CBC bloods',
        category: ReportCategory.lab,
        fileName: 'cbc.pdf',
        mimeType: 'application/pdf',
        storagePath: 'users/u1/reports/abc/cbc.pdf',
        sizeBytes: 12000,
        uploadedAt: DateTime.utc(2026, 8, 2, 12),
        takenOn: DateTime.utc(2026, 7, 30),
        notes: 'Fasting',
      );

      final MedicalReport? restored = MedicalReport.fromMap(
        'abc',
        original.toMap(),
      );

      expect(restored, isNotNull);
      expect(restored!.title, original.title);
      expect(restored.category, ReportCategory.lab);
      expect(restored.isPdf, isTrue);
      expect(restored.isImage, isFalse);
      expect(restored.notes, 'Fasting');
      expect(restored.takenOn, original.takenOn);
    });

    test('rejects incomplete maps', () {
      expect(MedicalReport.fromMap('x', <String, dynamic>{}), isNull);
    });

    test('unknown category falls back to other', () {
      final MedicalReport? report =
          MedicalReport.fromMap('x', <String, dynamic>{
            'title': 'Scan',
            'category': 'not-a-real-category',
            'fileName': 'scan.jpg',
            'mimeType': 'image/jpeg',
            'storagePath': 'users/u/reports/x/scan.jpg',
            'sizeBytes': 100,
            'uploadedAt': '2026-08-02T00:00:00.000Z',
          });

      expect(report?.category, ReportCategory.other);
      expect(report?.isImage, isTrue);
    });

    test('size label uses sensible units', () {
      final MedicalReport small = MedicalReport(
        id: '1',
        title: 't',
        category: ReportCategory.other,
        fileName: 'a.pdf',
        mimeType: 'application/pdf',
        storagePath: 'p',
        sizeBytes: 2048,
        uploadedAt: DateTime(2026),
      );

      expect(small.sizeLabel, '2 KB');

      final MedicalReport large = MedicalReport(
        id: '1',
        title: 't',
        category: ReportCategory.other,
        fileName: 'a.pdf',
        mimeType: 'application/pdf',
        storagePath: 'p',
        sizeBytes: 2 * 1024 * 1024,
        uploadedAt: DateTime(2026),
      );

      expect(large.sizeLabel, '2.0 MB');
    });
  });
}
