/// Roughly by body system, matching how the conditions list is grouped.
enum SymptomCategory {
  chestAndBreathing('Chest & breathing'),
  headAndNerves('Head & nerves'),
  stomachAndDigestion('Stomach & digestion'),
  generalAndFever('General & fever'),
  skinAndAllergy('Skin & allergy'),
  urinary('Urine & kidneys'),
  bonesAndInjury('Bones & injury'),
  mindAndMood('Mind & mood');

  const SymptomCategory(this.label);

  final String label;
}

/// What someone can tell TARU they are feeling.
///
/// The enum name is the stable code that gets stored with a check, so wording
/// can change later without rewriting anybody's history. [searchTerms] carry
/// the words people actually type — "loose motion", "giddy", "cannot breathe"
/// — because nobody in distress searches for "dyspnoea".
///
/// The list is deliberately finite. A free-text box would accept anything and
/// let TARU quietly fail to recognise a stroke; a fixed list means every entry
/// has red-flag questions written for it.
enum Symptom {
  // Chest & breathing
  chestPain(
    'Chest pain, pressure or tightness',
    SymptomCategory.chestAndBreathing,
    isCommon: true,
    searchTerms: ['chest', 'heart pain', 'angina', 'tightness', 'chest pain'],
  ),
  breathlessness(
    'Shortness of breath',
    SymptomCategory.chestAndBreathing,
    isCommon: true,
    searchTerms: [
      'breath',
      'breathless',
      'cannot breathe',
      'wheeze',
      'suffocating',
      'saans',
    ],
  ),
  cough(
    'Cough',
    SymptomCategory.chestAndBreathing,
    isCommon: true,
    searchTerms: ['cough', 'phlegm', 'sputum', 'khansi'],
  ),
  palpitations(
    'Racing or irregular heartbeat',
    SymptomCategory.chestAndBreathing,
    searchTerms: ['palpitation', 'heartbeat', 'fluttering', 'pounding heart'],
  ),

  // Head & nerves
  headache(
    'Headache',
    SymptomCategory.headAndNerves,
    isCommon: true,
    searchTerms: ['headache', 'head pain', 'migraine', 'sir dard'],
  ),
  dizziness(
    'Dizziness or feeling faint',
    SymptomCategory.headAndNerves,
    isCommon: true,
    searchTerms: ['dizzy', 'giddy', 'vertigo', 'spinning', 'lightheaded'],
  ),
  weaknessOrNumbness(
    'Sudden weakness, numbness or trouble speaking',
    SymptomCategory.headAndNerves,
    searchTerms: [
      'stroke',
      'paralysis',
      'face droop',
      'slurred',
      'numb',
      'weakness one side',
    ],
  ),
  fainting(
    'Fainting or blacking out',
    SymptomCategory.headAndNerves,
    searchTerms: ['faint', 'collapse', 'passed out', 'blackout', 'chakkar'],
  ),

  // Stomach & digestion
  abdominalPain(
    'Stomach or belly pain',
    SymptomCategory.stomachAndDigestion,
    isCommon: true,
    searchTerms: ['stomach', 'tummy', 'abdomen', 'cramps', 'pet dard'],
  ),
  vomiting(
    'Nausea or vomiting',
    SymptomCategory.stomachAndDigestion,
    isCommon: true,
    searchTerms: ['vomit', 'nausea', 'sick', 'throwing up', 'ulti'],
  ),
  diarrhoea(
    'Diarrhoea',
    SymptomCategory.stomachAndDigestion,
    isCommon: true,
    searchTerms: ['diarrhea', 'loose motion', 'loose stools', 'dast'],
  ),
  acidity(
    'Acidity, heartburn or indigestion',
    SymptomCategory.stomachAndDigestion,
    isCommon: true,
    searchTerms: ['acidity', 'heartburn', 'gas', 'indigestion', 'burning'],
  ),

