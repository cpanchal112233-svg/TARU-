import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/measurements/data/measurements_repository.dart';
import 'package:mobile/features/measurements/domain/blood_pressure_measurement.dart';
import 'package:mobile/features/measurements/domain/weight_measurement.dart';

void main() {
  group('BloodPressureMeasurement model', () {
    test('valid paired model round-trip', () {
      final DateTime at = DateTime.utc(2026, 8, 9, 8, 15);
      final BloodPressureMeasurement reading = BloodPressureMeasurement(
        id: 'bp1',
        systolicMmHg: 120,
        diastolicMmHg: 80,
        recordedAt: at,
      );

      final Map<String, dynamic> map = reading.toMap(
        recordedAtTimestamp: Timestamp.fromDate(at),
      );
      expect(map['type'], measurementTypeBloodPressure);
      expect(map['systolicMmHg'], 120);
      expect(map['diastolicMmHg'], 80);
      expect(map['source'], bloodPressureSourceManual);
      expect(map.containsKey('pulseBpm'), isFalse);
      expect(map.containsKey('pulse'), isFalse);
      expect(map.containsKey('category'), isFalse);
      expect(map.containsKey('value'), isFalse);
      expect(map.containsKey('createdAt'), isFalse);

      final BloodPressureMeasurement? restored =
          BloodPressureMeasurement.fromMap('bp1', map);
      expect(restored, isNotNull);
      expect(restored!.systolicMmHg, 120);
      expect(restored.diastolicMmHg, 80);
      expect(restored.recordedAt.toUtc(), at);
      expect(restored.source, 'manual');
    });

    test('rejects malformed / wrong-type maps', () {
      expect(BloodPressureMeasurement.fromMap('x', null), isNull);
      expect(
        BloodPressureMeasurement.fromMap('x', <String, dynamic>{
          'type': 'weight',
          'systolicMmHg': 120,
          'diastolicMmHg': 80,
          'recordedAt': Timestamp.now(),
        }),
        isNull,
      );
      expect(
        BloodPressureMeasurement.fromMap('x', <String, dynamic>{
          'type': 'blood_pressure',
          'systolicMmHg': 'high',
          'diastolicMmHg': 80,
          'recordedAt': Timestamp.now(),
        }),
        isNull,
      );
    });

    test('technical mmHg shape 1–999', () {
      expect(isTechnicallyValidBpMmHg(1), isTrue);
      expect(isTechnicallyValidBpMmHg(999), isTrue);
      expect(isTechnicallyValidBpMmHg(0), isFalse);
      expect(isTechnicallyValidBpMmHg(-1), isFalse);
      expect(isTechnicallyValidBpMmHg(1000), isFalse);
    });

    test('string input shape rejects >3 digits without truncating meaning', () {
      expect(isTechnicallyValidBpMmHgInput('1'), isTrue);
      expect(isTechnicallyValidBpMmHgInput('999'), isTrue);
      expect(isTechnicallyValidBpMmHgInput('1000'), isFalse);
      expect(isTechnicallyValidBpMmHgInput('1234'), isFalse);
      expect(isTechnicallyValidBpMmHgInput('0'), isFalse);
      expect(isTechnicallyValidBpMmHgInput(''), isFalse);
      expect(isTechnicallyValidBpMmHgInput(null), isFalse);
      expect(isTechnicallyValidBpMmHgInput('80'), isTrue);
      expect(isTechnicallyValidBpMmHgInput('120'), isTrue);
    });
  });

  group('BloodPressure repository', () {
    late FakeFirebaseFirestore firestore;
    late MeasurementsRepository repository;
    const String uid = 'bp-user';

    setUp(() {
      firestore = FakeFirebaseFirestore();
      repository = MeasurementsRepository(firestore);
    });

    Future<Map<String, dynamic>?> profileMap() async {
      final DocumentSnapshot<Map<String, dynamic>> snap = await firestore
          .collection('users')
          .doc(uid)
          .collection('health')
          .doc('profile')
          .get();
      return snap.data();
    }

    test('records valid BP with preserved recordedAt and no pulse', () async {
      final DateTime at = DateTime.utc(2026, 7, 1, 9, 30);
      await repository.recordBloodPressure(
        uid,
        systolicMmHg: 118,
        diastolicMmHg: 76,
        recordedAt: at,
        now: DateTime.utc(2026, 8, 9),
      );

      final List<BloodPressureMeasurement> history = await repository
          .fetchLatestBloodPressures(uid, limit: 10);
      expect(history, hasLength(1));
      expect(history.first.systolicMmHg, 118);
      expect(history.first.diastolicMmHg, 76);
      expect(history.first.source, 'manual');
      expect(history.first.recordedAt.toUtc(), at);

      final DocumentSnapshot<Map<String, dynamic>> doc = await firestore
          .collection('users')
          .doc(uid)
          .collection('measurements')
          .doc(history.first.id)
          .get();
      expect(doc.data()!.containsKey('pulseBpm'), isFalse);
      expect(await profileMap(), isNull);
    });

    test('rejects missing/invalid systolic and diastolic', () async {
      expect(
        () => repository.recordBloodPressure(
          uid,
          systolicMmHg: 0,
          diastolicMmHg: 80,
        ),
        throwsA(
          isA<ArgumentError>().having(
            (ArgumentError e) => e.message,
            'message',
            'Enter a valid systolic value.',
          ),
        ),
      );
      expect(
        () => repository.recordBloodPressure(
          uid,
          systolicMmHg: 120,
          diastolicMmHg: -3,
        ),
        throwsA(
          isA<ArgumentError>().having(
            (ArgumentError e) => e.message,
            'message',
            'Enter a valid diastolic value.',
          ),
        ),
      );
      expect(
        () => repository.recordBloodPressure(
          uid,
          systolicMmHg: 1000,
          diastolicMmHg: 80,
        ),
        throwsArgumentError,
      );
    });

    test('does not medically reject systolic <= diastolic', () async {
      await repository.recordBloodPressure(
        uid,
        systolicMmHg: 80,
        diastolicMmHg: 120,
        recordedAt: DateTime.utc(2026, 8, 1),
        now: DateTime.utc(2026, 8, 9),
      );
      final List<BloodPressureMeasurement> history = await repository
          .fetchLatestBloodPressures(uid, limit: 1);
      expect(history.first.systolicMmHg, 80);
      expect(history.first.diastolicMmHg, 120);
    });

    test('future timestamp rejected; historical accepted', () async {
      final DateTime now = DateTime.utc(2026, 8, 9, 12);
      expect(
        () => repository.recordBloodPressure(
          uid,
          systolicMmHg: 120,
          diastolicMmHg: 80,
          recordedAt: now.add(const Duration(minutes: 5)),
          now: now,
        ),
        throwsArgumentError,
      );

      await repository.recordBloodPressure(
        uid,
        systolicMmHg: 121,
        diastolicMmHg: 81,
        recordedAt: now.subtract(const Duration(days: 10)),
        now: now,
      );
      expect(
        (await repository.fetchLatestBloodPressures(uid, limit: 1)).first
            .systolicMmHg,
        121,
      );
    });

    test('ordering recordedAt DESC then documentId DESC', () async {
      final DateTime day = DateTime.utc(2026, 8, 1, 10);
      await firestore
          .collection('users')
          .doc(uid)
          .collection('measurements')
          .doc('aaa')
          .set(<String, dynamic>{
            'type': measurementTypeBloodPressure,
            'systolicMmHg': 110,
            'diastolicMmHg': 70,
            'source': bloodPressureSourceManual,
            'recordedAt': Timestamp.fromDate(day),
          });
      await firestore
          .collection('users')
          .doc(uid)
          .collection('measurements')
          .doc('zzz')
          .set(<String, dynamic>{
            'type': measurementTypeBloodPressure,
            'systolicMmHg': 130,
            'diastolicMmHg': 85,
            'source': bloodPressureSourceManual,
            'recordedAt': Timestamp.fromDate(day),
          });
      await firestore
          .collection('users')
          .doc(uid)
          .collection('measurements')
          .doc('mid')
          .set(<String, dynamic>{
            'type': measurementTypeBloodPressure,
            'systolicMmHg': 125,
            'diastolicMmHg': 82,
            'source': bloodPressureSourceManual,
            'recordedAt': Timestamp.fromDate(
              day.add(const Duration(hours: 1)),
            ),
          });

      final List<BloodPressureMeasurement> history = await repository
          .fetchLatestBloodPressures(uid, limit: 10);
      expect(
        history.map((BloodPressureMeasurement m) => m.systolicMmHg).toList(),
        <int>[125, 130, 110],
      );
      expect(history.map((BloodPressureMeasurement m) => m.id).toList(), <String>[
        'mid',
        'zzz',
        'aaa',
      ]);
    });

    test('recent history limit is 50', () async {
      expect(MeasurementsRepository.historyLimit, 50);
    });

    test('delete BP does not affect weight or profile mirror', () async {
      await repository.recordWeight(uid, 70);
      await repository.recordBloodPressure(
        uid,
        systolicMmHg: 120,
        diastolicMmHg: 80,
        recordedAt: DateTime.utc(2026, 8, 1),
        now: DateTime.utc(2026, 8, 9),
      );
      final BloodPressureMeasurement bp =
          (await repository.fetchLatestBloodPressures(uid, limit: 1)).first;

      await repository.deleteBloodPressureMeasurement(uid, bp.id);

      expect(await repository.fetchLatestBloodPressures(uid, limit: 5), isEmpty);
      expect(
        (await repository.fetchLatestWeights(uid, limit: 1)).first.valueKg,
        70,
      );
      expect((await profileMap())?['weightKg'], 70);
    });

    test('weight and BP queries are type-isolated', () async {
      await repository.recordWeight(uid, 72.5);
      await repository.recordBloodPressure(
        uid,
        systolicMmHg: 122,
        diastolicMmHg: 78,
        recordedAt: DateTime.utc(2026, 8, 2),
        now: DateTime.utc(2026, 8, 9),
      );

      final List<WeightMeasurement> weights = await repository
          .fetchLatestWeights(uid, limit: 10);
      final List<BloodPressureMeasurement> bps = await repository
          .fetchLatestBloodPressures(uid, limit: 10);

      expect(weights, hasLength(1));
      expect(bps, hasLength(1));
      expect(weights.first.valueKg, 72.5);
      expect(bps.first.systolicMmHg, 122);
    });
  });
}
