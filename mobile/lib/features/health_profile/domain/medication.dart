import 'package:flutter/foundation.dart';

import 'allergy.dart';

enum MedicationForm {
  tablet('Tablet'),
  capsule('Capsule'),
  syrup('Syrup or liquid'),
  injection('Injection'),
  inhaler('Inhaler'),
  drops('Drops'),
  cream('Cream or ointment'),
  patch('Patch'),
  other('Other');

  const MedicationForm(this.label);

  final String label;
}

enum DoseUnit {
  mg('mg'),
  mcg('mcg'),
  gram('g'),
  ml('ml'),
  tablet('tablet(s)'),
  puff('puff(s)'),
  drop('drop(s)'),
  unit('unit(s)');

  const DoseUnit(this.label);

  final String label;
}

/// How often a medicine is taken.
///
/// [timesPerDay] is what reminders and adherence tracking will count, and is
/// null where the schedule is not daily.
enum MedicationFrequency {
  onceDaily('Once a day', timesPerDay: 1),
  twiceDaily('Twice a day', timesPerDay: 2),
  threeTimesDaily('Three times a day', timesPerDay: 3),
  fourTimesDaily('Four times a day', timesPerDay: 4),
  everyOtherDay('Every other day'),
  weekly('Once a week'),
  monthly('Once a month'),
  asNeeded('Only when needed');

  const MedicationFrequency(this.label, {this.timesPerDay});

  final String label;
  final int? timesPerDay;

  bool get isDaily => timesPerDay != null;
}

enum DoseTime {
  morning('Morning'),
  afternoon('Afternoon'),
  evening('Evening'),
  bedtime('Bedtime');

  const DoseTime(this.label);

  final String label;
}

/// Whether the medicine should be taken with food, which changes both how well
/// it works and how likely it is to upset the stomach.
enum FoodTiming {
  noPreference('Any time'),
  beforeFood('Before food'),
  withFood('With food'),
  afterFood('After food'),
  emptyStomach('On an empty stomach');

  const FoodTiming(this.label);

  final String label;
}

/// Common generic ingredients, kept as stable codes.
///
/// People say the brand name ("Dolo", "Crocin") but safety checks need the
/// ingredient, so brands are search terms pointing at the generic. Anything not
/// on this list is still allowed as free text: an unrecognised medicine is far
/// better than an unrecorded one.
///
/// [relatedAllergen] is what makes it possible to warn someone that the pill
/// they just added is the same family as an allergy they already reported.
enum MedicationIngredient {
  paracetamol(
    'Paracetamol',
    searchTerms: ['paracetamol', 'acetaminophen', 'crocin', 'dolo', 'calpol'],
    relatedAllergen: AllergenType.paracetamol,
  ),
  ibuprofen(
    'Ibuprofen',
    searchTerms: ['ibuprofen', 'brufen', 'combiflam', 'advil'],
    relatedAllergen: AllergenType.nonSteroidalAntiInflammatories,
  ),
  diclofenac(
    'Diclofenac',
    searchTerms: ['diclofenac', 'voveran', 'volini'],
    relatedAllergen: AllergenType.nonSteroidalAntiInflammatories,
  ),
  naproxen(
    'Naproxen',
    searchTerms: ['naproxen', 'naprosyn'],
    relatedAllergen: AllergenType.nonSteroidalAntiInflammatories,
  ),
  aspirin(
    'Aspirin',
    searchTerms: ['aspirin', 'ecosprin', 'disprin'],
    relatedAllergen: AllergenType.aspirin,
  ),
  tramadol(
    'Tramadol',
    searchTerms: ['tramadol', 'ultracet'],
    relatedAllergen: AllergenType.opioids,
  ),
  codeine(
    'Codeine',
    searchTerms: ['codeine'],
    relatedAllergen: AllergenType.opioids,
  ),

