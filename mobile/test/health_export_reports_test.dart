import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/privacy/data/health_export_service.dart';
import 'package:mobile/features/reports/domain/report_extraction.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// Verifies reviewed OCR sidecars are included in health export archives.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempRoot;
  late FakeFirebaseFirestore firestore;
  late _MemoryStorage storage;
  const String uid = 'export-ocr-user';

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('taru_export_ocr_');
    PathProviderPlatform.instance = _FakePathProvider(tempRoot.path);
    firestore = FakeFirebaseFirestore();
    storage = _MemoryStorage();

    await firestore.collection('users').doc(uid).set(<String, dynamic>{
      'name': 'OCR Export Tester',
      'email': 'ocr.tester@example.com',
      'createdAt': Timestamp.fromDate(DateTime.utc(2026, 1, 1)),
    });

    await firestore
        .collection('users')
        .doc(uid)
        .collection('reports')
        .doc('scan1')
        .set(<String, dynamic>{
          'title': 'Lab scan',
          'category': 'lab',
          'fileName': 'scan.jpg',
          'mimeType': 'image/jpeg',
          'storagePath': 'users/$uid/reports/scan1/scan.jpg',
          'sizeBytes': 100,
          'uploadedAt': DateTime.utc(2026, 8, 1).toIso8601String(),
        });

    await firestore
        .collection('users')
        .doc(uid)
        .collection('reports')
        .doc('scan1')
        .collection('extraction')
        .doc('current')
        .set(<String, dynamic>{
          'method': 'ocr',
          'reviewedAt': Timestamp.fromDate(DateTime.utc(2026, 8, 2, 10)),
        });

    storage.objects['users/$uid/reports/scan1/scan.jpg'] =
        Uint8List.fromList(<int>[0xFF, 0xD8, 0xFF, 0xD9]);
    storage.objects[reviewedExtractionStoragePath(uid, 'scan1')] =
        Uint8List.fromList(utf8.encode('OCR reviewed text'));
  });

  tearDown(() async {
    if (tempRoot.existsSync()) {
      await tempRoot.delete(recursive: true);
    }
  });

  test('exportToZip includes OCR reviewed sidecar and method metadata', () async {
    final HealthExportService service = HealthExportService(
      firestore: firestore,
      auth: _FakeAuth(uid),
      storage: storage,
    );

    final File zipFile = await service.exportToZip();
    addTearDown(() async {
      if (zipFile.existsSync()) await zipFile.delete();
    });

    final Archive archive = ZipDecoder().decodeBytes(zipFile.readAsBytesSync());
    final List<String> names = archive.map((ArchiveFile f) => f.name).toList();

    expect(
      names.any((String n) => n.endsWith('reports/scan1/reviewed_extracted.txt')),
      isTrue,
    );

    final ArchiveFile reviewedFile = archive.files.firstWhere(
      (ArchiveFile f) => f.name.endsWith('reports/scan1/reviewed_extracted.txt'),
    );
    expect(
      utf8.decode(reviewedFile.content as List<int>),
      'OCR reviewed text',
    );

    final ArchiveFile indexFile = archive.files.firstWhere(
      (ArchiveFile f) => f.name.endsWith('reports/index.json'),
    );
    final Map<String, dynamic> indexRoot = Map<String, dynamic>.from(
      jsonDecode(utf8.decode(indexFile.content as List<int>)) as Map,
    );
    final List<dynamic> index = indexRoot['reports'] as List<dynamic>;
    final Map<String, dynamic> row =
        Map<String, dynamic>.from(index.first as Map);
    final Map<String, dynamic> derived = Map<String, dynamic>.from(
      row['derivedReviewedText'] as Map,
    );

    expect(derived['method'], 'ocr');
    expect(derived['role'], 'DERIVED');
    expect(
      derived['archivePath'],
      'reports/scan1/reviewed_extracted.txt',
    );
    expect(DateTime.tryParse(derived['reviewedAt'] as String), isNotNull);
  });
}

class _FakePathProvider extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  _FakePathProvider(this.temporaryPath);

  final String temporaryPath;

  @override
  Future<String?> getTemporaryPath() async => temporaryPath;
}

class _FakeAuth extends Fake implements FirebaseAuth {
  _FakeAuth(this.uid);

  final String uid;

  @override
  User? get currentUser => _FakeUser(uid);
}

class _FakeUser extends Fake implements User {
  _FakeUser(this._uid);

  final String _uid;

  @override
  String get uid => _uid;
}

class _MemoryStorage extends Fake implements FirebaseStorage {
  final Map<String, Uint8List> objects = <String, Uint8List>{};

  @override
  Reference ref([String? path]) => _MemoryReference(path ?? '', objects);
}

class _MemoryReference extends Fake implements Reference {
  _MemoryReference(this.fullPath, this.objects);

  final String fullPath;
  final Map<String, Uint8List> objects;

  @override
  Reference child(String path) {
    final String joined = fullPath.isEmpty ? path : '$fullPath/$path';
    return _MemoryReference(joined, objects);
  }

  @override
  DownloadTask writeToFile(File file) {
    return _ImmediateDownloadTask(() async {
      final Uint8List? bytes = objects[fullPath];
      if (bytes == null) {
        throw FirebaseException(
          plugin: 'storage',
          code: 'object-not-found',
          message: fullPath,
        );
      }
      await file.writeAsBytes(bytes, flush: true);
    });
  }
}

class _ImmediateDownloadTask extends Fake implements DownloadTask {
  _ImmediateDownloadTask(this._action);

  final Future<void> Function() _action;

  @override
  Future<S> then<S>(
    FutureOr<S> Function(TaskSnapshot value) onValue, {
    Function? onError,
  }) {
    return _action().then((_) => onValue(_FakeTaskSnapshot()));
  }
}

class _FakeTaskSnapshot extends Fake implements TaskSnapshot {}
