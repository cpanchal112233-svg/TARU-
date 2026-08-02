import '../symptom.dart';
import '../triage_level.dart';
import '../triage_rules.dart';

/// Guidance for chest, breathing, head and nerve symptoms.
///
/// These carry most of the time-critical patterns TARU has to catch: heart
/// attack, stroke, bleeding in the brain, meningitis and a collapsing airway.
/// Baselines are set high on purpose. Chest pain with every question answered
/// "no" is still a same-day problem, because a questionnaire cannot rule out a
/// heart attack and pretending otherwise is the one mistake that cannot be
/// undone.
const Map<Symptom, SymptomGuidance>
chestAndHeadGuidance = <Symptom, SymptomGuidance>{
  Symptom.chestPain: SymptomGuidance(
    baseline: TriageLevel.urgent,
    redFlags: <RedFlag>[
      RedFlag(
        code: 'chestPain.pressure',
        question:
            'Has it lasted more than 15 minutes, or does it feel like '
            'heavy pressure or squeezing?',
        level: TriageLevel.emergency,
        reason:
            'Pressure that does not pass can be a heart attack, and the '
            'treatment that saves heart muscle works best in the first '
            'hour.',
      ),
      RedFlag(
        code: 'chestPain.spreading',
        question: 'Does the pain spread to your arm, jaw, neck or back?',
        level: TriageLevel.emergency,
        reason:
            'Pain that travels away from the chest like this is a classic '
            'warning sign of a heart attack.',
      ),
      RedFlag(
        code: 'chestPain.sweating',
        question: 'Are you also sweating, feeling sick, or short of breath?',
        level: TriageLevel.emergency,
        reason:
            'Chest pain together with sweating or breathlessness points '
            'towards the heart rather than a muscle or the stomach.',
      ),
      RedFlag(
        code: 'chestPain.exertion',
        question:
            'Does it come on with effort — walking or stairs — and ease '
            'when you rest?',
        level: TriageLevel.urgent,
        reason:
            'Pain that follows effort and settles with rest is the pattern '
            'of angina, and needs assessing before your next exertion.',
      ),
      RedFlag(
        code: 'chestPain.pleuritic',
        question: 'Did it start suddenly and hurt more when you breathe in?',
        level: TriageLevel.urgent,
        reason:
            'Sudden pain that is worse on breathing in can come from the '
            'lung rather than the heart, including a clot.',
      ),
    ],
    escalations: <RiskEscalation>[
      RiskEscalation(
        factor: HealthRiskFactor.heartDisease,
        level: TriageLevel.emergency,
        reason:
            'You already have a heart condition, so new chest pain is '
            'treated as a heart problem until a doctor says otherwise.',
      ),
    ],
    actions: <String>[
      'Stop what you are doing and sit down while you wait for help.',
      'If a doctor has prescribed you a GTN spray or tablet for angina, '
          'use it as you were told.',
    ],
    watchFor: <String>[
      'The pain returns, lasts longer, or comes with sweating or '
          'breathlessness.',
    ],
  ),

  Symptom.breathlessness: SymptomGuidance(
    baseline: TriageLevel.urgent,
    redFlags: <RedFlag>[
      RedFlag(
        code: 'breathlessness.sentences',
        question: 'Are you too breathless to speak a full sentence?',
        level: TriageLevel.emergency,
        reason:
            'Not being able to finish a sentence means the effort of '
            'breathing is already very high.',
      ),
      RedFlag(
        code: 'breathlessness.sudden',
        question: 'Did it come on suddenly, while you were at rest?',
        level: TriageLevel.emergency,
        reason:
            'Breathlessness that arrives suddenly out of nowhere can mean '
            'a clot on the lung or a collapsed lung.',
      ),
      RedFlag(
        code: 'breathlessness.blueLips',
        question: 'Are your lips, face or fingertips turning blue or grey?',
        level: TriageLevel.emergency,
        reason:
            'A change in colour means the blood is not carrying enough '
            'oxygen.',
      ),
      RedFlag(
        code: 'breathlessness.inhaler',
        question: 'Have you used your reliever inhaler without it helping?',
        level: TriageLevel.emergency,
        reason:
            'An attack that does not answer the reliever needs hospital '
            'treatment, not a second dose at home.',
      ),
      RedFlag(
        code: 'breathlessness.legSwelling',
        question: 'Is one of your legs swollen, warm or painful?',
        level: TriageLevel.emergency,
        reason:
            'A swollen leg with breathlessness suggests a clot that has '
            'travelled from the leg to the lung.',
      ),
    ],
    actions: <String>[
      'Sit upright rather than lying down, and loosen tight clothing.',
    ],
    watchFor: <String>[
      'Breathing gets harder, you cannot speak, or your lips change '
          'colour.',
    ],
  ),

  Symptom.cough: SymptomGuidance(
    baseline: TriageLevel.selfCare,
    redFlags: <RedFlag>[
      RedFlag(
        code: 'cough.blood',
        question: 'Are you coughing up blood?',
        level: TriageLevel.urgent,
        reason:
            'Blood in what you cough up always needs explaining, even when '
            'there is only a little.',
      ),
      RedFlag(
        code: 'cough.breathless',
        question: 'Are you breathless, or is your breathing fast?',
        level: TriageLevel.urgent,
        reason:
            'A cough with fast or laboured breathing can mean the '
            'infection has reached the lung.',
      ),
      RedFlag(
        code: 'cough.threeWeeks',
        question: 'Has the cough lasted more than three weeks?',
        level: TriageLevel.soon,
        reason:
            'A cough lasting beyond three weeks is worth a chest check, '
            'including a test for TB where it is common.',
      ),
      RedFlag(
        code: 'cough.weightLossSweats',
        question: 'Along with weight loss, night sweats or evening fevers?',
        level: TriageLevel.urgent,
        reason:
            'That combination is how tuberculosis often shows itself, and '
            'it is treatable once found.',
      ),
      RedFlag(
        code: 'cough.feverChestPain',
        question: 'With a fever and chest pain when you breathe?',
        level: TriageLevel.urgent,
        reason: 'This is the usual pattern of pneumonia.',
      ),
    ],
    escalations: <RiskEscalation>[
      RiskEscalation(
        factor: HealthRiskFactor.lungDisease,
        level: TriageLevel.soon,
        reason:
            'A new cough is often the first step of a flare-up when you '
            'have asthma or COPD.',
      ),
      RiskEscalation(
        factor: HealthRiskFactor.immunosuppressed,
        level: TriageLevel.urgent,
        reason:
            'Chest infections move faster when your immune system is '
            'suppressed.',
      ),
    ],
    selfCare: <SelfCareTip>[
      SelfCareTip('Warm drinks, and honey in warm water to soothe it.'),
      SelfCareTip('Steam from a bowl of hot water can loosen thick phlegm.'),
      SelfCareTip(
        'Paracetamol if you also feel achy or feverish.',
        guard: SelfCareGuard.paracetamol,
      ),
      SelfCareTip('Rest your voice and avoid smoke and dust.'),
    ],
    watchFor: <String>[
      'You cough up blood, become breathless, or the fever lasts beyond '
          'three days.',
    ],
  ),

  Symptom.soreThroat: SymptomGuidance(
    baseline: TriageLevel.selfCare,
    redFlags: <RedFlag>[
      RedFlag(
        code: 'throat.saliva',
        question: 'Are you unable to swallow your own saliva, or drooling?',
        level: TriageLevel.emergency,
        reason:
            'Not being able to swallow saliva means the airway is starting '
            'to narrow.',
      ),
      RedFlag(
        code: 'throat.breathing',
        question:
            'Any difficulty breathing, or a muffled voice as though you '
            'have a hot potato in your mouth?',
        level: TriageLevel.emergency,
        reason:
            'A muffled voice with a sore throat suggests swelling deep in '
            'the throat.',
      ),
      RedFlag(
        code: 'throat.oneSided',
        question:
            'Severe pain on one side, with difficulty opening your mouth?',
        level: TriageLevel.urgent,
        reason:
            'One-sided pain that stops the jaw opening can be an abscess '
            'beside the tonsil, which needs draining.',
      ),
      RedFlag(
        code: 'throat.rashFever',
        question: 'With a rash, or a fever above 38.5°C?',
        level: TriageLevel.urgent,
        reason:
            'A rash with a sore throat changes what is likely to be '
            'causing it.',
      ),
      RedFlag(
        code: 'throat.week',
        question: 'Has it lasted more than a week without improving?',
        level: TriageLevel.soon,
        reason:
            'Most sore throats settle within a week, so a longer one is '
            'worth looking at.',
      ),
    ],
    escalations: <RiskEscalation>[
      RiskEscalation(
        factor: HealthRiskFactor.immunosuppressed,
        level: TriageLevel.urgent,
        reason:
            'A sore throat can be the first sign of a low white cell count '
            'if you take chemotherapy or immune-suppressing medicine.',
      ),
    ],
    selfCare: <SelfCareTip>[
      SelfCareTip('Gargle with warm salt water a few times a day.'),
      SelfCareTip('Cold drinks or ice lollies numb it as well as anything.'),
      SelfCareTip(
        'Paracetamol for the pain.',
        guard: SelfCareGuard.paracetamol,
      ),
    ],
    watchFor: <String>[
      'Swallowing becomes difficult, you start drooling, or your breathing '
          'changes.',
    ],
  ),

  Symptom.palpitations: SymptomGuidance(
    baseline: TriageLevel.soon,
    redFlags: <RedFlag>[
      RedFlag(
        code: 'palpitations.faint',
        question: 'Have you fainted, or nearly fainted, with it?',
        level: TriageLevel.emergency,
        reason:
            'Fainting with a racing heart suggests the heart is not '
            'pumping enough blood while it races.',
      ),
      RedFlag(
        code: 'palpitations.chestPain',
        question: 'Is there chest pain or breathlessness with it?',
        level: TriageLevel.emergency,
        reason:
            'Chest pain alongside palpitations needs the heart looked at '
            'straight away.',
      ),
      RedFlag(
        code: 'palpitations.ongoing',
        question: 'Is it still going on now, after more than 30 minutes?',
        level: TriageLevel.urgent,
        reason:
            'A rhythm that will not settle should be recorded on an ECG '
            'while it is happening.',
      ),
      RedFlag(
        code: 'palpitations.irregular',
        question: 'Does the beat feel irregular rather than only fast?',
        level: TriageLevel.urgent,
        reason:
            'An irregular beat can be atrial fibrillation, which raises '
            'stroke risk and is very treatable once found.',
      ),
    ],
    escalations: <RiskEscalation>[
      RiskEscalation(
        factor: HealthRiskFactor.heartDisease,
        level: TriageLevel.urgent,
        reason:
            'A new rhythm matters more when you already have a heart '
            'condition.',
      ),
    ],
    selfCare: <SelfCareTip>[
      SelfCareTip('Cut back on caffeine, alcohol and nicotine for a while.'),
      SelfCareTip(
        'Note when it happens and what you were doing — that record is '
        'what a doctor will ask for.',
      ),
    ],
    watchFor: <String>[
      'You feel faint, get chest pain, or it lasts more than half an hour.',
    ],
  ),

  Symptom.headache: SymptomGuidance(
    baseline: TriageLevel.selfCare,
    redFlags: <RedFlag>[
      RedFlag(
        code: 'headache.thunderclap',
        question:
            'Did it reach its worst within a few minutes, and is it the '
            'worst headache of your life?',
        level: TriageLevel.emergency,
        reason:
            'A headache that peaks that fast can mean bleeding around the '
            'brain, and it is ruled out with a scan rather than by '
            'waiting.',
      ),
      RedFlag(
        code: 'headache.meningism',
        question: 'With a fever, a stiff neck, or discomfort in bright light?',
        level: TriageLevel.emergency,
        reason: 'Together these can mean meningitis.',
      ),
      RedFlag(
        code: 'headache.neurology',
        question:
            'With weakness, confusion, trouble speaking, or loss of '
            'vision?',
        level: TriageLevel.emergency,
        reason:
            'A headache with any change in how the brain is working needs '
            'emergency assessment.',
      ),
      RedFlag(
        code: 'headache.headInjury',
        question: 'Did it start after a blow to the head?',
        level: TriageLevel.urgent,
        reason:
            'A headache after a head injury needs checking for slow '
            'bleeding inside the skull.',
        emergencyWhen: <HealthRiskFactor>{HealthRiskFactor.bleedingRisk},
      ),
      RedFlag(
        code: 'headache.worseLyingDown',
        question:
            'Is it worse when lying down or first thing in the morning, '
            'with vomiting?',
        level: TriageLevel.urgent,
        reason:
            'That pattern suggests raised pressure inside the head rather '
            'than an ordinary headache.',
      ),
    ],
    escalations: <RiskEscalation>[
      RiskEscalation(
        factor: HealthRiskFactor.pregnant,
        level: TriageLevel.urgent,
        reason:
            'A new headache in pregnancy needs a blood pressure and urine '
            'check the same day, because it can be the first sign of '
            'pre-eclampsia.',
      ),
      RiskEscalation(
        factor: HealthRiskFactor.olderAdult,
        level: TriageLevel.soon,
        reason:
            'A genuinely new type of headache after 65 is looked at more '
            'carefully than a familiar one.',
      ),
    ],
    selfCare: <SelfCareTip>[
      SelfCareTip('Drink water — mild dehydration is a common cause.'),
      SelfCareTip('Rest somewhere dark and quiet, away from screens.'),
      SelfCareTip(
        'Paracetamol at the full recommended dose, taken early.',
        guard: SelfCareGuard.paracetamol,
      ),
      SelfCareTip(
        'Ibuprofen if paracetamol alone is not enough.',
        guard: SelfCareGuard.nsaid,
      ),
      SelfCareTip(
        'Avoid painkillers on more than two days a week: taken often, they '
        'start causing headaches of their own.',
      ),
    ],
    watchFor: <String>[
      'It becomes sudden and severe, or comes with fever, a stiff neck, '
          'weakness or confusion.',
    ],
  ),

  Symptom.dizziness: SymptomGuidance(
    baseline: TriageLevel.soon,
    redFlags: <RedFlag>[
      RedFlag(
        code: 'dizziness.stroke',
        question: 'With weakness, numbness, double vision or slurred speech?',
        level: TriageLevel.emergency,
        reason:
            'Dizziness with any of these can be a stroke affecting the '
            'back of the brain.',
      ),
      RedFlag(
        code: 'dizziness.cardiac',
        question: 'With chest pain or a racing heart?',
        level: TriageLevel.emergency,
        reason:
            'This combination points at the heart rather than the inner '
            'ear.',
      ),
      RedFlag(
        code: 'dizziness.bleeding',
        question: 'With black stools, or vomiting blood?',
        level: TriageLevel.emergency,
        reason:
            'Feeling faint with either of those suggests you are losing '
            'blood internally.',
      ),
      RedFlag(
        code: 'dizziness.fell',
        question: 'Have you fainted or fallen because of it?',
        level: TriageLevel.urgent,
        reason:
            'Losing consciousness moves this beyond ordinary '
            'lightheadedness.',
      ),
      RedFlag(
        code: 'dizziness.postural',
        question: 'Does it happen only when you stand up quickly?',
        level: TriageLevel.selfCare,
        reason:
            'Dizziness only on standing is usually a blood pressure dip, '
            'often from dehydration or blood pressure medicine.',
      ),
    ],
    escalations: <RiskEscalation>[
      RiskEscalation(
        factor: HealthRiskFactor.bleedingRisk,
        level: TriageLevel.urgent,
        reason:
            'On a blood thinner, feeling faint can be the first sign of '
            'bleeding you cannot see.',
      ),
    ],
    selfCare: <SelfCareTip>[
      SelfCareTip('Stand up slowly, especially after sitting or lying.'),
      SelfCareTip(
        'Drink more water through the day.',
        guard: SelfCareGuard.extraFluids,
      ),
      SelfCareTip('Do not drive while this is happening.'),
    ],
    watchFor: <String>[
      'You faint, get chest pain, or notice weakness or speech trouble.',
    ],
  ),

  Symptom.weaknessOrNumbness: SymptomGuidance(
    baseline: TriageLevel.urgent,
    redFlags: <RedFlag>[
      RedFlag(
        code: 'weakness.faceArmSpeech',
        question:
            'Is one side of your face drooping, one arm weak, or your '
            'speech slurred?',
        level: TriageLevel.emergency,
        reason:
            'These are the classic signs of a stroke. Clot-busting '
            'treatment only works within a few hours of the start.',
      ),
      RedFlag(
        code: 'weakness.sudden',
        question: 'Did it come on suddenly, over seconds or minutes?',
        level: TriageLevel.emergency,
        reason:
            'Anything neurological that arrives that fast is treated as a '
            'stroke until a scan says otherwise.',
      ),
      RedFlag(
        code: 'weakness.vision',
        question: 'Sudden loss of vision in one eye?',
        level: TriageLevel.emergency,
        reason:
            'This can be a stroke affecting the eye, and it carries the '
            'same urgency.',
      ),
      RedFlag(
        code: 'weakness.legsBladder',
        question:
            'Weakness in both legs, or trouble controlling your bladder or '
            'bowels?',
        level: TriageLevel.emergency,
        reason:
            'Together these suggest pressure on the spinal cord, where '
            'delay costs permanent function.',
      ),
    ],
    escalations: <RiskEscalation>[
      RiskEscalation(
        factor: HealthRiskFactor.strokeHistory,
        level: TriageLevel.emergency,
        reason:
            'You have had a stroke or TIA before, which makes new weakness '
            'far more likely to be another one.',
      ),
    ],
    actions: <String>[
      'Write down the exact time the symptoms started. Hospital treatment '
          'decisions depend on it.',
      'Do not eat or drink anything until you have been assessed — '
          'swallowing may be affected.',
    ],
    watchFor: <String>[
      'Anything new appears on one side of the body, however briefly.',
    ],
  ),

  Symptom.fainting: SymptomGuidance(
    baseline: TriageLevel.urgent,
    redFlags: <RedFlag>[
      RedFlag(
        code: 'fainting.cardiac',
        question: 'With chest pain, or a racing or irregular heartbeat?',
        level: TriageLevel.emergency,
        reason:
            'Fainting from a heart rhythm problem can repeat without '
            'warning.',
      ),
      RedFlag(
        code: 'fainting.exertion',
        question: 'Did it happen during exercise or physical effort?',
        level: TriageLevel.emergency,
        reason:
            'Fainting during exertion, rather than after it, points at the '
            'heart and is always investigated.',
      ),
      RedFlag(
        code: 'fainting.stillUnwell',
        question: 'Do you still feel confused, weak or unwell now?',
        level: TriageLevel.emergency,
        reason:
            'Not recovering quickly after fainting suggests something '
            'beyond a simple faint.',
      ),
      RedFlag(
        code: 'fainting.headInjury',
        question: 'Did you hit your head when you fell?',
        level: TriageLevel.urgent,
        reason: 'A head injury from a fall needs its own assessment.',
        emergencyWhen: <HealthRiskFactor>{HealthRiskFactor.bleedingRisk},
      ),
      RedFlag(
        code: 'fainting.noWarning',
        question: 'Was there no warning at all before it happened?',
        level: TriageLevel.urgent,
        reason:
            'A faint with no build-up is more likely to come from the '
            'heart than from a drop in blood pressure.',
      ),
    ],
    escalations: <RiskEscalation>[
      RiskEscalation(
        factor: HealthRiskFactor.heartDisease,
        level: TriageLevel.emergency,
        reason:
            'Fainting with a known heart condition is assessed as a heart '
            'problem first.',
      ),
    ],
    actions: <String>['Do not drive until a doctor has told you it is safe.'],
    watchFor: <String>['It happens again, especially without warning.'],
  ),

  Symptom.eyeProblem: SymptomGuidance(
    baseline: TriageLevel.soon,
    redFlags: <RedFlag>[
      RedFlag(
        code: 'eye.visionLoss',
        question:
            'Sudden loss of vision, or a curtain or shadow across your '
            'sight?',
        level: TriageLevel.emergency,
        reason:
            'Sudden vision loss can come from a blocked vessel or a '
            'detaching retina, and sight is saved in hours, not days.',
      ),
      RedFlag(
        code: 'eye.glaucoma',
        question:
            'Severe eye pain with headache, vomiting, or halos around '
            'lights?',
        level: TriageLevel.emergency,
        reason:
            'That combination suggests pressure building inside the eye, '
            'which damages the nerve quickly.',
      ),
      RedFlag(
        code: 'eye.injury',
        question:
            'Was there a chemical splash, or did something strike the eye?',
        level: TriageLevel.emergency,
        reason: 'Chemical and penetrating injuries are sight-threatening.',
      ),
      RedFlag(
        code: 'eye.floaters',
        question: 'New flashes of light, or a sudden shower of floaters?',
        level: TriageLevel.urgent,
        reason:
            'These can be the warning before a retina detaches, when it is '
            'still easy to treat.',
      ),
      RedFlag(
        code: 'eye.contactLens',
        question: 'A painful red eye while wearing contact lenses?',
        level: TriageLevel.urgent,
        reason: 'An infection under a lens can reach the cornea within a day.',
      ),
    ],
    escalations: <RiskEscalation>[
      RiskEscalation(
        factor: HealthRiskFactor.diabetes,
        level: TriageLevel.urgent,
        reason:
            'Vision changes with diabetes are checked promptly, because '
            'the retina can be damaged before sight is noticeably lost.',
      ),
    ],
    actions: <String>[
      'For a chemical splash, rinse the eye with clean running water for '
          '15 minutes on the way to help.',
    ],
    selfCare: <SelfCareTip>[
      SelfCareTip('Stop wearing contact lenses until it has settled.'),
      SelfCareTip('Do not rub the eye, however much it itches.'),
      SelfCareTip('Clean the lids gently with cooled boiled water.'),
    ],
    watchFor: <String>[
      'Vision changes, the pain worsens, or the eye becomes sensitive to '
          'light.',
    ],
  ),
};
