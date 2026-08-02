import '../symptom.dart';
import '../triage_level.dart';
import '../triage_rules.dart';

/// Guidance for skin, allergy, injury and mental health symptoms.
///
/// The mental health entries are written to be asked directly. Softening a
/// question about suicidal thoughts does not protect anyone; it only makes the
/// answer easier to hide, and TARU cannot escalate what it never hears.
const Map<Symptom, SymptomGuidance>
skinInjuryAndMindGuidance = <Symptom, SymptomGuidance>{
  Symptom.rash: SymptomGuidance(
    baseline: TriageLevel.selfCare,
    redFlags: <RedFlag>[
      RedFlag(
        code: 'rash.nonBlanching',
        question:
            'Does the rash stay visible when you press a glass against '
            'it, with a fever?',
        level: TriageLevel.emergency,
        reason:
            'A rash that does not fade under pressure, alongside a fever, '
            'can mean bacteria in the bloodstream.',
      ),
      RedFlag(
        code: 'rash.airway',
        question:
            'With swelling of the lips, tongue or face, or any difficulty '
            'breathing?',
        level: TriageLevel.emergency,
        reason:
            'This is a severe allergic reaction, and the airway can close '
            'within minutes.',
      ),
      RedFlag(
        code: 'rash.blistering',
        question:
            'Blistering or peeling skin, or sores inside your mouth or '
            'eyes?',
        level: TriageLevel.emergency,
        reason:
            'Skin that blisters along with the mouth or eyes can be a '
            'severe drug reaction, which is treated in hospital.',
      ),
      RedFlag(
        code: 'rash.newMedicine',
        question: 'Did it start after beginning a new medicine?',
        level: TriageLevel.urgent,
        reason:
            'A drug rash is worth catching early, and the medicine usually '
            'needs stopping under advice rather than on your own.',
      ),
      RedFlag(
        code: 'rash.cellulitis',
        question: 'Spreading redness that is hot and painful, with a fever?',
        level: TriageLevel.urgent,
        reason:
            'This is the pattern of a skin infection spreading through the '
            'deeper layers, and it needs antibiotics.',
      ),
    ],
    escalations: <RiskEscalation>[
      RiskEscalation(
        factor: HealthRiskFactor.anaphylaxisHistory,
        level: TriageLevel.urgent,
        reason:
            'You have had a life-threatening reaction before, so a new '
            'rash is watched much more closely.',
      ),
      RiskEscalation(
        factor: HealthRiskFactor.immunosuppressed,
        level: TriageLevel.urgent,
        reason:
            'Skin infections spread faster with a suppressed immune '
            'system.',
      ),
      RiskEscalation(
        factor: HealthRiskFactor.diabetes,
        level: TriageLevel.soon,
        reason: 'Skin infections take hold more easily with diabetes.',
      ),
    ],
    selfCare: <SelfCareTip>[
      SelfCareTip('A cool damp cloth calms itching better than scratching.'),
      SelfCareTip('Fragrance-free moisturiser, and mild soap only.'),
      SelfCareTip(
        'A non-drowsy antihistamine such as cetirizine eases itching, if '
        'you have taken it before without trouble.',
      ),
      SelfCareTip(
        'Photograph it now. Rashes change by the time an appointment '
        'arrives.',
      ),
    ],
    watchFor: <String>[
      'It stops fading under pressure, you develop a fever, or your lips '
          'or tongue swell.',
    ],
  ),

  Symptom.allergicReaction: SymptomGuidance(
    baseline: TriageLevel.urgent,
    redFlags: <RedFlag>[
      RedFlag(
        code: 'allergy.airway',
        question:
            'Any swelling of the tongue, lips or throat, or a feeling that '
            'your throat is tightening?',
        level: TriageLevel.emergency,
        reason:
            'Swelling around the airway is the most dangerous part of an '
            'allergic reaction, and it can progress in minutes.',
      ),
      RedFlag(
        code: 'allergy.breathing',
        question: 'Difficulty breathing, wheezing, or a hoarse voice?',
        level: TriageLevel.emergency,
        reason: 'These mean the reaction has reached the airway.',
      ),
      RedFlag(
        code: 'allergy.collapse',
        question: 'Feeling faint, dizzy, or as though you might collapse?',
        level: TriageLevel.emergency,
        reason:
            'A drop in blood pressure during a reaction is anaphylaxis, '
            'whether or not there is a rash.',
      ),
      RedFlag(
        code: 'allergy.widespreadHives',
        question: 'Are hives spreading across your body?',
        level: TriageLevel.urgent,
        reason:
            'A whole-body reaction can move on to the airway, so it is '
            'watched somewhere with treatment on hand.',
      ),
      RedFlag(
        code: 'allergy.gut',
        question:
            'Vomiting or stomach cramps that started right after '
            'exposure?',
        level: TriageLevel.urgent,
        reason:
            'Gut symptoms straight after exposure count towards a severe '
            'reaction rather than a stomach upset.',
      ),
    ],
    escalations: <RiskEscalation>[
      RiskEscalation(
        factor: HealthRiskFactor.anaphylaxisHistory,
        level: TriageLevel.emergency,
        reason:
            'You have had a life-threatening reaction before, so this one '
            'is treated as an emergency until it has clearly settled.',
      ),
    ],
    actions: <String>[
      'If you carry an adrenaline auto-injector, use it now into the outer '
          'thigh — then still call for help, even if you improve.',
      'Lie flat with your legs raised if you feel faint. Do not stand up '
          'suddenly.',
      'Write down what you were exposed to and when. It decides what you '
          'must avoid for life.',
    ],
    watchFor: <String>[
      'Symptoms come back a few hours later — reactions can return after '
          'seeming to settle.',
    ],
  ),

  Symptom.wound: SymptomGuidance(
    baseline: TriageLevel.soon,
    redFlags: <RedFlag>[
      RedFlag(
        code: 'wound.bleeding',
        question: 'Is it still bleeding after 10 minutes of firm pressure?',
        level: TriageLevel.emergency,
        reason: 'Bleeding that will not stop needs closing properly.',
        emergencyWhen: <HealthRiskFactor>{HealthRiskFactor.bleedingRisk},
      ),
      RedFlag(
        code: 'wound.streaks',
        question: 'Are there red streaks running away from the wound?',
        level: TriageLevel.urgent,
        reason:
            'Streaks mean the infection is travelling along the lymph '
            'channels.',
      ),
      RedFlag(
        code: 'wound.spreadingFever',
        question: 'Spreading redness, swelling or pus, with a fever?',
        level: TriageLevel.urgent,
        reason:
            'This is an infection that needs antibiotics rather than '
            'dressings.',
      ),
      RedFlag(
        code: 'wound.bite',
        question: 'Was it caused by an animal or human bite?',
        level: TriageLevel.urgent,
        reason:
            'Bites are treated differently: they need cleaning, usually '
            'antibiotics, and a decision about tetanus and rabies cover.',
      ),
      RedFlag(
        code: 'wound.numbArea',
        question: 'Is it on a foot or an area where you have reduced feeling?',
        level: TriageLevel.urgent,
        reason:
            'A wound you cannot feel gets deeper without warning you, '
            'which is how foot ulcers begin.',
      ),
    ],
    escalations: <RiskEscalation>[
      RiskEscalation(
        factor: HealthRiskFactor.diabetes,
        level: TriageLevel.urgent,
        reason:
            'Foot and leg wounds with diabetes are seen quickly, because '
            'they get deep before they hurt and heal slowly once infected.',
      ),
      RiskEscalation(
        factor: HealthRiskFactor.immunosuppressed,
        level: TriageLevel.urgent,
        reason: 'Wound infections escalate faster when immunity is low.',
      ),
    ],
    selfCare: <SelfCareTip>[
      SelfCareTip('Rinse under clean running water and pat dry.'),
      SelfCareTip('Cover with a clean dressing and change it daily.'),
      SelfCareTip(
        'Check whether your tetanus jab is within ten years — ask if you '
        'are unsure.',
      ),
      SelfCareTip(
        'Draw a line around any redness with a pen. If it spreads past the '
        'line, get it seen.',
      ),
    ],
    watchFor: <String>['Redness spreads, pus appears, or you develop a fever.'],
  ),

  Symptom.backPain: SymptomGuidance(
    baseline: TriageLevel.selfCare,
    redFlags: <RedFlag>[
      RedFlag(
        code: 'back.caudaEquina',
        question:
            'Any loss of control of your bladder or bowels, or numbness '
            'between your legs or around the back passage?',
        level: TriageLevel.emergency,
        reason:
            'These mean pressure on the nerves at the base of the spine. '
            'Surgery within hours is what preserves control permanently.',
      ),
      RedFlag(
        code: 'back.legWeakness',
        question: 'Weakness in one or both legs?',
        level: TriageLevel.urgent,
        reason:
            'Weakness means a nerve is being compressed, not just '
            'irritated.',
      ),
      RedFlag(
        code: 'back.injury',
        question: 'Did it follow a fall or an accident?',
        level: TriageLevel.urgent,
        reason:
            'Back pain after an injury needs a fracture ruled out, '
            'particularly if your bones are thin.',
      ),
      RedFlag(
        code: 'back.infection',
        question: 'With a fever, or pain that wakes you from sleep?',
        level: TriageLevel.urgent,
        reason:
            'Night pain and fever raise the possibility of infection in '
            'the spine rather than a strain.',
      ),
      RedFlag(
        code: 'back.cancerHistory',
        question: 'With unplanned weight loss, or a history of cancer?',
        level: TriageLevel.urgent,
        reason:
            'These change what has to be ruled out before treating it as '
            'mechanical pain.',
      ),
    ],
    escalations: <RiskEscalation>[
      RiskEscalation(
        factor: HealthRiskFactor.immunosuppressed,
        level: TriageLevel.urgent,
        reason:
            'Spinal infections are rare but far more likely when immunity '
            'is suppressed.',
      ),
      RiskEscalation(
        factor: HealthRiskFactor.olderAdult,
        level: TriageLevel.soon,
        reason:
            'New back pain after 65 is more often a fracture than a strain.',
      ),
    ],
    selfCare: <SelfCareTip>[
      SelfCareTip(
        'Keep moving gently. Bed rest beyond a day or two makes back pain '
        'last longer, not shorter.',
      ),
      SelfCareTip('Heat for muscle spasm, for 15 minutes at a time.'),
      SelfCareTip(
        'Paracetamol regularly rather than waiting for the pain to peak.',
        guard: SelfCareGuard.paracetamol,
      ),
      SelfCareTip(
        'A short course of ibuprofen for the first few days.',
        guard: SelfCareGuard.nsaid,
      ),
    ],
    watchFor: <String>[
      'Numbness between the legs, trouble passing urine, or new leg '
          'weakness — these cannot wait.',
    ],
  ),

  Symptom.injury: SymptomGuidance(
    baseline: TriageLevel.soon,
    redFlags: <RedFlag>[
      RedFlag(
        code: 'injury.headSerious',
        question:
            'After a knock to the head: did you black out, vomit, or are '
            'you confused or drowsy?',
        level: TriageLevel.emergency,
        reason:
            'These are the signs of bleeding or swelling inside the skull, '
            'which is found with a scan.',
      ),
      RedFlag(
        code: 'injury.bleeding',
        question: 'Bleeding that will not stop with 10 minutes of pressure?',
        level: TriageLevel.emergency,
        reason: 'Uncontrolled bleeding needs closing at a hospital.',
      ),
      RedFlag(
        code: 'injury.deformity',
        question: 'Is a limb bent oddly, or can you not put any weight on it?',
        level: TriageLevel.urgent,
        reason:
            'Both suggest a fracture, which needs an X-ray and setting '
            'before it swells further.',
      ),
      RedFlag(
        code: 'injury.circulation',
        question:
            'Numbness, pins and needles, or cold pale skin beyond the '
            'injury?',
        level: TriageLevel.urgent,
        reason:
            'This suggests a nerve or blood vessel is being pressed, which '
            'is time-critical.',
      ),
      RedFlag(
        code: 'injury.headKnock',
        question: 'Was your head hit at all, even lightly?',
        level: TriageLevel.soon,
        reason:
            'Head injuries are watched for 48 hours even when they '
            'seem minor.',
        emergencyWhen: <HealthRiskFactor>{HealthRiskFactor.bleedingRisk},
      ),
    ],
    escalations: <RiskEscalation>[
      RiskEscalation(
        factor: HealthRiskFactor.bleedingRisk,
        level: TriageLevel.urgent,
        reason:
            'On a blood thinner, bleeding inside the body can start slowly '
            'and show itself hours later.',
      ),
      RiskEscalation(
        factor: HealthRiskFactor.olderAdult,
        level: TriageLevel.urgent,
        reason:
            'A fall after 65 is worth checking even when it feels minor, '
            'both for fractures and for what caused the fall.',
      ),
    ],
    selfCare: <SelfCareTip>[
      SelfCareTip('Rest it, and ice for 20 minutes every couple of hours.'),
      SelfCareTip('A snug bandage and keeping it raised limit swelling.'),
      SelfCareTip('Paracetamol for pain.', guard: SelfCareGuard.paracetamol),
      SelfCareTip(
        'Ibuprofen, or a gel rubbed in, for a sprain or bruise.',
        guard: SelfCareGuard.nsaid,
      ),
    ],
    watchFor: <String>[
      'After a head injury: vomiting, worsening headache, drowsiness or '
          'confusion in the next 48 hours.',
      'The joint cannot bear weight the next day, or swelling keeps '
          'growing.',
    ],
  ),

  Symptom.bleeding: SymptomGuidance(
    baseline: TriageLevel.soon,
    redFlags: <RedFlag>[
      RedFlag(
        code: 'bleeding.uncontrolled',
        question: 'Is it heavy, or not stopping with firm pressure?',
        level: TriageLevel.emergency,
        reason: 'Bleeding you cannot control needs treating now.',
      ),
      RedFlag(
        code: 'bleeding.gut',
        question: 'Vomiting blood, or passing black tarry stools?',
        level: TriageLevel.emergency,
        reason:
            'Both mean bleeding inside the gut, which can be brisk without '
            'looking dramatic.',
      ),
      RedFlag(
        code: 'bleeding.shock',
        question: 'Feeling dizzy, pale, or breathless with it?',
        level: TriageLevel.emergency,
        reason:
            'These mean you have lost enough blood for it to affect your '
            'circulation.',
      ),
      RedFlag(
        code: 'bleeding.spontaneous',
        question:
            'Bruises appearing without injury, or gums bleeding on their '
            'own?',
        level: TriageLevel.urgent,
        reason:
            'Bleeding without a cause suggests a problem with clotting or '
            'platelets, which is found with a blood test.',
      ),
      RedFlag(
        code: 'bleeding.afterFall',
        question: 'Did it follow a fall or a knock?',
        level: TriageLevel.urgent,
        reason: 'Injury plus bleeding needs the extent checked properly.',
        emergencyWhen: <HealthRiskFactor>{HealthRiskFactor.bleedingRisk},
      ),
    ],
    escalations: <RiskEscalation>[
      RiskEscalation(
        factor: HealthRiskFactor.bleedingRisk,
        level: TriageLevel.urgent,
        reason:
            'You take a blood thinner, so bleeding takes longer to stop '
            'and needs reviewing even when it looks small.',
      ),
      RiskEscalation(
        factor: HealthRiskFactor.liverDisease,
        level: TriageLevel.urgent,
        reason: 'Liver disease reduces the proteins that make blood clot.',
      ),
    ],
    actions: <String>[
      'Press firmly on the spot for a full 10 minutes without lifting to '
          'check.',
    ],
    selfCare: <SelfCareTip>[
      SelfCareTip(
        'For a nosebleed, lean forward and pinch the soft part of the nose '
        'for 10 minutes.',
      ),
      SelfCareTip('Avoid alcohol and hot drinks for a few hours after.'),
    ],
    watchFor: <String>['Bleeding restarts, or you feel dizzy or breathless.'],
  ),

  Symptom.lowMood: SymptomGuidance(
    baseline: TriageLevel.soon,
    redFlags: <RedFlag>[
      RedFlag(
        code: 'mood.plan',
        question:
            'Are you having thoughts of ending your life, with a plan or '
            'the means to act on it?',
        level: TriageLevel.emergency,
        reason:
            'You should not have to carry this alone, and help is '
            'available right now.',
      ),
      RedFlag(
        code: 'mood.unsafe',
        question: 'Do you feel unable to keep yourself safe today?',
        level: TriageLevel.emergency,
        reason:
            'Not feeling safe is reason enough to get help today, whatever '
            'else is going on.',
      ),
      RedFlag(
        code: 'mood.selfHarmThoughts',
        question:
            'Thoughts of harming yourself, without a plan to act on them?',
        level: TriageLevel.urgent,
        reason:
            'These thoughts are more common than people are told, and they '
            'ease considerably with support.',
      ),
      RedFlag(
        code: 'mood.selfCareStopped',
        question:
            'Have you stopped eating, sleeping, or looking after '
            'yourself?',
        level: TriageLevel.urgent,
        reason:
            'When the basics stop, recovery needs more than time on its '
            'own.',
      ),
      RedFlag(
        code: 'mood.twoWeeks',
        question: 'Has this been most days for more than two weeks?',
        level: TriageLevel.soon,
        reason:
            'Two weeks is the point where this is treated as depression '
            'rather than a low patch, and treatment works.',
      ),
    ],
    actions: <String>[
      'If you might act on these thoughts, call your local emergency '
          'number or a crisis line now: 988 in the US, 116 123 in the UK '
          'and Ireland, 9152987821 (AASRA) in India.',
      'Tell one person today. It does not have to be a professional.',
    ],
    selfCare: <SelfCareTip>[
      SelfCareTip('Keep the shape of the day, even when it feels pointless.'),
      SelfCareTip('Daylight and any movement, however short.'),
      SelfCareTip('Alcohol lifts mood for an hour and lowers it for a day.'),
      SelfCareTip(
        'Book a doctor\'s appointment. Talking treatments and medicine '
        'both work, and you do not have to be at your worst to qualify.',
      ),
    ],
    watchFor: <String>[
      'Thoughts of harming yourself become more frequent, or start to feel '
          'like a plan.',
    ],
  ),

  Symptom.anxiety: SymptomGuidance(
    baseline: TriageLevel.soon,
    redFlags: <RedFlag>[
      RedFlag(
        code: 'anxiety.firstEpisodeCardiac',
        question:
            'Is this the first time, with chest pain or a pounding '
            'heart?',
        level: TriageLevel.urgent,
        reason:
            'A first episode with chest symptoms is checked physically '
            'before it is called panic.',
      ),
      RedFlag(
        code: 'anxiety.selfHarm',
        question: 'Any thoughts of harming yourself?',
        level: TriageLevel.urgent,
        reason:
            'This needs support today rather than at the next '
            'appointment.',
      ),
      RedFlag(
        code: 'anxiety.function',
        question: 'Is it stopping you working, sleeping, or leaving the house?',
        level: TriageLevel.soon,
        reason:
            'Anxiety that limits your life responds well to treatment, and '
            'earlier is easier.',
      ),
      RedFlag(
        code: 'anxiety.substance',
        question:
            'Did it start after a new medicine, or alongside caffeine, '
            'alcohol or other substances?',
        level: TriageLevel.soon,
        reason:
            'Several common medicines and stimulants produce anxiety '
            'directly, and that is a fixable cause.',
      ),
    ],
    selfCare: <SelfCareTip>[
      SelfCareTip(
        'Breathe out for longer than you breathe in — four in, six out — '
        'for a few minutes. It works on the physical symptoms.',
      ),
      SelfCareTip('Cut caffeine, which imitates anxiety almost exactly.'),
      SelfCareTip('Regular exercise reduces baseline anxiety over weeks.'),
      SelfCareTip(
        'Ask about talking therapy. For panic in particular it works '
        'better than medicine on its own.',
      ),
    ],
    watchFor: <String>[
      'Chest pain or breathlessness that feels different from your usual '
          'pattern.',
    ],
  ),
};
