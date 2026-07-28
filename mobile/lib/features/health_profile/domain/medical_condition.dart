import 'package:flutter/foundation.dart';

/// Roughly by body system, so a long list stays navigable.
enum ConditionCategory {
  heartAndCirculation('Heart & circulation'),
  metabolicAndHormones('Metabolic & hormones'),
  lungsAndBreathing('Lungs & breathing'),
  kidneysAndLiver('Kidneys & liver'),
  digestive('Digestive'),
  brainAndNerves('Brain & nerves'),
  mentalHealth('Mental health'),
  bonesAndJoints('Bones & joints'),
  bloodAndImmune('Blood & immune'),
  other('Other');

  const ConditionCategory(this.label);

  final String label;
}

enum ConditionControl {
  wellControlled('Well controlled'),
  partlyControlled('Partly controlled'),
  notControlled('Not controlled'),
  unsure('Not sure');

  const ConditionControl(this.label);

  final String label;
}

/// The conditions TARU can recognise.
///
/// The enum name is the stable code that gets stored. Labels are display text
/// and can be reworded or translated later without touching anyone's saved
/// medical history, and each entry can be mapped to an ICD-10 code when needed.
///
/// [searchTerms] carry the words people actually use — "sugar" for diabetes,
/// "BP" for blood pressure — so search works outside clinical vocabulary.
enum MedicalConditionType {
  // Heart & circulation
  hypertension(
    'High blood pressure (hypertension)',
    ConditionCategory.heartAndCirculation,
    isCommon: true,
    searchTerms: ['bp', 'blood pressure', 'hypertension'],
  ),
  highCholesterol(
    'High cholesterol',
    ConditionCategory.heartAndCirculation,
    isCommon: true,
    searchTerms: ['cholesterol', 'lipids', 'triglycerides'],
  ),
  coronaryArteryDisease(
    'Coronary artery disease',
    ConditionCategory.heartAndCirculation,
    searchTerms: ['heart attack', 'angina', 'cad', 'blockage', 'stent'],
  ),
  heartFailure(
    'Heart failure',
    ConditionCategory.heartAndCirculation,
    searchTerms: ['weak heart', 'chf'],
  ),
  atrialFibrillation(
    'Atrial fibrillation',
    ConditionCategory.heartAndCirculation,
    searchTerms: ['irregular heartbeat', 'af', 'afib', 'palpitations'],
  ),
  strokeHistory(
    'Previous stroke or TIA',
    ConditionCategory.heartAndCirculation,
    searchTerms: ['stroke', 'tia', 'paralysis', 'brain attack'],
  ),

  // Metabolic & hormones
  type2Diabetes(
    'Type 2 diabetes',
    ConditionCategory.metabolicAndHormones,
    isCommon: true,
    searchTerms: ['sugar', 'diabetes', 'blood sugar', 'diabetic'],
  ),
  type1Diabetes(
    'Type 1 diabetes',
    ConditionCategory.metabolicAndHormones,
    searchTerms: ['sugar', 'diabetes', 'insulin', 'diabetic'],
  ),
  prediabetes(
    'Prediabetes',
    ConditionCategory.metabolicAndHormones,
    searchTerms: ['borderline sugar', 'impaired glucose'],
  ),
  hypothyroidism(
    'Underactive thyroid (hypothyroidism)',
    ConditionCategory.metabolicAndHormones,
    isCommon: true,
    searchTerms: ['thyroid', 'hypothyroid', 'tsh'],
  ),
  hyperthyroidism(
    'Overactive thyroid (hyperthyroidism)',
    ConditionCategory.metabolicAndHormones,
    searchTerms: ['thyroid', 'hyperthyroid', 'graves'],
  ),
  polycysticOvarySyndrome(
    'Polycystic ovary syndrome (PCOS)',
    ConditionCategory.metabolicAndHormones,
    searchTerms: ['pcos', 'pcod', 'ovary', 'irregular periods'],
  ),
  gout(
    'Gout',
    ConditionCategory.metabolicAndHormones,
    searchTerms: ['uric acid', 'gout'],
  ),

  // Lungs & breathing
  asthma(
    'Asthma',
    ConditionCategory.lungsAndBreathing,
    isCommon: true,
    searchTerms: ['asthma', 'wheezing', 'inhaler'],
  ),
  chronicObstructivePulmonaryDisease(
    'COPD',
    ConditionCategory.lungsAndBreathing,
    searchTerms: ['copd', 'emphysema', 'chronic bronchitis', 'smoker lung'],
  ),
  sleepApnoea(
    'Sleep apnoea',
    ConditionCategory.lungsAndBreathing,
    searchTerms: ['snoring', 'apnea', 'apnoea', 'cpap'],
  ),
  tuberculosis(
    'Tuberculosis (past or present)',
    ConditionCategory.lungsAndBreathing,
    searchTerms: ['tb', 'tuberculosis'],
  ),

