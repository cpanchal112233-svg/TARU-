import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/health_profile/domain/allergy.dart';
import 'package:mobile/features/health_profile/domain/health_profile.dart';
import 'package:mobile/features/health_profile/domain/medical_condition.dart';
import 'package:mobile/features/health_profile/domain/medication.dart';
import 'package:mobile/features/triage/domain/symptom.dart';
import 'package:mobile/features/triage/domain/symptom_guidance.dart';
import 'package:mobile/features/triage/domain/triage_engine.dart';
import 'package:mobile/features/triage/domain/triage_level.dart';
import 'package:mobile/features/safety/domain/safety_profile.dart';
import 'package:mobile/features/triage/domain/triage_result.dart';
import 'package:mobile/features/triage/domain/triage_rules.dart';

/// Builds a triage profile the way the app does, from real health records,
/// so these tests break if the mapping from conditions to risk factors drifts.
SafetyProfile profileWith({
  List<MedicalConditionType> conditions = const <MedicalConditionType>[],
  List<AllergenType> allergies = const <AllergenType>[],
  List<MedicationIngredient> medicines = const <MedicationIngredient>[],
  DateTime? dateOfBirth,
  PregnancyStatus? pregnancyStatus,
}) {
  return SafetyProfile.from(
    profile: HealthProfile(
      dateOfBirth: dateOfBirth,
      pregnancyStatus: pregnancyStatus,
    ),
    conditions: ConditionRecord(
      conditions: <UserCondition>[
        for (final MedicalConditionType type in conditions)
          UserCondition(type: type),
      ],
      noKnownConditions: conditions.isEmpty,
    ),
    allergies: AllergyRecord(
      allergies: <UserAllergy>[
        for (final AllergenType type in allergies) UserAllergy(type: type),
      ],
      noKnownAllergies: allergies.isEmpty,
    ),
    medications: MedicationRecord(
      medications: <UserMedication>[
        for (final MedicationIngredient ingredient in medicines)
          UserMedication(ingredient: ingredient),
      ],
      takesNoMedication: medicines.isEmpty,
    ),
  );
}

TriageResult assess(
  List<Symptom> symptoms, {
  Set<String> answeredYes = const <String>{},
  SafetyProfile? profile,
}) {
  return TriageEngine.assess(
    symptoms: symptoms,
    flaggedCodes: answeredYes,
    profile: profile ?? profileWith(),
  );
}

