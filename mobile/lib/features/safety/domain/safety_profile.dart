import 'package:flutter/foundation.dart';

import '../../health_profile/domain/allergy.dart';
import '../../health_profile/domain/health_profile.dart';
import '../../health_profile/domain/medical_condition.dart';
import '../../health_profile/domain/medication.dart';
import 'health_risk.dart';

/// The health profile, reduced to the handful of facts that change a safety
/// decision.
///
/// The rest of the profile — height, blood group, when a condition was
/// diagnosed — matters elsewhere but not here, and leaving it behind keeps the
/// symptom check and the interaction checker testable with a couple of lines
/// of setup.
@immutable
class SafetyProfile {
  const SafetyProfile({
    this.riskFactors = const <HealthRiskFactor>{},
    this.blockedGuards = const <SelfCareGuard, String>{},
    this.allergiesUnanswered = false,
    this.medicationsUnanswered = false,
    this.conditionsUnanswered = false,
  });

  static const SafetyProfile unknown = SafetyProfile(
    allergiesUnanswered: true,
    medicationsUnanswered: true,
    conditionsUnanswered: true,
  );

  factory SafetyProfile.from({
    required HealthProfile profile,
    required ConditionRecord conditions,
    required AllergyRecord allergies,
    required MedicationRecord medications,
  }) {
    final Set<MedicalConditionType> hasCondition = conditions.conditions
        .map((UserCondition condition) => condition.type)
        .toSet();

    final Set<MedicationIngredient> takes = medications.medications
        .map((UserMedication medication) => medication.ingredient)
        .toSet();

    final Set<AllergenType> allergicTo = allergies.allergies
        .map((UserAllergy allergy) => allergy.type)
        .toSet();

    final int? age = profile.ageInYears;

    final bool onBloodThinner =
        takes.contains(MedicationIngredient.warfarin) ||
        takes.contains(MedicationIngredient.clopidogrel) ||
        takes.contains(MedicationIngredient.aspirin);

    final bool immunosuppressed =
        hasCondition.contains(MedicalConditionType.humanImmunodeficiencyVirus) ||
        hasCondition.contains(MedicalConditionType.cancer) ||
        takes.contains(MedicationIngredient.prednisolone);

    final bool cirrhosis = hasCondition.contains(
      MedicalConditionType.liverCirrhosis,
    );

    final bool kidneyDisease = hasCondition.contains(
      MedicalConditionType.chronicKidneyDisease,
    );

    final bool heartFailure = hasCondition.contains(
      MedicalConditionType.heartFailure,
    );

    final bool ulcer = hasCondition.contains(MedicalConditionType.pepticUlcer);

    final bool pregnant = profile.pregnancyStatus == PregnancyStatus.pregnant;

    final Set<HealthRiskFactor> factors = <HealthRiskFactor>{
      if (pregnant) HealthRiskFactor.pregnant,
      if (profile.pregnancyStatus == PregnancyStatus.breastfeeding)
        HealthRiskFactor.breastfeeding,
      if (age != null && age >= 65) HealthRiskFactor.olderAdult,
      if (age != null && age < 16) HealthRiskFactor.child,
      if (hasCondition.contains(MedicalConditionType.type1Diabetes) ||
          hasCondition.contains(MedicalConditionType.type2Diabetes))
        HealthRiskFactor.diabetes,
      if (hasCondition.contains(MedicalConditionType.coronaryArteryDisease) ||
          heartFailure ||
          hasCondition.contains(MedicalConditionType.atrialFibrillation))
        HealthRiskFactor.heartDisease,
      if (heartFailure) HealthRiskFactor.heartFailure,
      if (hasCondition.contains(MedicalConditionType.hypertension))
        HealthRiskFactor.highBloodPressure,
      if (hasCondition.contains(MedicalConditionType.strokeHistory))
        HealthRiskFactor.strokeHistory,
      if (kidneyDisease) HealthRiskFactor.kidneyDisease,
      if (cirrhosis ||
          hasCondition.contains(MedicalConditionType.hepatitisB) ||
          hasCondition.contains(MedicalConditionType.hepatitisC))
        HealthRiskFactor.liverDisease,
      if (hasCondition.contains(MedicalConditionType.asthma) ||
          hasCondition.contains(
            MedicalConditionType.chronicObstructivePulmonaryDisease,
          ))
        HealthRiskFactor.lungDisease,
      if (immunosuppressed) HealthRiskFactor.immunosuppressed,
      if (onBloodThinner) HealthRiskFactor.bleedingRisk,
      if (allergies.emergencyRisks.isNotEmpty)
        HealthRiskFactor.anaphylaxisHistory,
      if (ulcer) HealthRiskFactor.stomachUlcer,
      if (hasCondition.contains(MedicalConditionType.epilepsy))
        HealthRiskFactor.epilepsy,
    };

    return SafetyProfile(
      riskFactors: factors,
      blockedGuards: _blockedGuards(
        allergicTo: allergicTo,
        cirrhosis: cirrhosis,
        kidneyDisease: kidneyDisease,
        heartFailure: heartFailure,
        ulcer: ulcer,
        onBloodThinner: onBloodThinner,
        pregnant: pregnant,
      ),
      allergiesUnanswered: !allergies.hasAnswered,
      medicationsUnanswered: !medications.hasAnswered,
      conditionsUnanswered: !conditions.hasAnswered,
    );
  }

