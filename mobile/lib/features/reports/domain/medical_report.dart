import 'package:flutter/foundation.dart';

/// What kind of document this is, so the list can be filtered later and AI
/// explanations can be specialised without re-reading the file.
enum ReportCategory {
  lab('Lab results'),
  imaging('Scan or X-ray'),
  prescription('Prescription'),
  discharge('Discharge summary'),
  other('Other document');

  const ReportCategory(this.label);

  final String label;
}

/// One uploaded medical document and the metadata needed to find it again.
@immutable
class MedicalReport {
  const MedicalReport({
    required this.id,
    required this.title,
    required this.category,
    required this.fileName,
    required this.mimeType,
    required this.storagePath,
    required this.sizeBytes,
    required this.uploadedAt,
    this.takenOn,
    this.notes,
  });

  final String id;
  final String title;
  final ReportCategory category;
  final String fileName;
  final String mimeType;
  final String storagePath;
  final int sizeBytes;
  final DateTime uploadedAt;

  /// When the test or letter was actually done, if the user knows it.
  final DateTime? takenOn;

  final String? notes;

  bool get isPdf =>
      mimeType == 'application/pdf' || fileName.toLowerCase().endsWith('.pdf');

  bool get isImage => mimeType.startsWith('image/');

  String get sizeLabel {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(0)} KB';
    }
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  MedicalReport copyWith({
    String? title,
    ReportCategory? category,
    DateTime? takenOn,
    String? notes,
  }) {
    return MedicalReport(
      id: id,
      title: title ?? this.title,
      category: category ?? this.category,
      fileName: fileName,
      mimeType: mimeType,
      storagePath: storagePath,
      sizeBytes: sizeBytes,
      uploadedAt: uploadedAt,
      takenOn: takenOn ?? this.takenOn,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'title': title,
    'category': category.name,
    'fileName': fileName,
    'mimeType': mimeType,
    'storagePath': storagePath,
    'sizeBytes': sizeBytes,
    'uploadedAt': uploadedAt.toIso8601String(),
    'takenOn': takenOn?.toIso8601String(),
    'notes': notes?.trim().isEmpty ?? true ? null : notes?.trim(),
  };

  static MedicalReport? fromMap(String id, Map<String, dynamic> map) {
    final String? title = _string(map['title']);
    final String? fileName = _string(map['fileName']);
    final String? mimeType = _string(map['mimeType']);
    final String? storagePath = _string(map['storagePath']);
    final Object? size = map['sizeBytes'];
    final DateTime? uploadedAt = _date(map['uploadedAt']);

    if (title == null ||
        fileName == null ||
        mimeType == null ||
        storagePath == null ||
        size is! num ||
        uploadedAt == null) {
      return null;
    }

    return MedicalReport(
      id: id,
      title: title,
      category: _category(map['category']),
      fileName: fileName,
      mimeType: mimeType,
      storagePath: storagePath,
      sizeBytes: size.toInt(),
      uploadedAt: uploadedAt,
      takenOn: _date(map['takenOn']),
      notes: _string(map['notes']),
    );
  }

  static ReportCategory _category(Object? code) {
    if (code is! String) return ReportCategory.other;

    for (final ReportCategory candidate in ReportCategory.values) {
      if (candidate.name == code) return candidate;
    }

    return ReportCategory.other;
  }

  static String? _string(Object? value) => value is String ? value : null;

  static DateTime? _date(Object? value) {
    if (value is String) return DateTime.tryParse(value);
    if (value is DateTime) return value;
    return null;
  }
}