  // Kidneys & liver
  chronicKidneyDisease(
    'Chronic kidney disease',
    ConditionCategory.kidneysAndLiver,
    searchTerms: ['ckd', 'kidney', 'renal', 'creatinine', 'dialysis'],
  ),
  kidneyStones(
    'Kidney stones',
    ConditionCategory.kidneysAndLiver,
    searchTerms: ['stone', 'renal calculi'],
  ),
  fattyLiverDisease(
    'Fatty liver disease',
    ConditionCategory.kidneysAndLiver,
    searchTerms: ['fatty liver', 'nafld', 'liver'],
  ),
  hepatitisB(
    'Hepatitis B',
    ConditionCategory.kidneysAndLiver,
    searchTerms: ['hep b', 'hbv', 'jaundice'],
  ),
  hepatitisC(
    'Hepatitis C',
    ConditionCategory.kidneysAndLiver,
    searchTerms: ['hep c', 'hcv'],
  ),
  liverCirrhosis(
    'Liver cirrhosis',
    ConditionCategory.kidneysAndLiver,
    searchTerms: ['cirrhosis', 'liver failure'],
  ),

  // Digestive
  acidReflux(
    'Acid reflux (GERD)',
    ConditionCategory.digestive,
    isCommon: true,
    searchTerms: ['acidity', 'heartburn', 'gerd', 'gastritis', 'reflux'],
  ),
  pepticUlcer(
    'Stomach or duodenal ulcer',
    ConditionCategory.digestive,
    searchTerms: ['ulcer', 'peptic'],
  ),
  irritableBowelSyndrome(
    'Irritable bowel syndrome (IBS)',
    ConditionCategory.digestive,
    searchTerms: ['ibs', 'bowel', 'bloating'],
  ),
  coeliacDisease(
    'Coeliac disease',
    ConditionCategory.digestive,
    searchTerms: ['celiac', 'coeliac', 'gluten'],
  ),
  inflammatoryBowelDisease(
    'Crohn\'s disease or ulcerative colitis',
    ConditionCategory.digestive,
    searchTerms: ['ibd', 'crohn', 'colitis'],
  ),

  // Brain & nerves
  migraine(
    'Migraine',
    ConditionCategory.brainAndNerves,
    isCommon: true,
    searchTerms: ['migraine', 'headache'],
  ),
  epilepsy(
    'Epilepsy',
    ConditionCategory.brainAndNerves,
    searchTerms: ['seizures', 'fits', 'epilepsy'],
  ),
  parkinsonsDisease(
    'Parkinson\'s disease',
    ConditionCategory.brainAndNerves,
    searchTerms: ['parkinson', 'tremor'],
  ),
  dementia(
    'Dementia or Alzheimer\'s',
    ConditionCategory.brainAndNerves,
    searchTerms: ['dementia', 'alzheimer', 'memory loss'],
  ),

  // Mental health
  depression(
    'Depression',
    ConditionCategory.mentalHealth,
    isCommon: true,
    searchTerms: ['depression', 'low mood'],
  ),
  anxietyDisorder(
    'Anxiety disorder',
    ConditionCategory.mentalHealth,
    isCommon: true,
    searchTerms: ['anxiety', 'panic'],
  ),
  bipolarDisorder(
    'Bipolar disorder',
    ConditionCategory.mentalHealth,
    searchTerms: ['bipolar', 'manic'],
  ),

  // Bones & joints
  osteoarthritis(
    'Osteoarthritis',
    ConditionCategory.bonesAndJoints,
    isCommon: true,
    searchTerms: ['arthritis', 'joint pain', 'knee pain'],
  ),
  rheumatoidArthritis(
    'Rheumatoid arthritis',
    ConditionCategory.bonesAndJoints,
    searchTerms: ['ra', 'rheumatoid', 'arthritis'],
  ),
  osteoporosis(
    'Osteoporosis',
    ConditionCategory.bonesAndJoints,
    searchTerms: ['osteoporosis', 'bone density', 'weak bones'],
  ),

