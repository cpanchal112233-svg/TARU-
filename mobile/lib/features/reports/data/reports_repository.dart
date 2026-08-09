import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as p;

import '../domain/medical_report.dart';
import '../domain/report_extraction.dart';
import 'report_object_store.dart';

/// Owns Storage objects and Firestore metadata for medical reports.
///
/// Phase 9 also owns the reviewed extracted-text sidecar and its provenance
/// document. Cross-service writes are ordered and retry-safe, but not atomic.
class ReportsRepository {
  ReportsRepository(
    this._firestore, {
    FirebaseStorage? storage,
    ReportObjectStore? objects,
  }) : assert(
         objects != null || storage != null,
         'Provide FirebaseStorage or a ReportObjectStore.',
       ),
       _objects = objects ?? FirebaseReportObjectStore(storage!);

  final FirebaseFirestore _firestore;
  final ReportObjectStore _objects;

  CollectionReference<Map<String, dynamic>> _collection(String uid) =>
      _firestore.collection('users').doc(uid).collection('reports');

  DocumentReference<Map<String, dynamic>> _extractionDoc(
    String uid,
    String reportId,
  ) => _collection(uid).doc(reportId).collection('extraction').doc('current');

  Stream<List<MedicalReport>> watch(String uid) {
    return _collection(uid)
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
          final List<MedicalReport> reports = <MedicalReport>[];

          for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
              in snapshot.docs) {
            final Map<String, dynamic> data = _normalise(doc.data());
            final MedicalReport? report = MedicalReport.fromMap(doc.id, data);
            if (report != null) reports.add(report);
          }

