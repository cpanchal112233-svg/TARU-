import 'package:flutter/foundation.dart';

enum AllergyCategory {
  medicine('Medicines'),
  food('Food'),
  environmental('Environmental');

  const AllergyCategory(this.label);

  final String label;
}

/// What actually happens on exposure. This matters as much as the allergen:
/// a mild rash and anaphylaxis are both allergies, but only one is an emergency.
enum AllergyReaction {
  rash('Rash or hives'),
  itching('Itching'),
  swelling('Swelling of face, lips or tongue'),
  breathingDifficulty('Difficulty breathing or wheezing'),
  stomachUpset('Nausea, vomiting or diarrhoea'),
  dizziness('Dizziness or fainting'),
  anaphylaxis('Anaphylaxis — needed emergency treatment');

  const AllergyReaction(this.label);

  final String label;

  bool get isEmergency => this == AllergyReaction.anaphylaxis;
}

enum AllergySeverity {
  mild('Mild'),
  moderate('Moderate'),
  severe('Severe'),
  lifeThreatening('Life-threatening');

  const AllergySeverity(this.label);

  final String label;
}

/// Allergens TARU can recognise, stored as stable codes like conditions are.
///
/// Medicines come first because they are the most safety-critical: a stored
/// penicillin allergy is what lets later features refuse to suggest amoxicillin.
enum AllergenType {
  // Medicines
  penicillin(
    'Penicillin',
    AllergyCategory.medicine,
    searchTerms: ['penicillin', 'amoxicillin', 'augmentin', 'amoxil'],
  ),
  cephalosporins(
    'Cephalosporins',
    AllergyCategory.medicine,
    searchTerms: ['cephalosporin', 'cefixime', 'ceftriaxone', 'cephalexin'],
  ),
  sulfonamides(
    'Sulfa drugs',
    AllergyCategory.medicine,
    searchTerms: ['sulfa', 'sulpha', 'cotrimoxazole', 'bactrim', 'septran'],
  ),
  nonSteroidalAntiInflammatories(
    'NSAIDs (ibuprofen, diclofenac)',
    AllergyCategory.medicine,
    searchTerms: [
      'nsaid',
      'ibuprofen',
      'brufen',
      'diclofenac',
      'voveran',
      'naproxen',
      'painkiller',
    ],
  ),
  aspirin(
    'Aspirin',
    AllergyCategory.medicine,
    searchTerms: ['aspirin', 'disprin', 'ecosprin'],
  ),
  paracetamol(
    'Paracetamol / acetaminophen',
    AllergyCategory.medicine,
    searchTerms: ['paracetamol', 'acetaminophen', 'crocin', 'dolo', 'tylenol'],
  ),
  macrolides(
    'Erythromycin or azithromycin',
    AllergyCategory.medicine,
    searchTerms: ['azithromycin', 'erythromycin', 'azithral', 'macrolide'],
  ),
  fluoroquinolones(
    'Fluoroquinolones',
    AllergyCategory.medicine,
    searchTerms: ['ciprofloxacin', 'levofloxacin', 'norfloxacin', 'quinolone'],
  ),
  tetracyclines(
    'Tetracyclines',
    AllergyCategory.medicine,
    searchTerms: ['doxycycline', 'tetracycline', 'minocycline'],
  ),
  opioids(
    'Opioid painkillers',
    AllergyCategory.medicine,
    searchTerms: ['morphine', 'codeine', 'tramadol', 'opioid'],
  ),
  localAnaesthetics(
    'Local anaesthetics',
    AllergyCategory.medicine,
    searchTerms: ['lignocaine', 'lidocaine', 'dental injection', 'anaesthetic'],
  ),
  generalAnaesthetics(
    'General anaesthetics',
    AllergyCategory.medicine,
    searchTerms: ['anaesthesia', 'anesthesia', 'surgery'],
  ),
  iodinatedContrast(
    'X-ray or CT contrast dye',
    AllergyCategory.medicine,
    searchTerms: ['contrast', 'dye', 'iodine', 'ct scan'],
  ),
  anticonvulsants(
    'Anti-seizure medicines',
    AllergyCategory.medicine,
    searchTerms: ['phenytoin', 'carbamazepine', 'valproate', 'lamotrigine'],
  ),
  statins(
    'Statins',
    AllergyCategory.medicine,
    searchTerms: ['atorvastatin', 'simvastatin', 'rosuvastatin', 'statin'],
  ),
  insulin('Insulin', AllergyCategory.medicine, searchTerms: ['insulin']),
  vaccines(
    'Vaccines',
    AllergyCategory.medicine,
    searchTerms: ['vaccine', 'vaccination', 'jab'],
  ),
  otherMedicine('Other medicine', AllergyCategory.medicine, isCustom: true),

