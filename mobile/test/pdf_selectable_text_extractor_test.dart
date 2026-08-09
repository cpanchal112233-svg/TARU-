import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/reports/data/pdf_selectable_text_extractor.dart';
import 'package:mobile/features/reports/domain/report_extraction.dart';

String _fixture(String name) {
  // Resolves from package root when running `flutter test`.
  final File file = File('test/fixtures/reports/$name');
  expect(file.existsSync(), isTrue, reason: 'missing fixture $name');
  return file.path;
}

void main() {
  final PdfSelectableTextExtractor extractor = PdfSelectableTextExtractor();

  test('extracts known selectable text from digital PDF', () async {
    final String text = await extractor.extractFromFile(
      File(_fixture('digital_single.pdf')),
    );
    expect(text.contains('ALPHA-ONE'), isTrue);
    expect(text.trim().isNotEmpty, isTrue);
  });

  test('extracts text from multiple pages', () async {
    final String text = await extractor.extractFromFile(
      File(_fixture('digital_multi.pdf')),
    );
    expect(text.contains('BETA'), isTrue);
    expect(text.contains('GAMMA'), isTrue);
    expect(text.contains('DELTA'), isTrue);
  });

  test('medical-style synthetic labels survive', () async {
    final String text = await extractor.extractFromFile(
      File(_fixture('digital_medical_style.pdf')),
    );
    expect(text.contains('WBC'), isTrue);
    expect(text.contains('HGB'), isTrue);
  });

  test('scanned/image-only PDF returns empty selectable text', () async {
    final String text = await extractor.extractFromFile(
      File(_fixture('scanned_image_only.pdf')),
    );
    expect(text.trim(), isEmpty);
  });

  test('malformed PDF maps to ReportTextExtractionException', () async {
    await expectLater(
      extractor.extractFromFile(File(_fixture('malformed.pdf'))),
      throwsA(isA<ReportTextExtractionException>()),
    );
  });
}