  // Blood & immune
  anaemia(
    'Anaemia',
    ConditionCategory.bloodAndImmune,
    isCommon: true,
    searchTerms: ['anemia', 'anaemia', 'iron', 'haemoglobin', 'hemoglobin'],
  ),
  sickleCellDisease(
    'Sickle cell disease',
    ConditionCategory.bloodAndImmune,
    searchTerms: ['sickle cell'],
  ),
  thalassaemia(
    'Thalassaemia',
    ConditionCategory.bloodAndImmune,
    searchTerms: ['thalassemia', 'thalassaemia'],
  ),
  humanImmunodeficiencyVirus(
    'HIV',
    ConditionCategory.bloodAndImmune,
    searchTerms: ['hiv', 'aids'],
  ),
  cancer(
    'Cancer (past or present)',
    ConditionCategory.bloodAndImmune,
    searchTerms: ['cancer', 'tumour', 'tumor', 'chemotherapy'],
  ),

  /// Anything not on the list. The real name is kept in
  /// [UserCondition.customName].
  other('Other condition', ConditionCategory.other);

  const MedicalConditionType(
    this.label,
    this.category, {
    this.isCommon = false,
    this.searchTerms = const <String>[],
  });

  final String label;
  final ConditionCategory category;

  /// Surfaced above the full list, since most people need one of these.
  final bool isCommon;

  final List<String> searchTerms;

  bool matches(String query) {
    final String needle = query.trim().toLowerCase();

    if (needle.isEmpty) return true;
    if (label.toLowerCase().contains(needle)) return true;

    return searchTerms.any((String term) => term.contains(needle));
  }
}

/// A condition this particular person has, with optional clinical detail.
///
/// Whether hypertension is well controlled or not controlled changes advice far
/// more than simply having it, so those details are worth room even though they
/// stay optional.
@immutable
class UserCondition {
  const UserCondition({
    required this.type,
    this.customName,
    this.yearDiagnosed,
    this.control,
  });

  final MedicalConditionType type;

  /// Only meaningful for [MedicalConditionType.other].
  final String? customName;

  final int? yearDiagnosed;
  final ConditionControl? control;

  String get displayName {
    if (type != MedicalConditionType.other) return type.label;

    final String? name = customName?.trim();

    return (name == null || name.isEmpty) ? type.label : name;
  }

  /// Short summary of the optional detail, for list subtitles.
  String? get detailSummary {
    final List<String> parts = [
      if (yearDiagnosed != null) 'Since $yearDiagnosed',
      if (control != null) control!.label,
    ];

    return parts.isEmpty ? null : parts.join('  •  ');
  }

  UserCondition copyWith({
    String? customName,
    int? yearDiagnosed,
    ConditionControl? control,
    bool clearYearDiagnosed = false,
    bool clearControl = false,
  }) {
    return UserCondition(
      type: type,
      customName: customName ?? this.customName,
      yearDiagnosed: clearYearDiagnosed
          ? null
          : (yearDiagnosed ?? this.yearDiagnosed),
      control: clearControl ? null : (control ?? this.control),
    );
  }

  @override
  bool operator ==(Object other) {
    if (other is! UserCondition) return false;

    return type == other.type &&
        customName?.trim() == other.customName?.trim() &&
        yearDiagnosed == other.yearDiagnosed &&
        control == other.control;
  }

  @override
  int get hashCode =>
      Object.hash(type, customName?.trim(), yearDiagnosed, control);

  Map<String, dynamic> toMap() => <String, dynamic>{
    'code': type.name,
    'customName': type == MedicalConditionType.other
        ? customName?.trim()
        : null,
    'yearDiagnosed': yearDiagnosed,
    'control': control?.name,
  };

  /// Returns null for records whose condition code is no longer recognised,
  /// so one unknown entry cannot break the whole list.
  static UserCondition? fromMap(Map<String, dynamic> map) {
    final Object? code = map['code'];

    if (code is! String) return null;

    MedicalConditionType? type;

    for (final MedicalConditionType candidate in MedicalConditionType.values) {
      if (candidate.name == code) {
        type = candidate;
        break;
      }
    }

    if (type == null) return null;

    ConditionControl? control;

    final Object? controlCode = map['control'];

    if (controlCode is String) {
      for (final ConditionControl candidate in ConditionControl.values) {
        if (candidate.name == controlCode) {
          control = candidate;
          break;
        }
      }
    }

    final Object? year = map['yearDiagnosed'];
    final Object? customName = map['customName'];

    return UserCondition(
      type: type,
      customName: customName is String ? customName : null,
      yearDiagnosed: year is num ? year.toInt() : null,
      control: control,
    );
  }
}
