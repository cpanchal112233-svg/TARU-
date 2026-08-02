import '../../health_profile/domain/medication.dart';

/// What a medicine belongs to pharmacologically.
///
/// Interactions are written between groups rather than between individual
/// medicines, because "a blood thinner and an anti-inflammatory" is one rule
/// while the ingredient pairs behind it are a dozen. A medicine belongs to as
/// many groups as apply: aspirin is both its own thing and an antiplatelet.
///
/// A few groups hold a single ingredient. That is deliberate — clopidogrel and
/// omeprazole interact specifically with each other, and pantoprazole does
/// not, so the rule has to be able to name them.
enum MedicineGroup {
  nsaid('anti-inflammatory painkillers'),
  aspirin('aspirin'),
  paracetamol('paracetamol'),
  antiplatelet('blood-thinning antiplatelets'),
  anticoagulant('anticoagulants'),
  clopidogrel('clopidogrel'),
  bloodThinning('medicines that thin the blood or irritate the stomach'),
  opioid('opioid painkillers'),
  benzodiazepine('benzodiazepines'),
  ssri('SSRI antidepressants'),
  tricyclic('tricyclic antidepressants'),
  serotonergic('medicines that raise serotonin'),
  qtProlonging('medicines that affect heart rhythm'),
  aceInhibitorOrArb('blood pressure medicines (ACE inhibitors and ARBs)'),
  betaBlocker('beta blockers'),
  loopDiuretic('water tablets'),
  statin('statins'),
  protonPumpInhibitor('acid-reducing medicines'),
  acidReducer('acid-reducing medicines'),
  omeprazole('omeprazole'),
  metformin('metformin'),
  hypoglycaemiaRisk('diabetes medicines that can drop your sugar too low'),
  glucoseLowering('diabetes medicines'),
  corticosteroid('steroid tablets'),
  levothyroxine('thyroid replacement'),
  mineralSupplement('iron and calcium supplements'),
  tetracycline('tetracycline antibiotics'),
  chelatedAntibiotic('antibiotics that bind to minerals'),
  quinolone('quinolone antibiotics'),
  macrolide('macrolide antibiotics'),
  sulfonamide('sulfa antibiotics'),
  nitroimidazole('metronidazole');

  const MedicineGroup(this.label);

  final String label;
}

