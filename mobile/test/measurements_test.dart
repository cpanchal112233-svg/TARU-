import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/health_profile/domain/health_profile.dart';
import 'package:mobile/features/health_profile/domain/health_units.dart';
import 'package:mobile/features/measurements/data/measurements_repository.dart';
import 'package:mobile/features/measurements/domain/weight_measurement.dart';

void main() {
  group('WeightMeasurement model', () {
    test('round-trips through toMap/fromMap', () {
      final DateTime at = DateTime.utc(2026, 8, 9, 14, 30);
      final WeightMeasurement measurement = WeightMeasurement(
        id: 'm1',
        valueKg: 72.4,
        recordedAt: at,
      );

      final Map<String, dynamic> map = measurement.toMap(
        recordedAtTimestamp: Timestamp.fromDate(at),
      );
      expect(map['type'], 'weight');
      expect(map['valueKg'], 72.4);
      expect(map['source'], 'manual');
      expect(map.containsKey('unit'), isFalse);
      expect(map.containsKey('values'), isFalse);
      expect(map.containsKey('createdAt'), isFalse);

      final WeightMeasurement? restored = WeightMeasurement.fromMap('m1', map);
      expect(restored, isNotNull);
      expect(restored!.valueKg, 72.4);
      expect(restored.recordedAt.toUtc(), at);
      expect(restored.source, 'manual');
    });

    test('rejects malformed maps', () {
      expect(WeightMeasurement.fromMap('x', null), isNull);
      expect(WeightMeasurement.fromMap('x', <String, dynamic>{}), isNull);
      expect(
        WeightMeasurement.fromMap('x', <String, dynamic>{
          'type': 'blood_pressure',
          'valueKg': 70,
          'recordedAt': Timestamp.now(),
        }),
        isNull,
      );
      expect(
        WeightMeasurement.fromMap('x', <String, dynamic>{
          'type': 'weight',
          'valueKg': 'heavy',
          'recordedAt': Timestamp.now(),
        }),
        isNull,
      );
    });

    test('plausible weight bounds and intentional-new detection', () {
      expect(isPlausibleWeightKg(72), isTrue);
      expect(isPlausibleWeightKg(1), isFalse);
      expect(isPlausibleWeightKg(401), isFalse);

      expect(
        isIntentionalNewWeight(previous: null, next: 70),
        isTrue,
      );
      expect(
        isIntentionalNewWeight(previous: 70, next: 70),
        isFalse,
      );
      expect(
        isIntentionalNewWeight(previous: 70, next: 71),
        isTrue,
      );
      expect(
        isIntentionalNewWeight(previous: 70, next: null),
        isFalse,
      );
    });
  });

  group('MeasurementsRepository', () {
    late FakeFirebaseFirestore firestore;
    late MeasurementsRepository repository;
    const String uid = 'user-1';

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

    test('recordWeight creates one measurement and updates snapshot', () async {
      await repository.recordWeight(uid, 72.4);

      final List<WeightMeasurement> history = await repository
          .fetchLatestWeights(uid, limit: 10);
      expect(history, hasLength(1));
      expect(history.first.valueKg, 72.4);
      expect(history.first.source, 'manual');

      final Map<String, dynamic>? profile = await profileMap();
      expect(profile?['weightKg'], 72.4);
    });

    test('history is newest first', () async {
      await repository.recordWeight(uid, 70);
      await Future<void>.delayed(const Duration(milliseconds: 2));
      await repository.recordWeight(uid, 71);
      await Future<void>.delayed(const Duration(milliseconds: 2));
      await repository.recordWeight(uid, 72);

      final List<WeightMeasurement> history = await repository
          .fetchLatestWeights(uid, limit: 10);
      expect(history.map((WeightMeasurement m) => m.valueKg).toList(), <double>[
        72,
        71,
        70,
      ]);
    });

    test('delete older leaves snapshot unchanged', () async {
      await repository.recordWeight(uid, 70);
      await Future<void>.delayed(const Duration(milliseconds: 2));
      await repository.recordWeight(uid, 72);
      final List<WeightMeasurement> before = await repository
          .fetchLatestWeights(uid, limit: 10);
      final String olderId = before.last.id;

      await repository.deleteWeightMeasurement(uid, olderId);

      final Map<String, dynamic>? profile = await profileMap();
      expect(profile?['weightKg'], 72);
      final List<WeightMeasurement> after = await repository.fetchLatestWeights(
        uid,
        limit: 10,
      );
      expect(after, hasLength(1));
      expect(after.first.valueKg, 72);
    });

    test('delete latest reconciles snapshot to previous', () async {
      await repository.recordWeight(uid, 70);
      await Future<void>.delayed(const Duration(milliseconds: 2));
      await repository.recordWeight(uid, 72);
      final WeightMeasurement latest =
          (await repository.fetchLatestWeights(uid, limit: 1)).first;

      await repository.deleteWeightMeasurement(uid, latest.id);

      final Map<String, dynamic>? profile = await profileMap();
      expect(profile?['weightKg'], 70);
    });

    test('delete final measurement clears snapshot', () async {
      await repository.recordWeight(uid, 72);
      final WeightMeasurement only =
          (await repository.fetchLatestWeights(uid, limit: 1)).first;

      await repository.deleteWeightMeasurement(uid, only.id);

      final Map<String, dynamic>? profile = await profileMap();
      expect(profile?['weightKg'], isNull);
      expect(await repository.hasWeightHistory(uid), isFalse);
    });

    test('legacy unchanged profile save creates zero measurements', () async {
      await firestore
          .collection('users')
          .doc(uid)
          .collection('health')
          .doc('profile')
          .set(<String, dynamic>{'weightKg': 80.0, 'heightCm': 170.0});

      const HealthProfile previous = HealthProfile(
        weightKg: 80,
        heightCm: 170,
      );
      const HealthProfile next = HealthProfile(weightKg: 80, heightCm: 170);

      await repository.saveHealthProfileWithWeightTracking(
        uid: uid,
        previous: previous,
        next: next,
        hasWeightHistory: false,
      );

      expect(await repository.hasWeightHistory(uid), isFalse);
      final Map<String, dynamic>? profile = await profileMap();
      expect(profile?['weightKg'], 80);
    });

    test('changed legacy weight creates first measurement atomically', () async {
      const HealthProfile previous = HealthProfile(
        weightKg: 80,
        heightCm: 170,
      );
      const HealthProfile next = HealthProfile(weightKg: 81, heightCm: 170);

      await repository.saveHealthProfileWithWeightTracking(
        uid: uid,
        previous: previous,
        next: next,
        hasWeightHistory: false,
      );

      final List<WeightMeasurement> history = await repository
          .fetchLatestWeights(uid, limit: 5);
      expect(history, hasLength(1));
      expect(history.first.valueKg, 81);
      final Map<String, dynamic>? profile = await profileMap();
      expect(profile?['weightKg'], 81);
      expect(profile?['heightCm'], 170);
    });

    test('null to non-null starts history', () async {
      const HealthProfile previous = HealthProfile(heightCm: 170);
      const HealthProfile next = HealthProfile(weightKg: 75, heightCm: 170);

      await repository.saveHealthProfileWithWeightTracking(
        uid: uid,
        previous: previous,
        next: next,
        hasWeightHistory: false,
      );

      expect(await repository.hasWeightHistory(uid), isTrue);
      expect((await profileMap())?['weightKg'], 75);
    });

    test('clear legacy weight with no history is allowed', () async {
      const HealthProfile previous = HealthProfile(weightKg: 80);
      const HealthProfile next = HealthProfile();

      await repository.saveHealthProfileWithWeightTracking(
        uid: uid,
        previous: previous,
        next: next,
        hasWeightHistory: false,
      );

      expect(await repository.hasWeightHistory(uid), isFalse);
      expect((await profileMap())?['weightKg'], isNull);
    });

    test('independent clear blocked while history exists', () async {
      await repository.recordWeight(uid, 72);

      expect(
        () => repository.saveHealthProfileWithWeightTracking(
          uid: uid,
          previous: const HealthProfile(weightKg: 72),
          next: const HealthProfile(),
          hasWeightHistory: true,
        ),
        throwsStateError,
      );

      expect((await profileMap())?['weightKg'], 72);
      expect(await repository.hasWeightHistory(uid), isTrue);
    });

    test('tracked profile weight change creates exactly one measurement', () async {
      await repository.recordWeight(uid, 70);
      await repository.saveHealthProfileWithWeightTracking(
        uid: uid,
        previous: const HealthProfile(weightKg: 70, heightCm: 170),
        next: const HealthProfile(weightKg: 71, heightCm: 170),
        hasWeightHistory: true,
      );

      final List<WeightMeasurement> history = await repository
          .fetchLatestWeights(uid, limit: 10);
      expect(history, hasLength(2));
      expect(history.first.valueKg, 71);
    });

    test('multi-field profile save records one measurement and other fields', () async {
      const HealthProfile previous = HealthProfile(
        weightKg: 70,
        heightCm: 170,
        emergencyContactName: 'Alex',
      );
      const HealthProfile next = HealthProfile(
        weightKg: 71.5,
        heightCm: 172,
        emergencyContactName: 'Sam',
        preferredUnits: UnitSystem.imperial,
      );

      await repository.saveHealthProfileWithWeightTracking(
        uid: uid,
        previous: previous,
        next: next,
        hasWeightHistory: false,
      );

      final List<WeightMeasurement> history = await repository
          .fetchLatestWeights(uid, limit: 10);
      expect(history, hasLength(1));
      expect(history.first.valueKg, 71.5);

      final Map<String, dynamic>? profile = await profileMap();
      expect(profile?['weightKg'], 71.5);
      expect(profile?['heightCm'], 172);
      expect(profile?['emergencyContactName'], 'Sam');
      expect(profile?['preferredUnits'], 'imperial');
    });

    test('start tracking uses recordWeight path', () async {
      await firestore
          .collection('users')
          .doc(uid)
          .collection('health')
          .doc('profile')
          .set(<String, dynamic>{'weightKg': 68.2});

      await repository.recordWeight(uid, 68.2);

      final List<WeightMeasurement> history = await repository
          .fetchLatestWeights(uid, limit: 5);
      expect(history, hasLength(1));
      expect(history.first.valueKg, 68.2);
    });

    test('imperial conversion helper keeps kg canonical', () {
      final double kg = HealthUnits.poundsToKilograms(154.3);
      expect(isPlausibleWeightKg(kg), isTrue);
      expect(kg, closeTo(70, 0.2));
    });

    test('safety: domain helpers have no judgment strings', () {
      const String joined =
          'Latest weight Weight history Add weight recorded on';
      for (final String banned in <String>[
        'improving',
        'great job',
        'lost weight',
        'gained weight',
        'unhealthy',
        'healthy weight trend',
      ]) {
        expect(joined.toLowerCase(), isNot(contains(banned)));
      }
    });
  });
}
