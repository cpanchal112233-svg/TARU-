import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/privacy/data/health_export_service.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// Archive-assembly test for the real [HealthExportService.exportToZip] path.
///
/// Auth/Storage/path_provider are test doubles only so the production service
/// can run offline. Measurement collection/serialization/ZIP assembly uses the
/// real Phase 10/11 export code.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempRoot;
  late FakeFirebaseFirestore firestore;
  const String uid = 'export-archive-user';

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('taru_export_archive_');
    PathProviderPlatform.instance = _FakePathProvider(tempRoot.path);
    firestore = FakeFirebaseFirestore();

    await firestore.collection('users').doc(uid).set(<String, dynamic>{
      'name': 'Export Tester',
      'email': 'export.tester@example.com',
      'createdAt': Timestamp.fromDate(DateTime.utc(2026, 1, 1)),
    });
    await firestore
        .collection('users')
        .doc(uid)
        .collection('health')
        .doc('profile')
        .set(<String, dynamic>{'weightKg': 70.0, 'heightCm': 170.0});

    final DateTime base = DateTime.utc(2026, 1, 1, 8);
    for (int i = 0; i < 55; i++) {
      await firestore
          .collection('users')
          .doc(uid)
          .collection('measurements')
          .doc('w_$i')
          .set(<String, dynamic>{
            'type': 'weight',
            'valueKg': 60.0 + i * 0.1,
            'source': 'manual',
            'recordedAt': Timestamp.fromDate(base.add(Duration(hours: i))),
          });
      await firestore
          .collection('users')
          .doc(uid)
          .collection('measurements')
          .doc('bp_$i')
          .set(<String, dynamic>{
            'type': 'blood_pressure',
            'systolicMmHg': 110 + (i % 20),
            'diastolicMmHg': 70 + (i % 10),
            'source': 'manual',
            'recordedAt': Timestamp.fromDate(
              base.add(Duration(hours: i, minutes: 30)),
            ),
          });
    }
  });

  tearDown(() async {
    if (tempRoot.existsSync()) {
      await tempRoot.delete(recursive: true);
    }
  });

  test(
    'exportToZip includes all weight and BP measurements without UI 50-cap',
    () async {
      final HealthExportService service = HealthExportService(
        firestore: firestore,
        auth: _FakeAuth(uid),
        storage: _FakeStorage(),
      );

      final File zipFile = await service.exportToZip();
      addTearDown(() async {
        if (zipFile.existsSync()) {
          await zipFile.delete();
        }
      });

      expect(zipFile.existsSync(), isTrue);

      final Archive archive = ZipDecoder().decodeBytes(zipFile.readAsBytesSync());
      final List<String> names = archive.map((ArchiveFile f) => f.name).toList();

      expect(
        names.any((String n) => n.endsWith('measurements/weight.json')),
        isTrue,
      );
      expect(
        names.any((String n) => n.endsWith('measurements/blood_pressure.json')),
        isTrue,
      );
      expect(names.any((String n) => n.endsWith('manifest.json')), isTrue);
      expect(names.any((String n) => n.endsWith('account.json')), isTrue);
      expect(
        names.any((String n) => n.endsWith('health/profile.json')),
        isTrue,
      );
      expect(names.any((String n) => n.endsWith('reports/index.json')), isTrue);

      final List<dynamic> weights = _jsonList(
        archive,
        'measurements/weight.json',
      );
      final List<dynamic> bps = _jsonList(
        archive,
        'measurements/blood_pressure.json',
      );

      expect(weights, hasLength(55));
      expect(bps, hasLength(55));

      final Map<String, dynamic> weightRow = Map<String, dynamic>.from(
        weights.first as Map,
      );
      expect(weightRow.keys.toSet(), <String>{
        'id',
        'type',
        'valueKg',
        'source',
        'recordedAt',
      });
      expect(weightRow['type'], 'weight');
      expect(weightRow['valueKg'], isA<num>());
      expect(weightRow['source'], 'manual');
      expect(
        DateTime.tryParse(weightRow['recordedAt'] as String),
        isNotNull,
      );
      expect(weightRow.containsKey('category'), isFalse);

      final Map<String, dynamic> bpRow = Map<String, dynamic>.from(
        bps.first as Map,
      );
      expect(bpRow.keys.toSet(), <String>{
        'id',
        'type',
        'systolicMmHg',
        'diastolicMmHg',
        'source',
        'recordedAt',
      });
      expect(bpRow['type'], 'blood_pressure');
      expect(bpRow['systolicMmHg'], isA<num>());
      expect(bpRow['diastolicMmHg'], isA<num>());
      expect(bpRow['source'], 'manual');
      expect(DateTime.tryParse(bpRow['recordedAt'] as String), isNotNull);
      expect(bpRow.containsKey('pulseBpm'), isFalse);
      expect(bpRow.containsKey('category'), isFalse);
      expect(bpRow.containsKey('status'), isFalse);
      expect(bpRow.containsKey('interpretation'), isFalse);
    },
  );

  test('empty BP history exports valid empty blood_pressure.json', () async {
    final FakeFirebaseFirestore emptyBp = FakeFirebaseFirestore();
    await emptyBp.collection('users').doc(uid).set(<String, dynamic>{
      'name': 'Export Tester',
      'email': 'export.tester@example.com',
      'createdAt': Timestamp.fromDate(DateTime.utc(2026, 1, 1)),
    });
    await emptyBp
        .collection('users')
        .doc(uid)
        .collection('measurements')
        .doc('w_only')
        .set(<String, dynamic>{
          'type': 'weight',
          'valueKg': 70.0,
          'source': 'manual',
          'recordedAt': Timestamp.fromDate(DateTime.utc(2026, 2, 1)),
        });

    final File zipFile = await HealthExportService(
      firestore: emptyBp,
      auth: _FakeAuth(uid),
      storage: _FakeStorage(),
    ).exportToZip();
    addTearDown(() async {
      if (zipFile.existsSync()) await zipFile.delete();
    });

    final Archive archive = ZipDecoder().decodeBytes(zipFile.readAsBytesSync());
    final List<dynamic> bps = _jsonList(
      archive,
      'measurements/blood_pressure.json',
    );
    expect(bps, isEmpty);
    expect(_jsonList(archive, 'measurements/weight.json'), hasLength(1));
  });

  test(
    'BP query failure fails the whole export (complete-or-fail)',
    () async {
      final HealthExportService service = HealthExportService(
        firestore: _BpQueryFailingFirestore(firestore),
        auth: _FakeAuth(uid),
        storage: _FakeStorage(),
      );

      await expectLater(
        service.exportToZip(),
        throwsA(
          isA<StateError>().having(
            (StateError e) => e.message,
            'message',
            contains('blood_pressure query failure'),
          ),
        ),
      );

      final List<FileSystemEntity> leftoverZips = tempRoot
          .listSync()
          .whereType<File>()
          .where((File f) => f.path.endsWith('.zip'))
          .toList();
      expect(
        leftoverZips,
        isEmpty,
        reason: 'Failed export must not leave a partial ZIP success artifact',
      );
    },
  );
}

