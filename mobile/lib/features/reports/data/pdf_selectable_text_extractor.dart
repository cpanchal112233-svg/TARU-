import 'dart:io';

import 'package:pdf_manipulator/io.dart';
import 'package:pdf_manipulator/pdf_manipulator.dart';

import '../domain/report_extraction.dart';

/// Local selectable-text extraction for digital PDFs.
///
/// Uses [pdf_manipulator] on-device. No OCR, no network document processing,
/// no medical interpretation. Empty trimmed text means no selectable text
/// (typical for scanned/image-only PDFs).
class PdfSelectableTextExtractor {
  /// Opens [file], extracts text from all pages, and disposes resources.
  ///
  /// Returns raw extracted text (may be empty). Throws
  /// [ReportTextExtractionException] on package/engine failures.
  Future<String> extractFromFile(File file) async {
    final Pdf pdf = Pdf();
    try {
      final PdfDoc doc = await pdf.open(FileSource(file));
      try {
        return await doc.extract(pages: PdfPages.all());
      } finally {
        await doc.dispose();
      }
    } on ReportTextExtractionException {
      rethrow;
    } catch (error) {
      throw ReportTextExtractionException(
        'Could not extract text from this PDF.',
        cause: error,
      );
    } finally {
      await pdf.dispose();
    }
  }
}
