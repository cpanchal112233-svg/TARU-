import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/health_profile/domain/health_profile.dart';
import 'package:mobile/features/health_profile/domain/health_profile_weight_draft.dart';
import 'package:mobile/features/measurements/data/measurements_repository.dart';
import 'package:mobile/features/measurements/domain/weight_measurement.dart';

/// Regression for the live Phase 8 smoke-test defect:
/// Health Profile stayed mounted while Weight History updated
/// `profile.weightKg`; a later Save could treat the stale draft as an
/// intentional weight change and create an unintended measurement.
void main() {
  group('Health Profile weight draft sync', () {
    test(
      'non-dirty draft follows live profile and Save does not create a measurement',
      () async {
        const double openedAt = 60;
        const double liveAfterWeightHistory = 99.2;

        // Mounted form: user has not edited weight.
        const bool weightDirty = false;
        const double draftWeightKg = openedAt;

        final double? synced = resolveHealthProfileDraftWeightKg(
          draftWeightKg: draftWeightKg,
          liveWeightKg: liveAfterWeightHistory,
          weightDirty: weightDirty,
        );

        expect(synced, liveAfterWeightHistory);
        expect(
          isIntentionalNewWeight(
            previous: liveAfterWeightHistory,
            next: synced,
          ),
          isFalse,
        );

        final FakeFirebaseFirestore firestore = FakeFirebaseFirestore();
        const String uid = 'draft-sync-user';
        final MeasurementsRepository repo = MeasurementsRepository(firestore);

        // Seed the live mirrored state Weight History would have written.
        await firestore
            .collection('users')
            .doc(uid)
            .collection('health')
            .doc('profile')
            .set(<String, dynamic>{'weightKg': liveAfterWeightHistory});
        await firestore
            .collection('users')
            .doc(uid)
            .collection('measurements')
            .doc('existing')
            .set(<String, dynamic>{
              'type': measurementTypeWeight,
              'valueKg': liveAfterWeightHistory,
              'source': measurementSourceManual,
              'recordedAt': Timestamp.fromDate(
                DateTime.utc(2026, 8, 9, 15, 45),
              ),
            });

        final HealthProfile liveProfile = HealthProfile(
          weightKg: liveAfterWeightHistory,
          heightCm: 165,
        );
        final HealthProfile next = HealthProfile(
          weightKg: synced,
          heightCm: 165,
        );

        await repo.saveHealthProfileWithWeightTracking(
          uid: uid,
          previous: liveProfile,
          next: next,
          hasWeightHistory: true,
        );

        final QuerySnapshot measurements = await firestore
            .collection('users')
            .doc(uid)
            .collection('measurements')
            .get();
        expect(measurements.docs, hasLength(1));
        expect(measurements.docs.single.id, 'existing');
      },
    );

    test(
      'dirty draft survives live profile refresh and remains intentional',
      () {
        const double intentionalEdit = 61;
        const double liveAfterWeightHistory = 99.2;

        final double? preserved = resolveHealthProfileDraftWeightKg(
          draftWeightKg: intentionalEdit,
          liveWeightKg: liveAfterWeightHistory,
          weightDirty: true,
        );

        expect(preserved, intentionalEdit);
        expect(sameWeightKg(preserved, liveAfterWeightHistory), isFalse);
        expect(
          isIntentionalNewWeight(
            previous: liveAfterWeightHistory,
            next: preserved,
          ),
          isTrue,
        );
      },
    );

    test('sameWeightKg treats near-equal values as equal', () {
      expect(sameWeightKg(60, 60), isTrue);
      expect(sameWeightKg(60, 60.00005), isTrue);
      expect(sameWeightKg(60, 61), isFalse);
      expect(sameWeightKg(null, null), isTrue);
      expect(sameWeightKg(60, null), isFalse);
    });
  });
}
