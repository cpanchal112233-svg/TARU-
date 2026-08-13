import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Maximum UTF-8 size for the confirmed reviewed-text sidecar (Phase 9/12).
///
/// Mobile review/edit usability guard — not a Firestore document limit.
const int kMaxReviewedTextUtf8Bytes = 256 * 1024;

/// How reviewed report text was produced before user confirmation.
enum ReportExtractionMethod {
  pdfText('pdf_text'),
  ocr('ocr');

  const ReportExtractionMethod(this.storageValue);

  final String storageValue;

  static ReportExtractionMethod? tryParse(String value) {
    for (final ReportExtractionMethod method in ReportExtractionMethod.values) {
      if (method.storageValue == value) return method;
    }
    return null;
  }
}

/// Provenance for a user-reviewed report text extraction.
///
/// Stored at `users/{uid}/reports/{reportId}/extraction/current`.
/// Absence of that document means no saved reviewed extraction.
@immutable
class ReportExtraction {
  const ReportExtraction({required this.method, required this.reviewedAt});

  static const String pdfTextMethod = 'pdf_text';
  static const String ocrMethod = 'ocr';

  /// [pdfTextMethod] for selectable PDF text, or [ocrMethod] for local OCR.
  final String method;

  /// Client time when the user confirmed the reviewed text.
  final DateTime reviewedAt;

  bool get isOcr => method == ocrMethod;

  bool get isPdfText => method == pdfTextMethod;

  Map<String, dynamic> toMap() => <String, dynamic>{
    'method': method,
    'reviewedAt': Timestamp.fromDate(reviewedAt),
  };

  /// Returns null for missing/malformed/unsupported method values.
  static ReportExtraction? fromMap(Map<String, dynamic>? map) {
    if (map == null) return null;

    final Object? method = map['method'];
    if (method is! String || ReportExtractionMethod.tryParse(method) == null) {
      return null;
    }

    final DateTime? reviewedAt = _date(map['reviewedAt']);
    if (reviewedAt == null) return null;

    return ReportExtraction(method: method, reviewedAt: reviewedAt);
  }

  static DateTime? _date(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}

/// Deterministic Storage path for the reviewed extracted text sidecar.
String reviewedExtractionStoragePath(String uid, String reportId) =>
    'users/$uid/reports/$reportId/derived/extracted.txt';

/// User-facing failures from local selectable-text extraction.
class ReportTextExtractionException implements Exception {
  const ReportTextExtractionException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => message;
}

/// Domain failures from local OCR / scanned-PDF rendering.
enum ReportOcrFailure {
  unsupportedReport,
  noTextFound,
  renderFailed,
  ocrFailed,
  reviewedTextTooLarge,
  canceled,
}

class ReportOcrException implements Exception {
  const ReportOcrException(this.failure, {this.message, this.cause});

  final ReportOcrFailure failure;
  final String? message;
  final Object? cause;

  String get userMessage {
    switch (failure) {
      case ReportOcrFailure.unsupportedReport:
        return 'Text reading is not available for this report type.';
      case ReportOcrFailure.noTextFound:
        return 'No readable text was found. If the report is sideways, '
            'rotate it and try again.';
      case ReportOcrFailure.renderFailed:
        return 'Could not read pages from this PDF. Please try again.';
      case ReportOcrFailure.ocrFailed:
        return 'Could not read text from this report. Please try again.';
      case ReportOcrFailure.reviewedTextTooLarge:
        return 'Reviewed text is too large to save in this release '
            '(max ${kMaxReviewedTextUtf8Bytes ~/ 1024} KiB).';
      case ReportOcrFailure.canceled:
        return 'Text reading was canceled.';
    }
  }

  @override
  String toString() => message ?? userMessage;
}
