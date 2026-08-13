import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf_manipulator/io.dart';
import 'package:pdf_manipulator/pdf_manipulator.dart';

import '../domain/report_extraction.dart';
import 'report_image_normalizer.dart';

typedef OcrPageProgress = void Function(int pageIndex, int pageCount);

/// Local on-device Latin OCR for report images and rendered PDF pages.
///
/// Persistence, medical parsing, and clinical interpretation are out of scope.
class LocalReportOcr {
  LocalReportOcr({ReportImageNormalizer? normalizer})
    : _normalizer = normalizer ?? ReportImageNormalizer();

  final ReportImageNormalizer _normalizer;

  /// Joins per-page OCR text, skipping blank pages with a blank line between.
  @visibleForTesting
  static String combinePageTexts(Iterable<String> pageTexts) {
    final StringBuffer combined = StringBuffer();
    for (final String raw in pageTexts) {
      final String pageText = raw.trim();
      if (pageText.isEmpty) continue;
      if (combined.isNotEmpty) {
        combined.writeln();
        combined.writeln();
      }
      combined.write(pageText);
    }
    return combined.toString();
  }

  /// OCR a local image report file. Returns trimmed-combined text or throws
  /// [ReportOcrException].
  Future<String> recognizeImageFile({
    required File source,
    required String reportId,
    bool Function()? isCanceled,
  }) async {
    final Directory work = await _ocrWorkDir(reportId);
    TextRecognizer? recognizer;
    try {
      if (isCanceled?.call() == true) {
        throw const ReportOcrException(ReportOcrFailure.canceled);
      }
      final File normalized = await _normalizer.normalizeToPngFile(
        source: source,
        workDir: work,
        reportId: reportId,
      );
      if (isCanceled?.call() == true) {
        throw const ReportOcrException(ReportOcrFailure.canceled);
      }
      recognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final RecognizedText result = await recognizer.processImage(
        InputImage.fromFilePath(normalized.path),
      );
      if (isCanceled?.call() == true) {
        throw const ReportOcrException(ReportOcrFailure.canceled);
      }
      final String text = result.text;
      if (text.trim().isEmpty) {
        throw const ReportOcrException(ReportOcrFailure.noTextFound);
      }
      return text;
    } on ReportOcrException {
      rethrow;
    } catch (error, stack) {
      developer.log(
        'image OCR failed',
        name: 'reports.ocr',
        error: error,
        stackTrace: stack,
      );
      throw ReportOcrException(ReportOcrFailure.ocrFailed, cause: error);
    } finally {
      await recognizer?.close();
      await _deleteQuietly(work);
    }
  }

  /// Render + OCR every page of a scanned PDF sequentially.
  ///
  /// Caller must only invoke this when selectable-text extraction is empty.
  Future<String> recognizeScannedPdfFile({
    required File source,
    required String reportId,
    OcrPageProgress? onPageProgress,
    bool Function()? isCanceled,
  }) async {
    final Directory work = await _ocrWorkDir(reportId);
    final Pdf pdf = Pdf();
    TextRecognizer? recognizer;
    try {
      if (isCanceled?.call() == true) {
        throw const ReportOcrException(ReportOcrFailure.canceled);
      }

      final PdfDoc doc = await pdf.open(FileSource(source));
      try {
        final int pageCount = doc.pageCount;
        if (pageCount <= 0) {
          throw const ReportOcrException(ReportOcrFailure.renderFailed);
        }

        recognizer = TextRecognizer(script: TextRecognitionScript.latin);
        final List<String> pageTexts = <String>[];
        int index = 0;

        await for (final RenderedPage page in doc.render(
          pages: PdfPages.all(),
          size: const PdfRenderSize(maxWidth: 1600, maxHeight: 2200),
        )) {
          if (isCanceled?.call() == true) {
            throw const ReportOcrException(ReportOcrFailure.canceled);
          }
          index += 1;
          onPageProgress?.call(index, pageCount);

          final File pageFile = File(
            p.join(work.path, 'page_${reportId}_$index.png'),
          );
          await pageFile.writeAsBytes(page.data, flush: true);
          try {
            final RecognizedText result = await recognizer.processImage(
              InputImage.fromFilePath(pageFile.path),
            );
            pageTexts.add(result.text);
          } finally {
            await _deleteQuietly(pageFile);
          }
        }

        if (isCanceled?.call() == true) {
          throw const ReportOcrException(ReportOcrFailure.canceled);
        }

        final String text = combinePageTexts(pageTexts);
        if (text.trim().isEmpty) {
          throw const ReportOcrException(ReportOcrFailure.noTextFound);
        }
        return text;
      } finally {
        await doc.dispose();
      }
    } on ReportOcrException {
      rethrow;
    } catch (error, stack) {
      developer.log(
        'scanned PDF OCR failed',
        name: 'reports.ocr',
        error: error,
        stackTrace: stack,
      );
      final bool looksRender = error.runtimeType.toString().contains('Pdf');
      throw ReportOcrException(
        looksRender ? ReportOcrFailure.renderFailed : ReportOcrFailure.ocrFailed,
        cause: error,
      );
    } finally {
      await recognizer?.close();
      await pdf.dispose();
      await _deleteQuietly(work);
    }
  }

  Future<Directory> _ocrWorkDir(String reportId) async {
    final Directory tmp = await getTemporaryDirectory();
    final Directory work = Directory(
      p.join(tmp.path, 'taru_ocr_$reportId'),
    );
    if (await work.exists()) {
      await work.delete(recursive: true);
    }
    await work.create(recursive: true);
    return work;
  }

  Future<void> _deleteQuietly(FileSystemEntity entity) async {
    try {
      if (await entity.exists()) {
        await entity.delete(recursive: entity is Directory);
      }
    } catch (_) {
      // Best-effort PHI temp cleanup.
    }
  }
}
