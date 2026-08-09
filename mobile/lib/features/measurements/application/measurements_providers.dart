import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/firebase_providers.dart';
import '../../auth/application/auth_providers.dart';
import '../../health_profile/domain/health_profile.dart';
import '../data/measurements_repository.dart';
import '../domain/blood_pressure_measurement.dart';
import '../domain/weight_measurement.dart';

final measurementsRepositoryProvider = Provider<MeasurementsRepository>(
  (ref) => MeasurementsRepository(ref.watch(firestoreProvider)),
);

final weightHistoryProvider = StreamProvider<List<WeightMeasurement>>((ref) {
  final User? user = ref.watch(authStateChangesProvider).value;
  if (user == null) {
    return Stream<List<WeightMeasurement>>.value(const <WeightMeasurement>[]);
  }
  return ref.watch(measurementsRepositoryProvider).watchWeightHistory(user.uid);
});

final latestWeightMeasurementProvider = StreamProvider<WeightMeasurement?>((
  ref,
) {
  final User? user = ref.watch(authStateChangesProvider).value;
  if (user == null) {
    return Stream<WeightMeasurement?>.value(null);
  }
  return ref.watch(measurementsRepositoryProvider).watchLatestWeight(user.uid);
});

/// True when at least one weight measurement exists (tracked state).
final hasWeightHistoryProvider = Provider<bool>((ref) {
  final AsyncValue<List<WeightMeasurement>> history = ref.watch(
    weightHistoryProvider,
  );
  return history.maybeWhen(
    data: (List<WeightMeasurement> items) => items.isNotEmpty,
    orElse: () => false,
  );
});

final bloodPressureHistoryProvider =
    StreamProvider<List<BloodPressureMeasurement>>((ref) {
      final User? user = ref.watch(authStateChangesProvider).value;
      if (user == null) {
        return Stream<List<BloodPressureMeasurement>>.value(
          const <BloodPressureMeasurement>[],
        );
      }
      return ref
          .watch(measurementsRepositoryProvider)
          .watchBloodPressureHistory(user.uid);
    });

final latestBloodPressureProvider =
    StreamProvider<BloodPressureMeasurement?>((ref) {
      final User? user = ref.watch(authStateChangesProvider).value;
      if (user == null) {
        return Stream<BloodPressureMeasurement?>.value(null);
      }
      return ref
          .watch(measurementsRepositoryProvider)
          .watchLatestBloodPressure(user.uid);
    });

final recordWeightProvider =
    Provider<Future<void> Function(double, {DateTime? recordedAt})>((ref) {
      return (double valueKg, {DateTime? recordedAt}) async {
        final User? user = ref.read(authStateChangesProvider).value;
        if (user == null) {
          throw StateError('Cannot record weight while signed out.');
        }
        await ref
            .read(measurementsRepositoryProvider)
            .recordWeight(user.uid, valueKg, recordedAt: recordedAt);
      };
    });

final deleteWeightMeasurementProvider =
    Provider<Future<void> Function(String)>((ref) {
      return (String measurementId) async {
        final User? user = ref.read(authStateChangesProvider).value;
        if (user == null) {
          throw StateError('Cannot delete weight while signed out.');
        }
        await ref
            .read(measurementsRepositoryProvider)
            .deleteWeightMeasurement(user.uid, measurementId);
      };
    });

final recordBloodPressureProvider =
    Provider<
      Future<void> Function({
        required int systolicMmHg,
        required int diastolicMmHg,
        DateTime? recordedAt,
      })
    >((ref) {
      return ({
        required int systolicMmHg,
        required int diastolicMmHg,
        DateTime? recordedAt,
      }) async {
        final User? user = ref.read(authStateChangesProvider).value;
        if (user == null) {
          throw StateError('Cannot record blood pressure while signed out.');
        }
        await ref
            .read(measurementsRepositoryProvider)
            .recordBloodPressure(
              user.uid,
              systolicMmHg: systolicMmHg,
              diastolicMmHg: diastolicMmHg,
              recordedAt: recordedAt,
            );
      };
    });

final deleteBloodPressureMeasurementProvider =
    Provider<Future<void> Function(String)>((ref) {
      return (String measurementId) async {
        final User? user = ref.read(authStateChangesProvider).value;
        if (user == null) {
          throw StateError('Cannot delete blood pressure while signed out.');
        }
        await ref
            .read(measurementsRepositoryProvider)
            .deleteBloodPressureMeasurement(user.uid, measurementId);
      };
    });

/// Saves Health Profile with weight-history semantics in one batch when a
/// new weight must be recorded (authoritative mirror gate).
final saveHealthProfileWithWeightTrackingProvider =
    Provider<
      Future<void> Function({
        required HealthProfile previous,
        required HealthProfile next,
      })
    >((ref) {
      return ({
        required HealthProfile previous,
        required HealthProfile next,
      }) async {
        final User? user = ref.read(authStateChangesProvider).value;
        if (user == null) {
          throw StateError('Cannot save a health profile while signed out.');
        }

        final bool hasHistory = await ref
            .read(measurementsRepositoryProvider)
            .hasWeightHistory(user.uid);

        await ref
            .read(measurementsRepositoryProvider)
            .saveHealthProfileWithWeightTracking(
              uid: user.uid,
              previous: previous,
              next: next,
              hasWeightHistory: hasHistory,
            );
      };
    });
