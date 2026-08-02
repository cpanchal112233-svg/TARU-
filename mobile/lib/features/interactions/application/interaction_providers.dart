import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../health_profile/application/medications_providers.dart';
import '../../health_profile/domain/medication.dart';
import '../../safety/application/safety_providers.dart';
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
