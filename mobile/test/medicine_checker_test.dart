import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/health_profile/domain/medication.dart';
import 'package:mobile/features/interactions/domain/interaction_rules.dart';
import 'package:mobile/features/interactions/domain/medicine_checker.dart';
import 'package:mobile/features/interactions/domain/medicine_group.dart';
import 'package:mobile/features/interactions/domain/medicine_warning.dart';
import 'package:mobile/features/safety/domain/health_risk.dart';
import 'package:mobile/features/safety/domain/safety_profile.dart';

UserMedication med(MedicationIngredient ingredient) =>
    UserMedication(ingredient: ingredient);

SafetyProfile profileWith([Set<HealthRiskFactor> factors = const {}]) =>
    SafetyProfile(riskFactors: factors);

List<MedicineWarning> checkOf(
  List<MedicationIngredient> ingredients, {
  Set<HealthRiskFactor> factors = const <HealthRiskFactor>{},
}) {
  return MedicineChecker.check(
    medicines: ingredients.map(med).toList(),
    profile: profileWith(factors),
  );
}

Set<String> codesOf(List<MedicineWarning> warnings) =>
    warnings.map((MedicineWarning w) => w.code).toSet();

void main() {
  group('rule table', () {
    test('every rule code is unique', () {
      final List<String> codes = <String>[
        ...interactionRules.map((InteractionRule r) => r.code),
        ...conditionCautions.map((ConditionCaution c) => c.code),
      ];

      expect(codes.toSet().length, codes.length);
    });

    test('every rule names at least one group and one action', () {
      for (final InteractionRule rule in interactionRules) {
        expect(rule.groups, isNotEmpty, reason: rule.code);
        expect(rule.requiredCount, greaterThanOrEqualTo(2), reason: rule.code);
        expect(rule.action.trim(), isNotEmpty, reason: rule.code);
        expect(rule.detail.trim(), isNotEmpty, reason: rule.code);
      }

      for (final ConditionCaution caution in conditionCautions) {
        expect(caution.action.trim(), isNotEmpty, reason: caution.code);
        expect(caution.detail.trim(), isNotEmpty, reason: caution.code);
      }
    });

    test('every group has at least one ingredient in it', () {
      for (final MedicineGroup group in MedicineGroup.values) {
        final bool used = MedicationIngredient.values.any(
          (MedicationIngredient i) => belongsTo(i, group),
        );

        expect(used, isTrue, reason: 'no ingredient maps to ${group.name}');
      }
    });

    test('every group is used by a rule or a caution', () {
      final Set<MedicineGroup> used = <MedicineGroup>{
        for (final InteractionRule rule in interactionRules) ...rule.groups,
        for (final ConditionCaution caution in conditionCautions) caution.group,
      };

      expect(used, containsAll(MedicineGroup.values));
    });

    test('superseded codes refer to real rules', () {
      final Set<String> codes = interactionRules
          .map((InteractionRule r) => r.code)
          .toSet();

      for (final InteractionRule rule in interactionRules) {
        expect(codes, containsAll(rule.supersedes), reason: rule.code);
      }
    });
  });

  group('no false alarms', () {
    test('an empty list produces nothing', () {
      expect(checkOf(const <MedicationIngredient>[]), isEmpty);
    });

    test('a single medicine cannot interact with itself', () {
      expect(checkOf([MedicationIngredient.warfarin]), isEmpty);
    });

    test('one medicine in two groups does not trigger a pair rule', () {
      // Aspirin is both an antiplatelet and blood-thinning; alone it must not
      // fire "two blood thinners".
      expect(checkOf([MedicationIngredient.aspirin]), isEmpty);
    });

    test('unrelated medicines stay quiet', () {
      expect(
        checkOf([
          MedicationIngredient.vitaminD,
          MedicationIngredient.cetirizine,
          MedicationIngredient.montelukast,
        ]),
        isEmpty,
      );
    });
  });

  group('bleeding risk', () {
    test('warfarin with ibuprofen is serious', () {
      final List<MedicineWarning> warnings = checkOf([
        MedicationIngredient.warfarin,
        MedicationIngredient.ibuprofen,
      ]);

      expect(codesOf(warnings), contains('anticoagulant+nsaid'));
      expect(warnings.highestSeverity, MedicineWarningSeverity.serious);
    });

    test('apixaban with ibuprofen is also serious bleeding risk', () {
      expect(
        codesOf(
          checkOf([
            MedicationIngredient.apixaban,
            MedicationIngredient.ibuprofen,
          ]),
        ),
        contains('anticoagulant+nsaid'),
      );
    });

    test('INR antibiotic rules stay warfarin-only, not DOACs', () {
      expect(
        codesOf(
          checkOf([
            MedicationIngredient.apixaban,
            MedicationIngredient.cotrimoxazole,
          ]),
        ),
        isNot(contains('warfarin+sulfonamide')),
      );

      expect(
        codesOf(
          checkOf([
            MedicationIngredient.warfarin,
            MedicationIngredient.cotrimoxazole,
          ]),
        ),
        contains('warfarin+sulfonamide'),
      );
    });

    test('warfarin with clopidogrel flags two blood thinners', () {
      expect(
        codesOf(
          checkOf([
            MedicationIngredient.warfarin,
            MedicationIngredient.clopidogrel,
          ]),
        ),
        contains('anticoagulant+antiplatelet'),
      );
    });

    test('no warning tells anyone to stop a prescribed blood thinner', () {
      final List<MedicineWarning> warnings = checkOf([
        MedicationIngredient.warfarin,
        MedicationIngredient.clopidogrel,
        MedicationIngredient.aspirin,
      ]);

      expect(warnings, isNotEmpty);

      for (final MedicineWarning warning in warnings) {
        expect(
          warning.action.toLowerCase(),
          isNot(matches(RegExp(r'^stop '))),
          reason: warning.code,
        );
      }
    });

    test('sertraline with aspirin is a caution, not silence', () {
      expect(
        codesOf(
          checkOf([
            MedicationIngredient.sertraline,
            MedicationIngredient.aspirin,
          ]),
        ),
        contains('ssri+bloodthinning'),
      );
    });
  });

  group('duplication', () {
    test('two entries of paracetamol are flagged as serious', () {
      final List<MedicineWarning> warnings = MedicineChecker.check(
        medicines: <UserMedication>[
          const UserMedication(
            ingredient: MedicationIngredient.paracetamol,
            brandName: 'Dolo 650',
          ),
          const UserMedication(
            ingredient: MedicationIngredient.paracetamol,
            brandName: 'Crocin',
          ),
        ],
        profile: profileWith(),
      );

      final MedicineWarning warning = warnings.singleWhere(
        (MedicineWarning w) => w.code == 'paracetamol+paracetamol',
      );

      expect(warning.severity, MedicineWarningSeverity.serious);
      expect(warning.medicines, hasLength(2));
    });

    test('one paracetamol entry is fine', () {
      expect(checkOf([MedicationIngredient.paracetamol]), isEmpty);
    });

    test('ibuprofen with naproxen is flagged as doubling up', () {
      expect(
        codesOf(
          checkOf([
            MedicationIngredient.ibuprofen,
            MedicationIngredient.naproxen,
          ]),
        ),
        contains('nsaid+nsaid'),
      );
    });

    test('ramipril with telmisartan is dual blockade', () {
      expect(
        codesOf(
          checkOf([
            MedicationIngredient.ramipril,
            MedicationIngredient.telmisartan,
          ]),
        ),
        contains('ace+ace'),
      );
    });
  });

  group('kidneys', () {
    test('the triple whammy fires and hides the weaker pair rules', () {
      final Set<String> codes = codesOf(
        checkOf([
          MedicationIngredient.ramipril,
          MedicationIngredient.furosemide,
          MedicationIngredient.ibuprofen,
        ]),
      );

      expect(codes, contains('triple-whammy'));
      expect(codes, isNot(contains('nsaid+ace')));
      expect(codes, isNot(contains('nsaid+diuretic')));
    });

    test('a thiazide also completes the triple whammy', () {
      expect(
        codesOf(
          checkOf([
            MedicationIngredient.telmisartan,
            MedicationIngredient.hydrochlorothiazide,
            MedicationIngredient.naproxen,
          ]),
        ),
        contains('triple-whammy'),
      );
    });

    test('the triple whammy names all three medicines', () {
      final MedicineWarning warning = checkOf([
        MedicationIngredient.ramipril,
        MedicationIngredient.furosemide,
        MedicationIngredient.ibuprofen,
      ]).singleWhere((MedicineWarning w) => w.code == 'triple-whammy');

      expect(warning.medicineNames, 'Ramipril + Furosemide + Ibuprofen');
    });

    test('two of the three is still worth a caution', () {
      final Set<String> codes = codesOf(
        checkOf([
          MedicationIngredient.ramipril,
          MedicationIngredient.ibuprofen,
        ]),
      );

      expect(codes, contains('nsaid+ace'));
      expect(codes, isNot(contains('triple-whammy')));
    });

    test('ibuprofen in kidney disease is serious', () {
      final List<MedicineWarning> warnings = checkOf(
        [MedicationIngredient.ibuprofen],
        factors: {HealthRiskFactor.kidneyDisease},
      );

      final MedicineWarning warning = warnings.single;

      expect(warning.code, 'nsaid/kidney');
      expect(warning.severity, MedicineWarningSeverity.serious);
      expect(warning.detail.toLowerCase(), contains('kidney'));
    });

    test('metformin in kidney disease asks for a dose review', () {
      final MedicineWarning warning = checkOf(
        [MedicationIngredient.metformin],
        factors: {HealthRiskFactor.kidneyDisease},
      ).single;

      expect(warning.code, 'metformin/kidney');
      expect(warning.action.toLowerCase(), contains('egfr'));
    });

    test('metformin without kidney disease says nothing', () {
      expect(checkOf([MedicationIngredient.metformin]), isEmpty);
    });
  });

  group('pregnancy', () {
    test('ramipril in pregnancy is serious and does not say just stop', () {
      final MedicineWarning warning = checkOf(
        [MedicationIngredient.ramipril],
        factors: {HealthRiskFactor.pregnant},
      ).single;

      expect(warning.code, 'ace/pregnant');
      expect(warning.severity, MedicineWarningSeverity.serious);
      expect(warning.action.toLowerCase(), contains('do not just stop'));
    });

    test('ibuprofen and a statin in pregnancy both flag', () {
      final Set<String> codes = codesOf(
        checkOf(
          [MedicationIngredient.ibuprofen, MedicationIngredient.atorvastatin],
          factors: {HealthRiskFactor.pregnant},
        ),
      );

      expect(codes, containsAll(<String>['nsaid/pregnant', 'statin/pregnant']));
    });

    test('codeine while breastfeeding is serious', () {
      final MedicineWarning warning = checkOf(
        [MedicationIngredient.codeine],
        factors: {HealthRiskFactor.breastfeeding},
      ).single;

      expect(warning.code, 'opioid/breastfeeding');
      expect(warning.severity, MedicineWarningSeverity.serious);
    });
  });

  group('other safety rules', () {
    test('tramadol with alprazolam warns about breathing', () {
      final Set<String> codes = codesOf(
        checkOf([
          MedicationIngredient.tramadol,
          MedicationIngredient.alprazolam,
        ]),
      );

      expect(codes, contains('opioid+benzodiazepine'));
    });

    test('sertraline with tramadol warns about serotonin', () {
      expect(
        codesOf(
          checkOf([
            MedicationIngredient.sertraline,
            MedicationIngredient.tramadol,
          ]),
        ),
        contains('serotonergic+serotonergic'),
      );
    });

    test('clopidogrel with omeprazole suggests pantoprazole', () {
      final MedicineWarning warning = checkOf([
        MedicationIngredient.clopidogrel,
        MedicationIngredient.omeprazole,
      ]).single;

      expect(warning.code, 'clopidogrel+omeprazole');
      expect(warning.action.toLowerCase(), contains('pantoprazole'));
    });

    test('clopidogrel with pantoprazole is fine', () {
      expect(
        checkOf([
          MedicationIngredient.clopidogrel,
          MedicationIngredient.pantoprazole,
        ]),
        isEmpty,
      );
    });

    test('levothyroxine with calcium is a timing warning', () {
      final MedicineWarning warning = checkOf([
        MedicationIngredient.levothyroxine,
        MedicationIngredient.calcium,
      ]).single;

      expect(warning.code, 'levothyroxine+minerals');
      expect(warning.severity, MedicineWarningSeverity.timing);
    });

    test('metoprolol with insulin warns about hidden hypos', () {
      expect(
        codesOf(
          checkOf([
            MedicationIngredient.metoprolol,
            MedicationIngredient.insulin,
          ]),
        ),
        contains('betablocker+hypo'),
      );
    });

    test(
      'metoprolol with metformin does not, since metformin rarely hypos',
      () {
        expect(
          codesOf(
            checkOf([
              MedicationIngredient.metoprolol,
              MedicationIngredient.metformin,
            ]),
          ),
          isNot(contains('betablocker+hypo')),
        );
      },
    );
  });

  group('ordering and grouping', () {
    test('serious warnings come before cautions and timing', () {
      final List<MedicineWarning> warnings = checkOf([
        MedicationIngredient.warfarin,
        MedicationIngredient.ibuprofen,
        MedicationIngredient.levothyroxine,
        MedicationIngredient.iron,
      ]);

      final List<int> order = warnings
          .map((MedicineWarning w) => w.severity.order)
          .toList();

      expect(order, orderedEquals(order.toList()..sort((a, b) => b - a)));
      expect(warnings.first.severity, MedicineWarningSeverity.serious);
      expect(warnings.last.severity, MedicineWarningSeverity.timing);
    });

    test('warnings can be filtered down to one medicine', () {
      final UserMedication warfarin = med(MedicationIngredient.warfarin);
      final UserMedication levothyroxine = med(
        MedicationIngredient.levothyroxine,
      );

      final List<MedicineWarning> warnings = MedicineChecker.check(
        medicines: <UserMedication>[
          warfarin,
          med(MedicationIngredient.ibuprofen),
          levothyroxine,
          med(MedicationIngredient.iron),
        ],
        profile: profileWith(),
      );

      expect(codesOf(warnings.forMedicine(warfarin)), <String>{
        'anticoagulant+nsaid',
      });
      expect(codesOf(warnings.forMedicine(levothyroxine)), <String>{
        'levothyroxine+minerals',
      });
    });

    test('a full cabinet stays under a readable number of warnings', () {
      final List<MedicineWarning> warnings = checkOf(
        [
          MedicationIngredient.metformin,
          MedicationIngredient.ramipril,
          MedicationIngredient.atorvastatin,
          MedicationIngredient.aspirin,
          MedicationIngredient.metoprolol,
          MedicationIngredient.pantoprazole,
          MedicationIngredient.vitaminD,
        ],
        factors: {HealthRiskFactor.diabetes, HealthRiskFactor.olderAdult},
      );

      expect(warnings.length, lessThanOrEqualTo(3));
    });
  });
}