  // General & fever
  fever(
    'Fever',
    SymptomCategory.generalAndFever,
    isCommon: true,
    searchTerms: ['fever', 'temperature', 'chills', 'bukhar'],
  ),
  fatigue(
    'Unusual tiredness or weakness',
    SymptomCategory.generalAndFever,
    isCommon: true,
    searchTerms: ['tired', 'fatigue', 'exhausted', 'no energy', 'weakness'],
  ),
  swollenLegs(
    'Swollen legs, ankles or feet',
    SymptomCategory.generalAndFever,
    searchTerms: ['swelling', 'oedema', 'edema', 'puffy ankles'],
  ),
  bloodSugarSymptoms(
    'Blood sugar symptoms (thirst, shakiness, sweats)',
    SymptomCategory.generalAndFever,
    searchTerms: ['sugar', 'hypo', 'hyper', 'thirst', 'shaky', 'diabetes'],
  ),

  // Skin & allergy
  rash(
    'Rash or itching',
    SymptomCategory.skinAndAllergy,
    isCommon: true,
    searchTerms: ['rash', 'itch', 'hives', 'spots', 'skin'],
  ),
  allergicReaction(
    'Reaction after a medicine, food or sting',
    SymptomCategory.skinAndAllergy,
    searchTerms: ['allergy', 'allergic', 'reaction', 'sting', 'swelling face'],
  ),
  wound(
    'Wound, boil or skin infection',
    SymptomCategory.skinAndAllergy,
    searchTerms: ['wound', 'cut', 'boil', 'abscess', 'ulcer', 'infected'],
  ),

  // Urine & kidneys
  urinarySymptoms(
    'Burning or frequent urination',
    SymptomCategory.urinary,
    isCommon: true,
    searchTerms: ['urine', 'uti', 'burning', 'peeing', 'bladder', 'peshab'],
  ),

  // Bones & injury
  backPain(
    'Back pain',
    SymptomCategory.bonesAndInjury,
    isCommon: true,
    searchTerms: ['back', 'spine', 'lower back', 'kamar dard'],
  ),
  injury(
    'Injury, fall or head knock',
    SymptomCategory.bonesAndInjury,
    searchTerms: ['injury', 'fall', 'accident', 'sprain', 'head injury'],
  ),
  bleeding(
    'Unusual bleeding or bruising',
    SymptomCategory.bonesAndInjury,
    searchTerms: ['bleeding', 'bruise', 'blood', 'nosebleed'],
  ),

  // Mind & mood
  lowMood(
    'Low mood, hopelessness or thoughts of self-harm',
    SymptomCategory.mindAndMood,
    isCommon: true,
    searchTerms: ['depressed', 'sad', 'hopeless', 'suicidal', 'self harm'],
  ),
  anxiety(
    'Anxiety or panic',
    SymptomCategory.mindAndMood,
    searchTerms: ['anxiety', 'panic', 'worry', 'nervous', 'attack'],
  ),

  // Other everyday complaints kept in an existing group rather than a bin
  soreThroat(
    'Sore throat',
    SymptomCategory.chestAndBreathing,
    isCommon: true,
    searchTerms: ['throat', 'swallow', 'tonsils', 'gala'],
  ),
  eyeProblem(
    'Eye pain or change in vision',
    SymptomCategory.headAndNerves,
    searchTerms: ['eye', 'vision', 'blurred', 'sight', 'red eye'],
  );

  const Symptom(
    this.label,
    this.category, {
    this.isCommon = false,
    this.searchTerms = const <String>[],
  });

  final String label;
  final SymptomCategory category;

  /// Surfaced above the full list, since most checks start with one of these.
  final bool isCommon;

  final List<String> searchTerms;

  bool matches(String query) {
    final String needle = query.trim().toLowerCase();

    if (needle.isEmpty) return true;
    if (label.toLowerCase().contains(needle)) return true;

    return searchTerms.any((String term) => term.contains(needle));
  }
}
