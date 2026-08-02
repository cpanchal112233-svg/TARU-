import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../health_profile/application/allergies_providers.dart';
import '../../health_profile/application/conditions_providers.dart';
import '../../health_profile/application/health_profile_providers.dart';
import '../../health_profile/application/medications_providers.dart';
import '../../health_profile/domain/allergy.dart';
import '../../health_profile/domain/health_profile.dart';
import '../../health_profile/domain/medical_condition.dart';
import '../../health_profile/domain/medication.dart';
import '../domain/safety_profile.dart';

/// The health profile reduced to what safety checks need.
///
/// Falls back to [SafetyProfile.unknown] while anything is still loading,
/// which makes TARU more cautious rather than less: an unknown profile counts
/// as unanswered allergies and medicines.
final safetyProfileProvider = Provider<SafetyProfile>((ref) {
  final HealthProfile? profile = ref.watch(healthProfileProvider).value;
  final ConditionRecord? conditions = ref.watch(conditionsProvider).value;
  final AllergyRecord? allergies = ref.watch(allergiesProvider).value;
  final MedicationRecord? medications = ref.watch(medicationsProvider).value;

  if (profile == null ||
      conditions == null ||
      allergies == null ||
      medications == null) {
    return SafetyProfile.unknown;
  }

  return SafetyProfile.from(
    profile: profile,
    conditions: conditions,
    allergies: allergies,
    medications: medications,
  );
});