  // Food
  peanuts(
    'Peanuts',
    AllergyCategory.food,
    searchTerms: ['peanut', 'groundnut', 'moongphali'],
  ),
  treeNuts(
    'Tree nuts (almond, cashew, walnut)',
    AllergyCategory.food,
    searchTerms: ['nuts', 'almond', 'cashew', 'walnut', 'pistachio', 'badam'],
  ),
  milk(
    'Milk or dairy',
    AllergyCategory.food,
    searchTerms: ['milk', 'dairy', 'lactose', 'cheese', 'paneer'],
  ),
  eggs('Eggs', AllergyCategory.food, searchTerms: ['egg', 'anda']),
  wheat(
    'Wheat or gluten',
    AllergyCategory.food,
    searchTerms: ['wheat', 'gluten', 'atta', 'bread'],
  ),
  soy('Soy', AllergyCategory.food, searchTerms: ['soy', 'soya', 'tofu']),
  fish('Fish', AllergyCategory.food, searchTerms: ['fish', 'machli']),
  shellfish(
    'Shellfish (prawn, crab)',
    AllergyCategory.food,
    searchTerms: ['prawn', 'shrimp', 'crab', 'lobster', 'shellfish'],
  ),
  sesame(
    'Sesame',
    AllergyCategory.food,
    searchTerms: ['sesame', 'til', 'tahini'],
  ),
  mustard('Mustard', AllergyCategory.food, searchTerms: ['mustard', 'sarson']),
  sulphites(
    'Sulphites or preservatives',
    AllergyCategory.food,
    searchTerms: ['sulphite', 'sulfite', 'preservative', 'msg'],
  ),
  otherFood('Other food', AllergyCategory.food, isCustom: true),

  // Environmental
  pollen(
    'Pollen',
    AllergyCategory.environmental,
    searchTerms: ['pollen', 'hay fever', 'hayfever', 'grass', 'flowers'],
  ),
  dustMites(
    'Dust or dust mites',
    AllergyCategory.environmental,
    searchTerms: ['dust', 'mite'],
  ),
  petDander(
    'Pet dander (cats, dogs)',
    AllergyCategory.environmental,
    searchTerms: ['cat', 'dog', 'pet', 'fur', 'dander', 'animal'],
  ),
  mould(
    'Mould or damp',
    AllergyCategory.environmental,
    searchTerms: ['mould', 'mold', 'fungus', 'damp'],
  ),
  latex(
    'Latex',
    AllergyCategory.environmental,
    searchTerms: ['latex', 'rubber', 'gloves', 'condom'],
  ),
  insectStings(
    'Insect stings (bee, wasp)',
    AllergyCategory.environmental,
    searchTerms: ['bee', 'wasp', 'sting', 'hornet', 'insect'],
  ),
  nickel(
    'Nickel or metal jewellery',
    AllergyCategory.environmental,
    searchTerms: ['nickel', 'metal', 'jewellery', 'jewelry'],
  ),
  otherEnvironmental(
    'Other environmental trigger',
    AllergyCategory.environmental,
    isCustom: true,
  );

  const AllergenType(
    this.label,
    this.category, {
    this.isCustom = false,
    this.searchTerms = const <String>[],
  });

  final String label;
  final AllergyCategory category;

  /// Placeholder for something not on the list; the real name is kept in
  /// [UserAllergy.customName].
  final bool isCustom;

  final List<String> searchTerms;

  bool matches(String query) {
    final String needle = query.trim().toLowerCase();

    if (needle.isEmpty) return true;
    if (label.toLowerCase().contains(needle)) return true;

    return searchTerms.any((String term) => term.contains(needle));
  }
}

