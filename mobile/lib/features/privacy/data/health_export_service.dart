import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../reports/domain/report_extraction.dart';

/// Builds a complete local ZIP of the signed-in user's TARU health data.
///
/// Complete-or-fail: any required read/download/ZIP failure aborts without
/// presenting a partial archive as success.
class HealthExportService {
  HealthExportService({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    FirebaseAuth? auth,
    this._weightLoader,
    this._bloodPressureLoader,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance,
       _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final FirebaseAuth _auth;
  final Future<List<Map<String, dynamic>>> Function(String uid)? _weightLoader;
  final Future<List<Map<String, dynamic>>> Function(String uid)?
  _bloodPressureLoader;

  /// Returns the generated ZIP file. Caller shares then cleans up.
  Future<File> exportToZip({void Function(String step)? onProgress}) async {
    final User? user = _auth.currentUser;
    if (user == null) {
      throw StateError('Not signed in.');
    }
    final String uid = user.uid;

    final Directory tempRoot = await getTemporaryDirectory();
    final String stamp = _timestampStamp(DateTime.now());
    final Directory staging = Directory(
      p.join(tempRoot.path, 'taru_export_${uid}_$stamp'),
    );
    if (staging.existsSync()) {
      await staging.delete(recursive: true);
    }
    await staging.create(recursive: true);

    final File zipFile = File(p.join(tempRoot.path, 'taru-export-$stamp.zip'));
    if (zipFile.existsSync()) {
      await zipFile.delete();
    }

    try {
      onProgress?.call('Collecting account…');
      await _writeJson(staging, 'manifest.json', _manifest());
      await _writeJson(staging, 'account.json', await _account(uid));

      onProgress?.call('Collecting health profile…');
      await _writeJson(
        staging,
        'health/profile.json',
        await _docMap(uid, 'health', 'profile'),
      );
      await _writeJson(
        staging,
        'health/conditions.json',
        await _docMap(uid, 'health', 'conditions'),
      );
      await _writeJson(
        staging,
        'health/allergies.json',
        await _docMap(uid, 'health', 'allergies'),
      );
      await _writeJson(
        staging,
        'health/medications.json',
        await _docMap(uid, 'health', 'medications'),
      );

      onProgress?.call('Collecting routine…');
      await _writeJson(
        staging,
        'routine/habit_preferences.json',
        await _docMap(uid, 'routine', 'habitPreferences'),
      );
      await _writeJson(
        staging,
        'routine/dose_logs.json',
        await _collectionArray(uid, 'doseLogs'),
      );
      await _writeJson(
        staging,
        'routine/habit_logs.json',
        await _collectionArray(uid, 'habitLogs'),
      );

      onProgress?.call('Collecting measurements…');
      await _writeJson(
        staging,
        'measurements/weight.json',
        await _allWeightMeasurements(uid),
      );
      await _writeJson(
        staging,
        'measurements/blood_pressure.json',
        await _allBloodPressureMeasurements(uid),
      );

      onProgress?.call('Collecting reports…');
      final List<Map<String, dynamic>> reportIndex = await _exportReports(
        uid,
        staging,
        onProgress,
      );
      await _writeJson(staging, 'reports/index.json', <String, dynamic>{
        'reports': reportIndex,
      });

      onProgress?.call('Building archive…');
      final ZipFileEncoder encoder = ZipFileEncoder();
      encoder.create(zipFile.path);
      await _addDirectorySequentially(encoder, staging, 'taru-export-$stamp');
      await encoder.close();

      return zipFile;
    } catch (_) {
      await _bestEffortDelete(zipFile);
      rethrow;
    } finally {
      await _bestEffortDelete(staging);
    }
  }

  Map<String, dynamic> _manifest() => <String, dynamic>{
    'exportVersion': 1,
    'product': 'TARU',
    'assembledAt': DateTime.now().toUtc().toIso8601String(),
    'snapshotNote':
        'This archive was assembled during the export operation. '
        'It is not a single database transaction.',
    'reportProvenanceNote':
        'Original report files are SOURCE artifacts. Reviewed extracted text, '
        'when present, is DERIVED user-reviewed content and is not guaranteed '
        'to be clinically exact.',
  };

  Future<Map<String, dynamic>> _account(String uid) async {
    final DocumentSnapshot<Map<String, dynamic>> snap = await _firestore
        .collection('users')
        .doc(uid)
        .get();
    if (!snap.exists || snap.data() == null) {
      throw StateError('Account document missing.');
    }
    final Map<String, dynamic> data = snap.data()!;
    return <String, dynamic>{
      'name': data['name'],
      'email': data['email'],
      'createdAt': _iso(data['createdAt']),
    };
  }

  Future<Map<String, dynamic>> _docMap(
    String uid,
    String collection,
    String docId,
  ) async {
    final DocumentSnapshot<Map<String, dynamic>> snap = await _firestore
        .collection('users')
        .doc(uid)
        .collection(collection)
        .doc(docId)
        .get();
    if (!snap.exists || snap.data() == null) {
      return <String, dynamic>{};
    }
    return _sanitize(_normalizeTimestamps(snap.data()!));
  }

  Future<List<Map<String, dynamic>>> _collectionArray(
    String uid,
    String collection,
  ) async {
    final QuerySnapshot<Map<String, dynamic>> snap = await _firestore
        .collection('users')
        .doc(uid)
        .collection(collection)
        .get();
    return snap.docs
        .map(
          (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
              <String, dynamic>{
                'id': doc.id,
                ..._sanitize(_normalizeTimestamps(doc.data())),
              },
        )
        .toList();
  }

  Future<List<Map<String, dynamic>>> _allWeightMeasurements(String uid) async {
    if (_weightLoader != null) {
      return _weightLoader(uid);
    }
    final QuerySnapshot<Map<String, dynamic>> snap = await _firestore
        .collection('users')
        .doc(uid)
        .collection('measurements')
        .where('type', isEqualTo: 'weight')
        .get();
    return snap.docs.map((QueryDocumentSnapshot<Map<String, dynamic>> doc) {
      return serializeWeightExportRow(doc.id, doc.data());
    }).toList();
  }

  Future<List<Map<String, dynamic>>> _allBloodPressureMeasurements(
    String uid,
  ) async {
    if (_bloodPressureLoader != null) {
      return _bloodPressureLoader(uid);
    }
    final QuerySnapshot<Map<String, dynamic>> snap = await _firestore
        .collection('users')
        .doc(uid)
        .collection('measurements')
        .where('type', isEqualTo: 'blood_pressure')
        .get();
    return snap.docs.map((QueryDocumentSnapshot<Map<String, dynamic>> doc) {
      return serializeBloodPressureExportRow(doc.id, doc.data());
    }).toList();
  }

  /// Phase 10 weight export row shape (preserved in Phase 11).
  @visibleForTesting
  static Map<String, dynamic> serializeWeightExportRow(
    String id,
    Map<String, dynamic> raw,
  ) {
    return <String, dynamic>{
      'id': id,
      'type': raw['type'],
      'valueKg': raw['valueKg'],
      'source': raw['source'],
      'recordedAt': exportIsoTimestamp(raw['recordedAt']),
    };
  }

  /// Blood-pressure export row — canonical mmHg, no clinical fields.
  @visibleForTesting
  static Map<String, dynamic> serializeBloodPressureExportRow(
    String id,
    Map<String, dynamic> raw,
  ) {
    return <String, dynamic>{
      'id': id,
      'type': raw['type'],
      'systolicMmHg': raw['systolicMmHg'],
      'diastolicMmHg': raw['diastolicMmHg'],
      'source': raw['source'],
      'recordedAt': exportIsoTimestamp(raw['recordedAt']),
    };
  }

  /// ISO-8601 UTC timestamp helper for export rows (testable without Firebase).
  @visibleForTesting
  static String? exportIsoTimestamp(Object? value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate().toUtc().toIso8601String();
    if (value is DateTime) return value.toUtc().toIso8601String();
    if (value is String) {
      final DateTime? parsed = DateTime.tryParse(value);
      return parsed?.toUtc().toIso8601String() ?? value;
    }
    return value.toString();
  }

  Future<List<Map<String, dynamic>>> _exportReports(
    String uid,
    Directory staging,
    void Function(String step)? onProgress,
  ) async {
    final QuerySnapshot<Map<String, dynamic>> snap = await _firestore
        .collection('users')
        .doc(uid)
        .collection('reports')
        .orderBy('uploadedAt', descending: true)
        .get();

    final List<Map<String, dynamic>> index = <Map<String, dynamic>>[];

    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in snap.docs) {
      final Map<String, dynamic> data = doc.data();
      final String reportId = doc.id;
      final String? storagePath = data['storagePath'] as String?;
      final String fileName = (data['fileName'] as String?) ?? 'report.bin';
      if (storagePath == null || storagePath.isEmpty) {
        throw StateError('Report $reportId missing source path.');
      }

      onProgress?.call('Downloading report…');
      final Directory reportDir = Directory(
        p.join(staging.path, 'reports', reportId),
      );
      await reportDir.create(recursive: true);

      final String ext = p.extension(fileName).isEmpty
          ? '.bin'
          : p.extension(fileName);
      final File original = File(p.join(reportDir.path, 'original$ext'));
      try {
        await _storage.ref(storagePath).writeToFile(original);
      } catch (error) {
        throw StateError('Failed to download report source: $reportId');
      }

      final DocumentSnapshot<Map<String, dynamic>> extractionSnap =
          await _firestore
              .collection('users')
              .doc(uid)
              .collection('reports')
              .doc(reportId)
              .collection('extraction')
              .doc('current')
              .get();

      bool hasReviewed = false;
      Map<String, dynamic>? extractionMeta;
      if (extractionSnap.exists && extractionSnap.data() != null) {
        final ReportExtraction? parsed = ReportExtraction.fromMap(
          extractionSnap.data(),
        );
        if (parsed == null) {
          throw StateError('Invalid extraction metadata for $reportId');
        }
        extractionMeta = <String, dynamic>{
          'method': parsed.method,
          'reviewedAt': parsed.reviewedAt.toUtc().toIso8601String(),
          'role': 'DERIVED',
        };
        final File reviewed = File(
          p.join(reportDir.path, 'reviewed_extracted.txt'),
        );
        try {
          await _storage
              .ref(reviewedExtractionStoragePath(uid, reportId))
              .writeToFile(reviewed);
        } catch (_) {
          throw StateError(
            'Reviewed extraction exists but bytes could not be fetched '
            'for $reportId',
          );
        }
        hasReviewed = true;
      }

      index.add(<String, dynamic>{
        'id': reportId,
        'title': data['title'],
        'category': data['category'],
        'fileName': fileName,
        'mimeType': data['mimeType'],
        'sizeBytes': data['sizeBytes'],
        'uploadedAt': _iso(data['uploadedAt']),
        'takenOn': _iso(data['takenOn']),
        'notes': data['notes'],
        'source': <String, dynamic>{
          'role': 'SOURCE',
          'archivePath': 'reports/$reportId/original$ext',
        },
        if (hasReviewed)
          'derivedReviewedText': <String, dynamic>{
            ...?extractionMeta,
            'archivePath': 'reports/$reportId/reviewed_extracted.txt',
          },
      });
    }

    return index;
  }

  Future<void> _addDirectorySequentially(
    ZipFileEncoder encoder,
    Directory dir,
    String zipRoot,
  ) async {
    final List<File> files =
        dir.listSync(recursive: true).whereType<File>().toList()
          ..sort((File a, File b) => a.path.compareTo(b.path));

    for (final File file in files) {
      final String relative = p.join(
        zipRoot,
        p.relative(file.path, from: dir.path),
      );
      await encoder.addFile(file, relative.replaceAll('\\', '/'));
    }
  }

  Future<void> _writeJson(
    Directory staging,
    String relative,
    Object data,
  ) async {
    final File file = File(p.join(staging.path, relative));
    await file.parent.create(recursive: true);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(data),
      encoding: utf8,
    );
  }

  Map<String, dynamic> _normalizeTimestamps(Map<String, dynamic> input) {
    final Map<String, dynamic> out = <String, dynamic>{};
    input.forEach((String key, Object? value) {
      out[key] = _iso(value) ?? value;
    });
    return out;
  }

  /// Strip operational / backend-internal fields from export payloads.
  Map<String, dynamic> _sanitize(Map<String, dynamic> input) {
    final Map<String, dynamic> out = Map<String, dynamic>.from(input);
    out.remove('storagePath');
    out.remove('deletionInProgress');
    out.remove('deletionStartedAt');
    return out;
  }

  Object? _iso(Object? value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate().toUtc().toIso8601String();
    if (value is DateTime) return value.toUtc().toIso8601String();
    if (value is String) {
      final DateTime? parsed = DateTime.tryParse(value);
      return parsed?.toUtc().toIso8601String() ?? value;
    }
    return value;
  }

  Future<void> _bestEffortDelete(FileSystemEntity entity) async {
    try {
      if (entity.existsSync()) {
        if (entity is Directory) {
          await entity.delete(recursive: true);
        } else {
          await entity.delete();
        }
      }
    } catch (_) {}
  }

  static String _timestampStamp(DateTime value) {
    final DateTime local = value.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${local.year}'
        '${two(local.month)}'
        '${two(local.day)}-'
        '${two(local.hour)}'
        '${two(local.minute)}'
        '${two(local.second)}';
  }

  /// Visible for tests.
  static String debugTimestampStamp(DateTime value) => _timestampStamp(value);
}