  amoxicillin(
    'Amoxicillin',
    searchTerms: ['amoxicillin', 'amoxil', 'augmentin', 'mox', 'clavulanate'],
    relatedAllergen: AllergenType.penicillin,
  ),
  azithromycin(
    'Azithromycin',
    searchTerms: ['azithromycin', 'azithral', 'zithromax'],
    relatedAllergen: AllergenType.macrolides,
  ),
  ciprofloxacin(
    'Ciprofloxacin',
    searchTerms: ['ciprofloxacin', 'cifran', 'ciplox'],
    relatedAllergen: AllergenType.fluoroquinolones,
  ),
  levofloxacin(
    'Levofloxacin',
    searchTerms: ['levofloxacin', 'levoflox'],
    relatedAllergen: AllergenType.fluoroquinolones,
  ),
  doxycycline(
    'Doxycycline',
    searchTerms: ['doxycycline', 'doxy'],
    relatedAllergen: AllergenType.tetracyclines,
  ),
  cefixime(
    'Cefixime',
    searchTerms: ['cefixime', 'taxim', 'zifi', 'cephalosporin'],
    relatedAllergen: AllergenType.cephalosporins,
  ),
  cotrimoxazole(
    'Co-trimoxazole',
    searchTerms: ['cotrimoxazole', 'bactrim', 'septran', 'sulfamethoxazole'],
    relatedAllergen: AllergenType.sulfonamides,
  ),
  metronidazole(
    'Metronidazole',
    searchTerms: ['metronidazole', 'flagyl', 'metrogyl'],
  ),

  metformin(
    'Metformin',
    searchTerms: ['metformin', 'glycomet', 'glucophage', 'sugar tablet'],
  ),
  glimepiride('Glimepiride', searchTerms: ['glimepiride', 'amaryl']),
  insulin(
    'Insulin',
    searchTerms: ['insulin', 'lantus', 'humalog', 'mixtard'],
    relatedAllergen: AllergenType.insulin,
  ),
  sitagliptin('Sitagliptin', searchTerms: ['sitagliptin', 'januvia']),

  amlodipine('Amlodipine', searchTerms: ['amlodipine', 'amlokind', 'norvasc']),
  telmisartan('Telmisartan', searchTerms: ['telmisartan', 'telma']),
  losartan('Losartan', searchTerms: ['losartan', 'losar']),
  ramipril('Ramipril', searchTerms: ['ramipril', 'cardace']),
  metoprolol('Metoprolol', searchTerms: ['metoprolol', 'metolar']),
  atenolol('Atenolol', searchTerms: ['atenolol', 'aten']),
  carvedilol('Carvedilol', searchTerms: ['carvedilol', 'cardivas']),
  furosemide('Furosemide', searchTerms: ['furosemide', 'lasix', 'frusemide']),
  atorvastatin(
    'Atorvastatin',
    searchTerms: ['atorvastatin', 'atorva', 'lipitor', 'cholesterol'],
    relatedAllergen: AllergenType.statins,
  ),
  rosuvastatin(
    'Rosuvastatin',
    searchTerms: ['rosuvastatin', 'rosuvas', 'crestor'],
    relatedAllergen: AllergenType.statins,
  ),
  clopidogrel(
    'Clopidogrel',
    searchTerms: ['clopidogrel', 'plavix', 'clopilet'],
  ),
  warfarin('Warfarin', searchTerms: ['warfarin', 'blood thinner']),
  apixaban('Apixaban', searchTerms: ['apixaban', 'eliquis', 'blood thinner']),
  rivaroxaban(
    'Rivaroxaban',
    searchTerms: ['rivaroxaban', 'xarelto', 'blood thinner'],
  ),
  dabigatran(
    'Dabigatran',
    searchTerms: ['dabigatran', 'pradaxa', 'blood thinner'],
  ),
  hydrochlorothiazide(
    'Hydrochlorothiazide',
    searchTerms: ['hydrochlorothiazide', 'hctz', 'water tablet'],
  ),
  spironolactone(
    'Spironolactone',
    searchTerms: ['spironolactone', 'aldactone'],
  ),

  omeprazole('Omeprazole', searchTerms: ['omeprazole', 'omez']),
  pantoprazole('Pantoprazole', searchTerms: ['pantoprazole', 'pan', 'pantop']),
  ranitidine('Ranitidine', searchTerms: ['ranitidine', 'zinetac']),
  ondansetron(
    'Ondansetron',
    searchTerms: ['ondansetron', 'emeset', 'vomiting'],
  ),

  levothyroxine(
    'Levothyroxine',
    searchTerms: ['levothyroxine', 'thyronorm', 'eltroxin', 'thyroid'],
  ),

  salbutamol(
    'Salbutamol',
    searchTerms: ['salbutamol', 'asthalin', 'albuterol', 'inhaler'],
  ),
  budesonide('Budesonide', searchTerms: ['budesonide', 'budecort']),
  montelukast('Montelukast', searchTerms: ['montelukast', 'montair']),
  cetirizine('Cetirizine', searchTerms: ['cetirizine', 'cetzine', 'alerid']),
  prednisolone(
    'Prednisolone',
    searchTerms: ['prednisolone', 'wysolone', 'steroid'],
  ),