const Map<MedicineGroup, Set<MedicationIngredient>>
_members = <MedicineGroup, Set<MedicationIngredient>>{
  MedicineGroup.nsaid: <MedicationIngredient>{
    MedicationIngredient.ibuprofen,
    MedicationIngredient.diclofenac,
    MedicationIngredient.naproxen,
  },
  MedicineGroup.aspirin: <MedicationIngredient>{MedicationIngredient.aspirin},
  MedicineGroup.paracetamol: <MedicationIngredient>{
    MedicationIngredient.paracetamol,
  },
  MedicineGroup.antiplatelet: <MedicationIngredient>{
    MedicationIngredient.aspirin,
    MedicationIngredient.clopidogrel,
  },
  MedicineGroup.clopidogrel: <MedicationIngredient>{
    MedicationIngredient.clopidogrel,
  },
  MedicineGroup.anticoagulant: <MedicationIngredient>{
    MedicationIngredient.warfarin,
  },
  // Anything that makes a bleed more likely, whether by thinning the blood
  // or by stripping the stomach lining.
  MedicineGroup.bloodThinning: <MedicationIngredient>{
    MedicationIngredient.warfarin,
    MedicationIngredient.aspirin,
    MedicationIngredient.clopidogrel,
    MedicationIngredient.ibuprofen,
    MedicationIngredient.diclofenac,
    MedicationIngredient.naproxen,
  },
  MedicineGroup.opioid: <MedicationIngredient>{
    MedicationIngredient.tramadol,
    MedicationIngredient.codeine,
  },
  MedicineGroup.benzodiazepine: <MedicationIngredient>{
    MedicationIngredient.alprazolam,
  },
  MedicineGroup.ssri: <MedicationIngredient>{
    MedicationIngredient.sertraline,
    MedicationIngredient.escitalopram,
  },
  MedicineGroup.tricyclic: <MedicationIngredient>{
    MedicationIngredient.amitriptyline,
  },
  MedicineGroup.serotonergic: <MedicationIngredient>{
    MedicationIngredient.sertraline,
    MedicationIngredient.escitalopram,
    MedicationIngredient.amitriptyline,
    MedicationIngredient.tramadol,
  },
  MedicineGroup.qtProlonging: <MedicationIngredient>{
    MedicationIngredient.azithromycin,
    MedicationIngredient.ciprofloxacin,
    MedicationIngredient.levofloxacin,
    MedicationIngredient.ondansetron,
    MedicationIngredient.amitriptyline,
    MedicationIngredient.escitalopram,
  },
  MedicineGroup.aceInhibitorOrArb: <MedicationIngredient>{
    MedicationIngredient.ramipril,
    MedicationIngredient.telmisartan,
    MedicationIngredient.losartan,
  },
  MedicineGroup.betaBlocker: <MedicationIngredient>{
    MedicationIngredient.metoprolol,
    MedicationIngredient.atenolol,
  },
  MedicineGroup.loopDiuretic: <MedicationIngredient>{
    MedicationIngredient.furosemide,
  },
  MedicineGroup.statin: <MedicationIngredient>{
    MedicationIngredient.atorvastatin,
    MedicationIngredient.rosuvastatin,
  },
  MedicineGroup.protonPumpInhibitor: <MedicationIngredient>{
    MedicationIngredient.omeprazole,
    MedicationIngredient.pantoprazole,
  },
  MedicineGroup.acidReducer: <MedicationIngredient>{
    MedicationIngredient.omeprazole,
    MedicationIngredient.pantoprazole,
    MedicationIngredient.ranitidine,
  },
  MedicineGroup.omeprazole: <MedicationIngredient>{
    MedicationIngredient.omeprazole,
  },
  MedicineGroup.metformin: <MedicationIngredient>{
    MedicationIngredient.metformin,
  },
  // Metformin and sitagliptin rarely cause a hypo on their own; these two
  // do, which changes what a warning should say.
  MedicineGroup.hypoglycaemiaRisk: <MedicationIngredient>{
    MedicationIngredient.glimepiride,
    MedicationIngredient.insulin,
  },
  MedicineGroup.glucoseLowering: <MedicationIngredient>{
    MedicationIngredient.metformin,
    MedicationIngredient.glimepiride,
    MedicationIngredient.insulin,
    MedicationIngredient.sitagliptin,
  },
  MedicineGroup.corticosteroid: <MedicationIngredient>{
    MedicationIngredient.prednisolone,
  },
  MedicineGroup.levothyroxine: <MedicationIngredient>{
    MedicationIngredient.levothyroxine,
  },
  MedicineGroup.mineralSupplement: <MedicationIngredient>{
    MedicationIngredient.iron,
    MedicationIngredient.calcium,
  },
  MedicineGroup.tetracycline: <MedicationIngredient>{
    MedicationIngredient.doxycycline,
  },
  MedicineGroup.chelatedAntibiotic: <MedicationIngredient>{
    MedicationIngredient.doxycycline,
    MedicationIngredient.ciprofloxacin,
    MedicationIngredient.levofloxacin,
  },
  MedicineGroup.quinolone: <MedicationIngredient>{
    MedicationIngredient.ciprofloxacin,
    MedicationIngredient.levofloxacin,
  },
  MedicineGroup.macrolide: <MedicationIngredient>{
    MedicationIngredient.azithromycin,
  },
  MedicineGroup.sulfonamide: <MedicationIngredient>{
    MedicationIngredient.cotrimoxazole,
  },
  MedicineGroup.nitroimidazole: <MedicationIngredient>{
    MedicationIngredient.metronidazole,
  },
};

Set<MedicineGroup> groupsOf(MedicationIngredient ingredient) {
  return <MedicineGroup>{
    for (final MapEntry<MedicineGroup, Set<MedicationIngredient>> entry
        in _members.entries)
      if (entry.value.contains(ingredient)) entry.key,
  };
}

bool belongsTo(MedicationIngredient ingredient, MedicineGroup group) =>
    _members[group]?.contains(ingredient) ?? false;
