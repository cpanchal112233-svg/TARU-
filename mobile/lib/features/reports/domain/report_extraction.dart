import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Maximum UTF-8 size for the confirmed reviewed-text sidecar (Phase 9).
///
/// Mobile review/edit usability guard — not a Firestore document limit.
const int kMaxReviewedTextUtf8Bytes = 256 * 1024;

/// Provenance for a user-reviewed selectable-PDF text extraction.
///
/// Stored at `users/{uid}/reports/{reportId}/extraction/current`.
/// Absence of that document means no saved reviewed extraction.
@immutable
class ReportExtraction {
  const ReportExtraction({required this.method, required this.reviewedAt});

  static const String pdfTextMethod = 'pdf_text';

  /// Always [pdfTextMethod] for Phase 9 selectable-PDF text.
  final String method;

  /// Client time when the user confirmed the reviewed text.
  final DateTime reviewedAt;

  Map<String, dynamic> toMap() => <String, dynamic>{
    'method': method,
    'reviewedAt': Timestamp.fromDate(reviewedAt),
  };

  /// Returns null for missing/malformed/unsupported method values.
  static ReportExtraction? fromMap(Map<String, dynamic>? map) {
    if (map == null) return null;

    final Object? method = map['method'];
    if (method is! String || method != pdfTextMethod) return null;

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