@immutable
class UserAllergy {
  const UserAllergy({
    required this.type,
    this.customName,
    this.reactions = const <AllergyReaction>{},
    this.severity,
  });

  final AllergenType type;

  /// Only meaningful when [AllergenType.isCustom] is true.
  final String? customName;

  final Set<AllergyReaction> reactions;
  final AllergySeverity? severity;

  String get displayName {
    if (!type.isCustom) return type.label;

    final String? name = customName?.trim();

    return (name == null || name.isEmpty) ? type.label : name;
  }

  /// True when exposure could be an emergency, so the UI can say so plainly
  /// and later features can escalate instead of offering home advice.
  bool get isEmergencyRisk =>
      severity == AllergySeverity.lifeThreatening ||
      reactions.any((AllergyReaction reaction) => reaction.isEmergency);

  String? get detailSummary {
    final List<String> parts = [
      if (severity != null) severity!.label,
      if (reactions.isNotEmpty)
        '${reactions.length} reaction'
            '${reactions.length == 1 ? '' : 's'}',
    ];

    return parts.isEmpty ? null : parts.join('  •  ');
  }

  UserAllergy copyWith({
    String? customName,
    Set<AllergyReaction>? reactions,
    AllergySeverity? severity,
  }) {
    return UserAllergy(
      type: type,
      customName: customName ?? this.customName,
      reactions: reactions ?? this.reactions,
      severity: severity ?? this.severity,
    );
  }

  @override
  bool operator ==(Object other) {
    if (other is! UserAllergy) return false;

    return type == other.type &&
        customName?.trim() == other.customName?.trim() &&
        severity == other.severity &&
        setEquals(reactions, other.reactions);
  }

  @override
  int get hashCode => Object.hash(
    type,
    customName?.trim(),
    severity,
    Object.hashAllUnordered(reactions),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    'code': type.name,
    'customName': type.isCustom ? customName?.trim() : null,
    'severity': severity?.name,
    'reactions': reactions
        .map((AllergyReaction reaction) => reaction.name)
        .toList(),
  };

  static UserAllergy? fromMap(Map<String, dynamic> map) {
    final AllergenType? type = _lookup(map['code'], AllergenType.values);

    if (type == null) return null;

    final Object? rawReactions = map['reactions'];

    final Set<AllergyReaction> reactions = rawReactions is List
        ? rawReactions
              .map((Object? code) => _lookup(code, AllergyReaction.values))
              .whereType<AllergyReaction>()
              .toSet()
        : const <AllergyReaction>{};

    final Object? customName = map['customName'];

    return UserAllergy(
      type: type,
      customName: customName is String ? customName : null,
      reactions: reactions,
      severity: _lookup(map['severity'], AllergySeverity.values),
    );
  }

  static T? _lookup<T extends Enum>(Object? code, List<T> values) {
    if (code is! String) return null;

    for (final T candidate in values) {
      if (candidate.name == code) return candidate;
    }

    return null;
  }
}

/// The user's allergy answers.
///
/// [noKnownAllergies] is stored separately because "I have no allergies" and
/// "I have not answered yet" are clinically different, and an empty list alone
/// cannot tell them apart.
@immutable
class AllergyRecord {
  const AllergyRecord({
    this.allergies = const <UserAllergy>[],
    this.noKnownAllergies = false,
  });

  static const AllergyRecord empty = AllergyRecord();

  final List<UserAllergy> allergies;
  final bool noKnownAllergies;

  bool get hasAnswered => noKnownAllergies || allergies.isNotEmpty;

  List<UserAllergy> get emergencyRisks => allergies
      .where((UserAllergy allergy) => allergy.isEmergencyRisk)
      .toList();

  factory AllergyRecord.fromMap(Map<String, dynamic> map) {
    final Object? items = map['items'];

    return AllergyRecord(
      allergies: items is List
          ? items
                .whereType<Map<String, dynamic>>()
                .map(UserAllergy.fromMap)
                .whereType<UserAllergy>()
                .toList()
          : const <UserAllergy>[],
      noKnownAllergies: map['noKnownAllergies'] == true,
    );
  }
}