  /// Which over-the-counter suggestions must not be made, and why.
  ///
  /// The reason is shown to the user rather than kept internal. "TARU has not
  /// suggested ibuprofen because of your kidney disease" is useful to read
  /// before someone reaches for the packet anyway.
  static Map<SelfCareGuard, String> _blockedGuards({
    required Set<AllergenType> allergicTo,
    required bool cirrhosis,
    required bool kidneyDisease,
    required bool heartFailure,
    required bool ulcer,
    required bool onBloodThinner,
    required bool pregnant,
  }) {
    final Map<SelfCareGuard, String> blocked = <SelfCareGuard, String>{};

    if (allergicTo.contains(AllergenType.paracetamol)) {
      blocked[SelfCareGuard.paracetamol] =
          'Paracetamol is not suggested because you have recorded an allergy '
          'to it.';
    } else if (cirrhosis) {
      blocked[SelfCareGuard.paracetamol] =
          'Paracetamol is left out because liver cirrhosis changes the safe '
          'dose. Ask your doctor what yours is.';
    }

    const String noNsaid =
        'Ibuprofen and similar painkillers are not suggested because ';

    if (allergicTo.contains(AllergenType.nonSteroidalAntiInflammatories) ||
        allergicTo.contains(AllergenType.aspirin)) {
      blocked[SelfCareGuard.nsaid] = '${noNsaid}of your recorded allergy.';
    } else if (kidneyDisease) {
      blocked[SelfCareGuard.nsaid] =
          '${noNsaid}they can reduce kidney function further.';
    } else if (heartFailure) {
      blocked[SelfCareGuard.nsaid] =
          '${noNsaid}they make the body hold on to fluid.';
    } else if (ulcer) {
      blocked[SelfCareGuard.nsaid] =
          '${noNsaid}of your history of a stomach ulcer.';
    } else if (onBloodThinner) {
      blocked[SelfCareGuard.nsaid] =
          '${noNsaid}they add to the bleeding risk from your blood thinner.';
    } else if (pregnant) {
      blocked[SelfCareGuard.nsaid] = '${noNsaid}you are pregnant.';
    } else if (cirrhosis) {
      blocked[SelfCareGuard.nsaid] = '${noNsaid}of your liver disease.';
    }

    if (kidneyDisease || heartFailure || cirrhosis) {
      blocked[SelfCareGuard.extraFluids] =
          'You may have been given a daily fluid limit. Keep to it, and ask '
          'your care team how to replace what you are losing.';
    }

    return blocked;
  }

  final Set<HealthRiskFactor> riskFactors;
  final Map<SelfCareGuard, String> blockedGuards;

  /// Advice is given more cautiously when TARU has never been told these.
  final bool allergiesUnanswered;
  final bool medicationsUnanswered;
  final bool conditionsUnanswered;

  bool has(HealthRiskFactor factor) => riskFactors.contains(factor);

  bool allows(SelfCareGuard? guard) =>
      guard == null || !blockedGuards.containsKey(guard);
}