  sertraline('Sertraline', searchTerms: ['sertraline', 'zoloft', 'serta']),
  escitalopram('Escitalopram', searchTerms: ['escitalopram', 'nexito']),
  alprazolam('Alprazolam', searchTerms: ['alprazolam', 'alprax', 'xanax']),
  amitriptyline('Amitriptyline', searchTerms: ['amitriptyline', 'tryptomer']),

  vitaminD(
    'Vitamin D',
    searchTerms: ['vitamin d', 'cholecalciferol', 'calcirol'],
  ),
  vitaminB12(
    'Vitamin B12',
    searchTerms: ['b12', 'cobalamin', 'methylcobalamin'],
  ),
  iron('Iron', searchTerms: ['iron', 'ferrous', 'orofer', 'haemoglobin']),
  calcium('Calcium', searchTerms: ['calcium', 'shelcal']),
  folicAcid('Folic acid', searchTerms: ['folic', 'folvite']),

  other('Other medicine', isCustom: true);

  const MedicationIngredient(
    this.label, {
    this.isCustom = false,
    this.searchTerms = const <String>[],
    this.relatedAllergen,
  });

  final String label;

  /// Placeholder for a medicine TARU does not recognise; the real name lives in
  /// [UserMedication.customName].
  final bool isCustom;

  final List<String> searchTerms;

  /// The allergy family this medicine belongs to, where there is one.
  final AllergenType? relatedAllergen;

  bool matches(String query) {
    final String needle = query.trim().toLowerCase();

    if (needle.isEmpty) return true;
    if (label.toLowerCase().contains(needle)) return true;

    return searchTerms.any((String term) => term.contains(needle));
  }
}

@immutable
class UserMedication {
  const UserMedication({
    required this.ingredient,
    this.customName,
    this.brandName,
    this.form,
    this.doseAmount,
    this.doseUnit,
    this.frequency,
    this.doseTimes = const <DoseTime>{},
    this.foodTiming,
    this.reason,
    this.startedOn,
  });

  final MedicationIngredient ingredient;

  /// Only meaningful when [MedicationIngredient.isCustom] is true.
  final String? customName;

  /// What it says on the strip, kept alongside the generic so the entry still
  /// looks familiar to the person who takes it.
  final String? brandName;

  final MedicationForm? form;
  final double? doseAmount;
  final DoseUnit? doseUnit;
  final MedicationFrequency? frequency;
  final Set<DoseTime> doseTimes;
  final FoodTiming? foodTiming;

  /// Why it was prescribed, in the user's own words.
  final String? reason;

  final DateTime? startedOn;

  String get displayName {
    if (!ingredient.isCustom) return ingredient.label;

    final String? name = customName?.trim();

    return (name == null || name.isEmpty) ? ingredient.label : name;
  }

  String? get doseSummary {
    final double? amount = doseAmount;
    final DoseUnit? unit = doseUnit;

    if (amount == null || unit == null) return null;

    final String rendered = amount == amount.roundToDouble()
        ? amount.toStringAsFixed(0)
        : amount.toString();

    return '$rendered ${unit.label}';
  }

  /// One line for list subtitles: "500 mg  •  Twice a day  •  After food".
  String? get scheduleSummary {
    final List<String> parts = [
      ?doseSummary,
      if (frequency != null) frequency!.label,
      if (foodTiming != null && foodTiming != FoodTiming.noPreference)
        foodTiming!.label,
    ];

    return parts.isEmpty ? null : parts.join('  •  ');
  }

  UserMedication copyWith({
    String? customName,
    String? brandName,
    MedicationForm? form,
    double? doseAmount,
    DoseUnit? doseUnit,
    MedicationFrequency? frequency,
    Set<DoseTime>? doseTimes,
    FoodTiming? foodTiming,
    String? reason,
    DateTime? startedOn,
  }) {
    return UserMedication(
      ingredient: ingredient,
      customName: customName ?? this.customName,
      brandName: brandName ?? this.brandName,
      form: form ?? this.form,
      doseAmount: doseAmount ?? this.doseAmount,
      doseUnit: doseUnit ?? this.doseUnit,
      frequency: frequency ?? this.frequency,
      doseTimes: doseTimes ?? this.doseTimes,
      foodTiming: foodTiming ?? this.foodTiming,
      reason: reason ?? this.reason,
      startedOn: startedOn ?? this.startedOn,
    );
  }