void main() {
  group('guidance coverage', () {
    test('every symptom has rules written for it', () {
      expect(symptomsWithGuidance, containsAll(Symptom.values));
    });

    test('every red flag code is unique across all symptoms', () {
      final List<String> codes = <String>[
        for (final Symptom symptom in Symptom.values)
          for (final RedFlag flag in guidanceFor(symptom).redFlags) flag.code,
      ];

      expect(codes.toSet().length, codes.length);
    });
  });

  group('levels', () {
    test('an ordinary sore throat with no red flags stays self care', () {
      final TriageResult result = assess(<Symptom>[Symptom.soreThroat]);

      expect(result.level, TriageLevel.selfCare);
      expect(result.selfCare, isNotEmpty);
    });

    test('chest pain is never self care, even with every answer no', () {
      final TriageResult result = assess(<Symptom>[Symptom.chestPain]);

      expect(result.level, TriageLevel.urgent);
    });

    test('a red flag escalates and explains itself', () {
      final TriageResult result = assess(
        <Symptom>[Symptom.headache],
        answeredYes: <String>{'headache.thunderclap'},
      );

      expect(result.level, TriageLevel.emergency);
      expect(result.answerReasons, hasLength(1));
      expect(result.actions.first, emergencyNumberHint);
    });

    test('a reassuring answer cannot pull the level back down', () {
      final TriageResult result = assess(
        <Symptom>[Symptom.dizziness],
        answeredYes: <String>{'dizziness.postural', 'dizziness.stroke'},
      );

      expect(result.level, TriageLevel.emergency);
    });

    test('the worst of several symptoms decides the outcome', () {
      final TriageResult result = assess(<Symptom>[
        Symptom.cough,
        Symptom.fever,
        Symptom.chestPain,
      ]);

      expect(result.level, TriageLevel.urgent);
    });

    test('home remedies disappear once someone needs to be seen today', () {
      final TriageResult result = assess(
        <Symptom>[Symptom.fever],
        answeredYes: <String>{'fever.threeDays'},
      );

      expect(result.level, TriageLevel.urgent);
      expect(result.selfCare, isEmpty);
    });
  });

  group('the profile changes the answer', () {
    test('chest pain with a known heart condition becomes an emergency', () {
      final TriageResult result = assess(
        <Symptom>[Symptom.chestPain],
        profile: profileWith(
          conditions: <MedicalConditionType>[
            MedicalConditionType.coronaryArteryDisease,
          ],
        ),
      );

      expect(result.level, TriageLevel.emergency);
      expect(result.profileReasons, hasLength(1));
    });

    test('a fever is urgent for someone whose immunity is suppressed', () {
      final TriageResult result = assess(
        <Symptom>[Symptom.fever],
        profile: profileWith(
          conditions: <MedicalConditionType>[MedicalConditionType.cancer],
        ),
      );

      expect(result.level, TriageLevel.urgent);
    });

    test('a head knock is watch-and-wait, but an emergency on warfarin', () {
      const Set<String> knock = <String>{'injury.headKnock'};

      expect(
        assess(<Symptom>[Symptom.injury], answeredYes: knock).level,
        TriageLevel.soon,
      );

      expect(
        assess(
          <Symptom>[Symptom.injury],
          answeredYes: knock,
          profile: profileWith(
            medicines: <MedicationIngredient>[MedicationIngredient.warfarin],
          ),
        ).level,
        TriageLevel.emergency,
      );
    });

    test('belly pain in pregnancy is escalated to an emergency', () {
      final TriageResult result = assess(<Symptom>[
        Symptom.abdominalPain,
      ], profile: profileWith(pregnancyStatus: PregnancyStatus.pregnant));

      expect(result.level, TriageLevel.emergency);
    });

    test('a risk factor that changes nothing is not reported', () {
      final TriageResult result = assess(
        <Symptom>[Symptom.soreThroat],
        profile: profileWith(
          conditions: <MedicalConditionType>[MedicalConditionType.hypertension],
        ),
      );

      expect(result.profileReasons, isEmpty);
    });
  });

  group('medicine safety', () {
    test('ibuprofen is withheld with kidney disease, and paracetamol is '
        'still offered', () {
      final TriageResult result = assess(
        <Symptom>[Symptom.backPain],
        profile: profileWith(
          conditions: <MedicalConditionType>[
            MedicalConditionType.chronicKidneyDisease,
          ],
        ),
      );

      expect(
        result.selfCare.any((String tip) => tip.contains('Ibuprofen')),
        isFalse,
      );
      expect(
        result.selfCare.any((String tip) => tip.contains('Paracetamol')),
        isTrue,
      );
      expect(result.cautions.single, contains('kidney'));
    });

    test('paracetamol is withheld from someone allergic to it', () {
      final TriageResult result = assess(
        <Symptom>[Symptom.headache],
        profile: profileWith(
          allergies: <AllergenType>[AllergenType.paracetamol],
        ),
      );

      expect(
        result.selfCare.any((String tip) => tip.contains('Paracetamol')),
        isFalse,
      );
      expect(result.cautions.first, contains('allergy'));
    });

    test('an NSAID allergy also rules out ibuprofen', () {
      final TriageResult result = assess(
        <Symptom>[Symptom.headache],
        profile: profileWith(
          allergies: <AllergenType>[
            AllergenType.nonSteroidalAntiInflammatories,
          ],
        ),
      );

      expect(
        result.selfCare.any((String tip) => tip.contains('Ibuprofen')),
        isFalse,
      );
    });

    test('advice comes with a warning while allergies are unanswered', () {
      final TriageResult result = assess(<Symptom>[
        Symptom.headache,
      ], profile: SafetyProfile.unknown);

      expect(
        result.cautions.any((String line) => line.contains('allergies')),
        isTrue,
      );
    });

    test('extra fluids are qualified for someone on a fluid limit', () {
      final TriageResult result = assess(
        <Symptom>[Symptom.diarrhoea],
        profile: profileWith(
          conditions: <MedicalConditionType>[MedicalConditionType.heartFailure],
        ),
      );

      expect(
        result.cautions.any((String line) => line.contains('fluid limit')),
        isTrue,
      );
    });
  });

  group('risk factors read from the profile', () {
    test('type 2 diabetes and warfarin are both recognised', () {
      final SafetyProfile profile = profileWith(
        conditions: <MedicalConditionType>[MedicalConditionType.type2Diabetes],
        medicines: <MedicationIngredient>[MedicationIngredient.warfarin],
      );

      expect(profile.has(HealthRiskFactor.diabetes), isTrue);
      expect(profile.has(HealthRiskFactor.bleedingRisk), isTrue);
    });

    test('age decides the older adult factor', () {
      final DateTime seventy = DateTime.now().subtract(
        const Duration(days: 365 * 70),
      );

      expect(
        profileWith(dateOfBirth: seventy).has(HealthRiskFactor.olderAdult),
        isTrue,
      );
      expect(profileWith().has(HealthRiskFactor.olderAdult), isFalse);
    });

    test('a life-threatening allergy is carried into triage', () {
      final SafetyProfile profile = SafetyProfile.from(
        profile: HealthProfile.empty,
        conditions: ConditionRecord.empty,
        allergies: const AllergyRecord(
          allergies: <UserAllergy>[
            UserAllergy(
              type: AllergenType.peanuts,
              severity: AllergySeverity.lifeThreatening,
            ),
          ],
        ),
        medications: MedicationRecord.empty,
      );

      expect(profile.has(HealthRiskFactor.anaphylaxisHistory), isTrue);
    });
  });
}
