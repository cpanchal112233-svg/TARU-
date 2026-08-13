import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/reports/domain/report_extraction.dart';

void main() {
  group('ReportExtraction', () {
    test('parses valid pdf_text metadata', () {
      final DateTime reviewedAt = DateTime.utc(2026, 8, 9, 12);
      final ReportExtraction? parsed = ReportExtraction.fromMap(
        <String, dynamic>{
          'method': 'pdf_text',
          'reviewedAt': Timestamp.fromDate(reviewedAt),
        },
      );

      expect(parsed, isNotNull);
      expect(parsed!.method, ReportExtraction.pdfTextMethod);
      expect(parsed.reviewedAt.toUtc(), reviewedAt);
    });

    test('round-trips through toMap', () {
      final ReportExtraction original = ReportExtraction(
        method: ReportExtraction.pdfTextMethod,
        reviewedAt: DateTime.utc(2026, 8, 9, 15, 30),
      );

      final ReportExtraction? restored = ReportExtraction.fromMap(
        original.toMap(),
      );
      expect(restored?.method, original.method);
      expect(restored?.reviewedAt.toUtc(), original.reviewedAt.toUtc());
    });

    test('rejects missing map', () {
      expect(ReportExtraction.fromMap(null), isNull);
    });

    test('parses valid ocr metadata', () {
      final DateTime reviewedAt = DateTime.utc(2026, 8, 9, 14);
      final ReportExtraction? parsed = ReportExtraction.fromMap(
        <String, dynamic>{
          'method': 'ocr',
          'reviewedAt': Timestamp.fromDate(reviewedAt),
        },
      );

      expect(parsed, isNotNull);
      expect(parsed!.method, ReportExtraction.ocrMethod);
      expect(parsed.isOcr, isTrue);
      expect(parsed.reviewedAt.toUtc(), reviewedAt);
    });

    test('rejects unsupported method', () {
      expect(
        ReportExtraction.fromMap(<String, dynamic>{
          'method': 'ai',
          'reviewedAt': Timestamp.fromDate(DateTime.utc(2026, 8, 9)),
        }),
        isNull,
      );
      expect(
        ReportExtraction.fromMap(<String, dynamic>{
          'method': 'image_ocr',
          'reviewedAt': Timestamp.fromDate(DateTime.utc(2026, 8, 9)),
        }),
        isNull,
      );
    });

    test('rejects missing reviewedAt', () {
      expect(
        ReportExtraction.fromMap(<String, dynamic>{'method': 'pdf_text'}),
        isNull,
      );
    });

    test('storage path is deterministic', () {
      expect(
        reviewedExtractionStoragePath('u1', 'r1'),
        'users/u1/reports/r1/derived/extracted.txt',
      );
    });
  });
}
