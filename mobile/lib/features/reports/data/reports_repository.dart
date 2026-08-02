import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as p;

import '../domain/medical_report.dart';

/// Owns both the Storage object and the Firestore metadata for a report.
///
/// The two are written together so a listing never points at a missing file,
/// and a delete removes both so nothing is left orphaned.
class ReportsRepository {
  ReportsRepository(this._firestore, this._storage);

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  CollectionReference<Map<String, dynamic>> _collection(String uid) =>
      _firestore.collection('users').doc(uid).collection('reports');

  Reference _object(String uid, String reportId, String fileName) => _storage
      .ref()
      .child('users')
      .child(uid)
      .child('reports')
      .child(reportId)
      .child(fileName);

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
    final Reference ref = _object(uid, reportId, safeName);

    final UploadTask task = ref.putData(
      bytes,
      SettableMetadata(
        contentType: mimeType,
        customMetadata: <String, String>{'originalFileName': fileName},
      ),
    );

    if (onProgress != null) {
      task.snapshotEvents.listen((TaskSnapshot snapshot) {
        final int total = snapshot.totalBytes;
        if (total <= 0) return;
        onProgress(snapshot.bytesTransferred / total);
      });
    }

    await task;

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
    return _storage.ref(report.storagePath).getDownloadURL();
  }

  Future<File> downloadToTemp(MedicalReport report) async {
    final Directory temp = Directory.systemTemp;
    final File file = File(
      p.join(temp.path, 'taru_${report.id}_${report.fileName}'),
    );
    await _storage.ref(report.storagePath).writeToFile(file);
    return file;
  }

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

  Future<void> delete(String uid, MedicalReport report) async {
    try {
      await _storage.ref(report.storagePath).delete();
    } on FirebaseException catch (error) {
      // Object already gone is fine — still clear the metadata.
      if (error.code != 'object-not-found') rethrow;
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