          return reports;
        });
  }

  /// Uploads the bytes, then writes the metadata document.
  Future<MedicalReport> upload({
    required String uid,
    required String title,
    required ReportCategory category,
    required String fileName,
    required String mimeType,
    required Uint8List bytes,
    DateTime? takenOn,
    String? notes,
    void Function(double progress)? onProgress,
  }) async {
    final String reportId = _collection(uid).doc().id;
    final String safeName = _safeFileName(fileName);
    final String storagePath = 'users/$uid/reports/$reportId/$safeName';

    await _objects.putData(
      storagePath,
      bytes,
      contentType: mimeType,
      customMetadata: <String, String>{'originalFileName': fileName},
      onProgress: onProgress,
    );

    final DateTime uploadedAt = DateTime.now();
    final MedicalReport report = MedicalReport(
      id: reportId,
      title: title.trim().isEmpty ? _titleFromFileName(fileName) : title.trim(),
      category: category,
      fileName: safeName,
      mimeType: mimeType,
      storagePath: storagePath,
      sizeBytes: bytes.length,
      uploadedAt: uploadedAt,
      takenOn: takenOn,
      notes: notes,
    );

    await _collection(uid).doc(reportId).set(report.toMap());

    return report;
  }

  Future<String> downloadUrl(MedicalReport report) {
    return _objects.downloadUrl(report.storagePath);
  }

  Future<File> downloadToTemp(MedicalReport report) async {
    final Directory temp = Directory.systemTemp;
    final File file = File(
      p.join(temp.path, 'taru_${report.id}_${report.fileName}'),
    );
    await _objects.writeToFile(report.storagePath, file.path);
    return file;
  }

  /// Patches editable metadata only — never rewrites immutable source fields.
  Future<void> updateMetadata(String uid, MedicalReport report) {
    return _collection(uid).doc(report.id).update(<String, dynamic>{
      'title': report.title,
      'category': report.category.name,
      'takenOn': report.takenOn?.toIso8601String(),
      'notes': report.notes?.trim().isEmpty ?? true
          ? null
          : report.notes?.trim(),
    });
  }

  Stream<ReportExtraction?> watchExtraction(String uid, String reportId) {
    return _extractionDoc(uid, reportId).snapshots().map((
      DocumentSnapshot<Map<String, dynamic>> snap,
    ) {
      if (!snap.exists) return null;
      return ReportExtraction.fromMap(snap.data());
    });
  }

  Future<ReportExtraction?> getExtraction(String uid, String reportId) async {
    final DocumentSnapshot<Map<String, dynamic>> snap = await _extractionDoc(
      uid,
      reportId,
    ).get();
    if (!snap.exists) return null;
    return ReportExtraction.fromMap(snap.data());
  }

  Future<String> loadReviewedText(String uid, String reportId) async {
    final Uint8List bytes = await _objects.readAll(
      reviewedExtractionStoragePath(uid, reportId),
    );
    return utf8.decode(bytes);
  }

  /// First save or replace of reviewed extracted text.
  ///
  /// Order: sidecar first, then metadata. On first-save metadata failure,
  /// best-effort deletes the new sidecar. On replace metadata failure,
  /// best-effort restores [previousReviewedText] when provided.
  Future<ReportExtraction> saveReviewedText({
    required String uid,
    required String reportId,
    required String reviewedText,
    String? previousReviewedText,
  }) async {
    final List<int> utf8Bytes = utf8.encode(reviewedText);
    if (utf8Bytes.length > kMaxReviewedTextUtf8Bytes) {
      throw StateError(
        'Reviewed text is too large to save in this release '
        '(max ${kMaxReviewedTextUtf8Bytes ~/ 1024} KiB).',
      );
    }

    final String path = reviewedExtractionStoragePath(uid, reportId);
    final bool isReplace = previousReviewedText != null;
    final Uint8List payload = Uint8List.fromList(utf8Bytes);

    await _objects.putData(
      path,
      payload,
      contentType: 'text/plain',
    );

    final ReportExtraction extraction = ReportExtraction(
      method: ReportExtraction.pdfTextMethod,
      reviewedAt: DateTime.now(),
    );

    try {
      await writeExtractionMetadata(uid, reportId, extraction);
    } catch (error) {
      if (isReplace) {
        try {
          await _objects.putData(
            path,
            Uint8List.fromList(utf8.encode(previousReviewedText)),
            contentType: 'text/plain',
          );
        } catch (_) {
          throw StateError(
            'Could not save reviewed text metadata, and restoring the '
            'previous reviewed text also failed. You can try Replace or '
            'Remove again.',
          );
        }
      } else {
        await _objects.deleteIfExists(path);
      }
      rethrow;
    }

    return extraction;
  }

  /// Visible for tests that simulate metadata write failures.
  Future<void> writeExtractionMetadata(
    String uid,
    String reportId,
    ReportExtraction extraction,
  ) {
    return _extractionDoc(uid, reportId).set(extraction.toMap());
  }

  Future<void> removeReviewedExtraction(String uid, String reportId) async {
    await _objects.deleteIfExists(
      reviewedExtractionStoragePath(uid, reportId),
    );

    try {
      await _extractionDoc(uid, reportId).delete();
    } on FirebaseException catch (error) {
      if (error.code != 'not-found') rethrow;
    }
  }

  /// Idempotent cascade: derived → source → extraction metadata → report doc.
  Future<void> delete(String uid, MedicalReport report) async {
    await _objects.deleteIfExists(
      reviewedExtractionStoragePath(uid, report.id),
    );
    await _objects.deleteIfExists(report.storagePath);

    try {
      await _extractionDoc(uid, report.id).delete();
    } on FirebaseException catch (error) {
      if (error.code != 'not-found') rethrow;
    }

    await _collection(uid).doc(report.id).delete();
  }

  /// Firestore may return Timestamp for fields written by other clients; turn
  /// them into ISO strings before the domain parser sees them.
  Map<String, dynamic> _normalise(Map<String, dynamic> data) {
    final Map<String, dynamic> copy = Map<String, dynamic>.from(data);

    for (final String key in <String>['uploadedAt', 'takenOn']) {
      final Object? value = copy[key];
      if (value is Timestamp) {
        copy[key] = value.toDate().toIso8601String();
      }
    }

    return copy;
  }

  static String _safeFileName(String fileName) {
    final String base = p.basename(fileName);
    final String cleaned = base.replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_');
    return cleaned.isEmpty ? 'report.bin' : cleaned;
  }

  static String _titleFromFileName(String fileName) {
    final String base = p.basenameWithoutExtension(fileName);
    final String spaced = base.replaceAll(RegExp(r'[_\-]+'), ' ').trim();
    return spaced.isEmpty ? 'Medical report' : spaced;
  }
}