List<dynamic> _jsonList(Archive archive, String suffix) {
  final ArchiveFile file = archive.files.firstWhere(
    (ArchiveFile f) => f.name.endsWith(suffix),
  );
  return jsonDecode(utf8.decode(file.content as List<int>)) as List<dynamic>;
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

class _FakeStorage extends Fake implements FirebaseStorage {}

/// Delegates to [inner] except blood-pressure measurement queries, which fail.
///
/// Proves Phase 11 BP collection participates in complete-or-fail — there is
/// no soft-skip path when the required BP read throws.
class _BpQueryFailingFirestore extends Fake implements FirebaseFirestore {
  _BpQueryFailingFirestore(this.inner);

  final FakeFirebaseFirestore inner;

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) {
    return _BpAwareCollection(inner.collection(path), path);
  }
}

class _BpAwareCollection extends Fake
    implements CollectionReference<Map<String, dynamic>> {
  _BpAwareCollection(this.inner, this.fullPath);

  final CollectionReference<Map<String, dynamic>> inner;
  final String fullPath;

  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) {
    final DocumentReference<Map<String, dynamic>> doc = inner.doc(path);
    if (fullPath == 'users') {
      return _BpAwareUserDoc(doc);
    }
    return doc;
  }
}

class _BpAwareUserDoc extends Fake
    implements DocumentReference<Map<String, dynamic>> {
  _BpAwareUserDoc(this.inner);

  final DocumentReference<Map<String, dynamic>> inner;

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) {
    final CollectionReference<Map<String, dynamic>> col = inner.collection(
      path,
    );
    if (path == 'measurements') {
      return _FailingBpMeasurements(col);
    }
    return col;
  }

  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get([GetOptions? options]) {
    return inner.get(options);
  }
}

class _FailingBpMeasurements extends Fake
    implements CollectionReference<Map<String, dynamic>> {
  _FailingBpMeasurements(this.inner);

  final CollectionReference<Map<String, dynamic>> inner;

  @override
  Query<Map<String, dynamic>> where(
    Object field, {
    Object? isEqualTo,
    Object? isNotEqualTo,
    Object? isLessThan,
    Object? isLessThanOrEqualTo,
    Object? isGreaterThan,
    Object? isGreaterThanOrEqualTo,
    Object? arrayContains,
    Iterable<Object?>? arrayContainsAny,
    Iterable<Object?>? whereIn,
    Iterable<Object?>? whereNotIn,
    bool? isNull,
  }) {
    if (field == 'type' && isEqualTo == 'blood_pressure') {
      return _ThrowingQuery();
    }
    return inner.where(
      field,
      isEqualTo: isEqualTo,
      isNotEqualTo: isNotEqualTo,
      isLessThan: isLessThan,
      isLessThanOrEqualTo: isLessThanOrEqualTo,
      isGreaterThan: isGreaterThan,
      isGreaterThanOrEqualTo: isGreaterThanOrEqualTo,
      arrayContains: arrayContains,
      arrayContainsAny: arrayContainsAny,
      whereIn: whereIn,
      whereNotIn: whereNotIn,
      isNull: isNull,
    );
  }
}

class _ThrowingQuery extends Fake implements Query<Map<String, dynamic>> {
  @override
  Future<QuerySnapshot<Map<String, dynamic>>> get([GetOptions? options]) {
    return Future<QuerySnapshot<Map<String, dynamic>>>.error(
      StateError('Simulated blood_pressure query failure'),
    );
  }
}