  @override
  bool operator ==(Object other) {
    if (other is! UserMedication) return false;

    return ingredient == other.ingredient &&
        customName?.trim() == other.customName?.trim() &&
        brandName?.trim() == other.brandName?.trim() &&
        form == other.form &&
        doseAmount == other.doseAmount &&
        doseUnit == other.doseUnit &&
        frequency == other.frequency &&
        foodTiming == other.foodTiming &&
        reason?.trim() == other.reason?.trim() &&
        startedOn == other.startedOn &&
        setEquals(doseTimes, other.doseTimes);
  }

  @override
  int get hashCode => Object.hash(
    ingredient,
    customName?.trim(),
    brandName?.trim(),
    form,
    doseAmount,
    doseUnit,
    frequency,
    foodTiming,
    reason?.trim(),
    startedOn,
    Object.hashAllUnordered(doseTimes),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    'code': ingredient.name,
    'customName': ingredient.isCustom ? customName?.trim() : null,
    'brandName': brandName?.trim(),
    'form': form?.name,
    'doseAmount': doseAmount,
    'doseUnit': doseUnit?.name,
    'frequency': frequency?.name,
    'doseTimes': doseTimes.map((DoseTime time) => time.name).toList(),
    'foodTiming': foodTiming?.name,
    'reason': reason?.trim(),
    'startedOn': startedOn?.toIso8601String(),
  };

  static UserMedication? fromMap(Map<String, dynamic> map) {
    final MedicationIngredient? ingredient = _lookup(
      map['code'],
      MedicationIngredient.values,
    );

    if (ingredient == null) return null;

    final Object? rawTimes = map['doseTimes'];

    final Set<DoseTime> doseTimes = rawTimes is List
        ? rawTimes
              .map((Object? code) => _lookup(code, DoseTime.values))
              .whereType<DoseTime>()
              .toSet()
        : const <DoseTime>{};

    final Object? amount = map['doseAmount'];
    final Object? startedOn = map['startedOn'];

    return UserMedication(
      ingredient: ingredient,
      customName: _readString(map['customName']),
      brandName: _readString(map['brandName']),
      form: _lookup(map['form'], MedicationForm.values),
      doseAmount: amount is num ? amount.toDouble() : null,
      doseUnit: _lookup(map['doseUnit'], DoseUnit.values),
      frequency: _lookup(map['frequency'], MedicationFrequency.values),
      doseTimes: doseTimes,
      foodTiming: _lookup(map['foodTiming'], FoodTiming.values),
      reason: _readString(map['reason']),
      startedOn: startedOn is String ? DateTime.tryParse(startedOn) : null,
    );
  }

  static String? _readString(Object? value) => value is String ? value : null;

  static T? _lookup<T extends Enum>(Object? code, List<T> values) {
    if (code is! String) return null;

    for (final T candidate in values) {
      if (candidate.name == code) return candidate;
    }

    return null;
  }
}

/// The user's answer to "what are you taking?".
@immutable
class MedicationRecord {
  const MedicationRecord({
    this.medications = const <UserMedication>[],
    this.takesNoMedication = false,
  });

  static const MedicationRecord empty = MedicationRecord();

  final List<UserMedication> medications;
  final bool takesNoMedication;

  bool get hasAnswered => takesNoMedication || medications.isNotEmpty;

  /// Medicines that belong to an allergy family the user already reported.
  ///
  /// This is the check that catches someone adding amoxicillin while carrying a
  /// recorded penicillin allergy, which is the exact mistake that puts people
  /// in hospital.
  List<({UserMedication medication, UserAllergy allergy})> conflictsWith(
    AllergyRecord allergies,
  ) {
    final List<({UserMedication medication, UserAllergy allergy})> conflicts =
        [];

    for (final UserMedication medication in medications) {
      final AllergenType? allergen = medication.ingredient.relatedAllergen;

      if (allergen == null) continue;

      for (final UserAllergy allergy in allergies.allergies) {
        if (allergy.type == allergen) {
          conflicts.add((medication: medication, allergy: allergy));
        }
      }
    }

    return conflicts;
  }

  factory MedicationRecord.fromMap(Map<String, dynamic> map) {
    final Object? items = map['items'];

    return MedicationRecord(
      medications: items is List
          ? items
                .whereType<Map<String, dynamic>>()
                .map(UserMedication.fromMap)
                .whereType<UserMedication>()
                .toList()
          : const <UserMedication>[],
      takesNoMedication: map['takesNoMedication'] == true,
    );
  }
}
