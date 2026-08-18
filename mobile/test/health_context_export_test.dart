import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/privacy/data/health_export_service.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempRoot;
  late FakeFirebaseFirestore firestore;
  const String uid = 'context-export-user';

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('taru_hc_export_');
    PathProviderPlatform.instance = _FakePathProvider(tempRoot.path);
    firestore = FakeFirebaseFirestore();
    await firestore.collection('users').doc(uid).set(<String, dynamic>{
      'name': 'Context Tester',
      'email': 'context.tester@example.com',
      'createdAt': Timestamp.fromDate(DateTime.utc(2026, 1, 1)),
    });
    await firestore
        .collection('users')
        .doc(uid)
        .collection('health')
        .doc('dietaryProfile')
        .set(<String, dynamic>{
          'pattern': 'vegetarian',
          'recordedAt': '2026-08-01T00:00:00.000Z',
          'updatedAt': '2026-08-02T00:00:00.000Z',
          'provenance': 'selfReported',
        });
    await firestore
        .collection('users')
        .doc(uid)
        .collection('health')
        .doc('lifestyle')
        .set(<String, dynamic>{'usualSleepHours': 7});
    await firestore
        .collection('users')
        .doc(uid)
        .collection('supplements')
        .doc('s1')
        .set(<String, dynamic>{
          'name': 'Vitamin D',
          'isCurrent': true,
          'recordedAt': '2026-08-01T00:00:00.000Z',
          'updatedAt': '2026-08-01T00:00:00.000Z',
          'provenance': 'selfReported',
        });
    await firestore
        .collection('users')
        .doc(uid)
        .collection('familyHistory')
        .doc('f1')
        .set(<String, dynamic>{
          'relationship': 'Mother',
          'condition': 'Asthma',
        });
    await firestore
        .collection('users')
        .doc(uid)
        .collection('procedures')
        .doc('p1')
        .set(<String, dynamic>{'name': 'Appendectomy'});
    await firestore
        .collection('users')
        .doc(uid)
        .collection('immunizations')
        .doc('i1')
        .set(<String, dynamic>{'vaccine': 'Tetanus'});
    await firestore
        .collection('users')
        .doc(uid)
        .collection('healthGoals')
        .doc('g1')
        .set(<String, dynamic>{
          'title': 'Walk comfortably',
          'area': 'movement',
          'createdAt': '2026-01-01T00:00:00.000Z',
          'desiredByMeaning': 'userGoalDate',
          'status': 'active',
        });
    await firestore
        .collection('users')
        .doc(uid)
        .collection('careTeam')
        .doc('c1')
        .set(<String, dynamic>{'name': 'Clinic example', 'role': 'GP'});
  });

  tearDown(() async {
    if (tempRoot.existsSync()) await tempRoot.delete(recursive: true);
  });

  test('export includes every Health Context domain', () async {
    final File zipFile = await HealthExportService(
      firestore: firestore,
      auth: _FakeAuth(uid),
      storage: _FakeStorage(),
    ).exportToZip();
    addTearDown(() async {
      if (zipFile.existsSync()) await zipFile.delete();
    });

    final Archive archive = ZipDecoder().decodeBytes(zipFile.readAsBytesSync());
    final List<String> names = archive.map((ArchiveFile f) => f.name).toList();

    const List<String> required = <String>[
      'health/dietary_profile.json',
      'health/lifestyle.json',
      'health_context/supplements.json',
      'health_context/family_history.json',
      'health_context/procedures.json',
      'health_context/immunizations.json',
      'health_context/health_goals.json',
      'health_context/care_team.json',
    ];
    for (final String path in required) {
      expect(names.any((String n) => n.endsWith(path)), isTrue, reason: path);
    }

    final List<dynamic> supplements = _jsonList(
      archive,
      'health_context/supplements.json',
    );
    expect(supplements, hasLength(1));
    expect((supplements.first as Map)['name'], 'Vitamin D');
    expect((supplements.first as Map)['recordedAt'], isNotNull);
    expect((supplements.first as Map)['updatedAt'], isNotNull);
    expect((supplements.first as Map)['provenance'], 'selfReported');
    expect(
      _jsonMap(archive, 'health/dietary_profile.json')['pattern'],
      'vegetarian',
    );
    expect(
      _jsonMap(archive, 'health/dietary_profile.json')['recordedAt'],
      isNotNull,
    );
    expect(
      _jsonMap(archive, 'health/dietary_profile.json')['updatedAt'],
      isNotNull,
    );
  });
}

List<dynamic> _jsonList(Archive archive, String suffix) {
  final ArchiveFile file = archive.firstWhere(
    (ArchiveFile f) => f.name.endsWith(suffix),
  );
  return jsonDecode(utf8.decode(file.content as List<int>)) as List<dynamic>;
}

Map<String, dynamic> _jsonMap(Archive archive, String suffix) {
  final ArchiveFile file = archive.firstWhere(
    (ArchiveFile f) => f.name.endsWith(suffix),
  );
  return Map<String, dynamic>.from(
    jsonDecode(utf8.decode(file.content as List<int>)) as Map,
  );
}

class _FakeAuth implements FirebaseAuth {
  _FakeAuth(this.uid);
  final String uid;
  @override
  User? get currentUser => _FakeUser(uid);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeUser implements User {
  _FakeUser(this.uid);
  @override
  final String uid;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeStorage implements FirebaseStorage {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakePathProvider extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  _FakePathProvider(this.path);
  final String path;
  @override
  Future<String?> getTemporaryPath() async => path;
}
