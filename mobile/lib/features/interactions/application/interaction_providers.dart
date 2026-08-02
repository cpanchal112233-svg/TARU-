import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../health_profile/application/medications_providers.dart';
import '../../health_profile/domain/medication.dart';
import '../../safety/application/safety_providers.dart';
import '../../safety/domain/safety_profile.dart';
import '../domain/medicine_checker.dart';
import '../domain/medicine_warning.dart';

/// Warnings for the medicines the user has saved.
final medicineWarningsProvider = Provider<List<MedicineWarning>>((ref) {
  final MedicationRecord? record = ref.watch(medicationsProvider).value;

  if (record == null) return const <MedicineWarning>[];

  return MedicineChecker.check(
    medicines: record.medications,
    profile: ref.watch(safetyProfileProvider),
  );
});

/// Warnings for a list being edited, before it is saved.
///
/// The editor needs to say "this clashes with what you already take" while the
/// user is still typing, so the medicine list comes in as an argument rather
/// than from storage.
final draftWarningsProvider =
    Provider.family<List<MedicineWarning>, List<UserMedication>>((
      ref,
      medicines,
    ) {
      final SafetyProfile profile = ref.watch(safetyProfileProvider);

      return MedicineChecker.check(medicines: medicines, profile: profile);
    });
