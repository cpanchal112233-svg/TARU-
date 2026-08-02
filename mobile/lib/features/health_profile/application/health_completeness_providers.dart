import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/allergy.dart';
import '../domain/health_completeness.dart';
import '../domain/health_profile.dart';
import '../domain/medical_condition.dart';
import '../domain/medication.dart';
import 'allergies_providers.dart';
import 'conditions_providers.dart';
import 'health_profile_providers.dart';
import 'medications_providers.dart';

/// Combines every part of the health profile into one progress figure.
///
/// Stays null until all three sources have loaded, so the Home card never
/// flashes a misleadingly low number while Firestore is still answering.
final healthCompletenessProvider = Provider<HealthCompleteness?>((ref) {
  final HealthProfile? profile = ref.watch(healthProfileProvider).value;
  final ConditionRecord? conditions = ref.watch(conditionsProvider).value;
  final AllergyRecord? allergies = ref.watch(allergiesProvider).value;
  final MedicationRecord? medications = ref.watch(medicationsProvider).value;

  if (profile == null ||
      conditions == null ||
      allergies == null ||
      medications == null) {
    return null;
  }

  return HealthCompleteness.from(
    profile: profile,
    conditions: conditions,
    allergies: allergies,
    medications: medications,
  );
});
