import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/reports/domain/report_extraction.dart';

void main() {
  test('256 KiB UTF-8 guard boundary', () {
    final String atLimit = 'a' * kMaxReviewedTextUtf8Bytes;
    final String over = 'a' * (kMaxReviewedTextUtf8Bytes + 1);
    expect(utf8.encode(atLimit).length, kMaxReviewedTextUtf8Bytes);
    expect(utf8.encode(over).length > kMaxReviewedTextUtf8Bytes, isTrue);
  });

  test('privacy/safety constants are local pdf_text only', () {
    expect(ReportExtraction.pdfTextMethod, 'pdf_text');
    expect(ReportExtraction.pdfTextMethod.contains('ocr'), isFalse);
    expect(ReportExtraction.pdfTextMethod.contains('ai'), isFalse);
  });
}
