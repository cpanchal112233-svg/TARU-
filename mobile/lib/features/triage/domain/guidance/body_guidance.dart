import '../symptom.dart';
import '../triage_level.dart';
import '../triage_rules.dart';

/// Guidance for the stomach, general and urinary symptoms.
///
/// Most of these are ordinary most of the time, so the baselines sit low and
/// the questions do the work. The exceptions are written in deliberately: a
/// burning chest that arrives with effort is treated as a heart attack rather
/// than acidity, and vomiting in someone with diabetes is treated as a warning
/// rather than a stomach bug.
const Map<Symptom, SymptomGuidance> bodyGuidance = <Symptom, SymptomGuidance>{
  Symptom.abdominalPain: SymptomGuidance(
    baseline: TriageLevel.soon,
    redFlags: <RedFlag>[
      RedFlag(
        code: 'abdomen.suddenSevere',
        question: 'Did it start suddenly and is it severe?',
        level: TriageLevel.emergency,
        reason:
            'Pain that arrives suddenly and severely can mean something has '
            'burst, twisted or blocked.',
      ),
      RedFlag(
        code: 'abdomen.rigid',
        question: 'Is your belly hard, or too tender to touch?',
        level: TriageLevel.emergency,
        reason:
            'A rigid, exquisitely tender abdomen suggests inflammation of the '
            'lining, which is a surgical emergency.',
      ),
      RedFlag(
        code: 'abdomen.bleeding',
        question: 'Vomiting blood, or passing black tarry stools?',
        level: TriageLevel.emergency,
        reason: 'Both mean bleeding somewhere in the stomach or gut.',
      ),
      RedFlag(
        code: 'abdomen.lowerRight',
        question: 'Has the pain settled into the lower right side?',
        level: TriageLevel.urgent,
        reason:
            'Pain that starts centrally and moves to the lower right is the '
            'usual story of appendicitis.',
      ),
      RedFlag(
        code: 'abdomen.feverJaundice',
        question: 'With a fever, or yellowing of the eyes or skin?',
        level: TriageLevel.urgent,
        reason:
            'Fever or jaundice with belly pain suggests infection in the gut, '
            'gallbladder or liver.',
      ),
      RedFlag(
        code: 'abdomen.noFluids',
        question: 'Are you unable to keep any fluids down?',
        level: TriageLevel.urgent,
        reason:
            'Not holding fluids down leads to dehydration quickly, and can '
            'mean a blockage.',
      ),
    ],
    escalations: <RiskEscalation>[
      RiskEscalation(
        factor: HealthRiskFactor.pregnant,
        level: TriageLevel.emergency,
        reason:
            'Belly pain in pregnancy is assessed in person now, because an '
            'ectopic pregnancy or a placental problem has to be ruled out.',
      ),
      RiskEscalation(
        factor: HealthRiskFactor.olderAdult,
        level: TriageLevel.urgent,
        reason:
            'Serious causes of belly pain often hurt less than expected after '
            '65, so the threshold for being seen is lower.',
      ),
    ],
    selfCare: <SelfCareTip>[
      SelfCareTip('Sip clear fluids rather than eating a full meal.'),
      SelfCareTip('Plain food when hungry — rice, toast, banana.'),
      SelfCareTip(
        'Paracetamol for the pain. Avoid ibuprofen and similar painkillers, '
        'which irritate the stomach lining.',
        guard: SelfCareGuard.paracetamol,
      ),
      SelfCareTip('No alcohol, and go easy on spicy and fatty food.'),
    ],
    watchFor: <String>[
      'The pain becomes severe or constant, you cannot keep fluids down, or '
          'you develop a fever.',
    ],
  ),

  Symptom.vomiting: SymptomGuidance(
    baseline: TriageLevel.soon,
    redFlags: <RedFlag>[
      RedFlag(
        code: 'vomiting.blood',
        question: 'Is there blood in it, or does it look like coffee grounds?',
        level: TriageLevel.emergency,
        reason: 'Either appearance means bleeding in the stomach or gullet.',
      ),
      RedFlag(
        code: 'vomiting.headacheNeck',
        question: 'With a severe headache or a stiff neck?',
        level: TriageLevel.emergency,
        reason:
            'Vomiting with these can mean raised pressure in the head or '
            'meningitis rather than a stomach problem.',
      ),
      RedFlag(
        code: 'vomiting.severePain',
        question: 'With severe stomach pain?',
        level: TriageLevel.urgent,
        reason:
            'Pain and vomiting together suggest a blockage or an inflamed '
            'organ.',
      ),
      RedFlag(
        code: 'vomiting.noFluids24',
        question:
            'Have you been unable to keep fluids down for more than 24 hours?',
        level: TriageLevel.urgent,
        reason:
            'Beyond a day without fluids, dehydration starts affecting the '
            'kidneys.',
      ),
      RedFlag(
        code: 'vomiting.dehydrated',
        question:
            'Passing much less urine than usual, or dizzy when you stand?',
        level: TriageLevel.urgent,
        reason: 'These are the signs that dehydration is already setting in.',
      ),
    ],
    escalations: <RiskEscalation>[
      RiskEscalation(
        factor: HealthRiskFactor.diabetes,
        level: TriageLevel.urgent,
        reason:
            'Vomiting with diabetes can tip into a dangerous state within '
            'hours, especially if you cannot eat or keep your medicine down. '
            'Never stop insulin because you are not eating.',
      ),
      RiskEscalation(
        factor: HealthRiskFactor.kidneyDisease,
        level: TriageLevel.urgent,
        reason:
            'Kidneys already under strain cope badly with fluid loss, and some '
            'of your medicines may need pausing while you are ill.',
      ),
      RiskEscalation(
        factor: HealthRiskFactor.olderAdult,
        level: TriageLevel.urgent,
        reason: 'Dehydration develops faster and shows itself later after 65.',
      ),
    ],
    selfCare: <SelfCareTip>[
      SelfCareTip(
        'Small sips of water or rehydration salts every few minutes rather '
        'than a glass at once.',
        guard: SelfCareGuard.extraFluids,
      ),
      SelfCareTip('Leave solid food for a few hours, then start plain.'),
      SelfCareTip('Rest, and avoid the smell of cooking if it sets you off.'),
    ],
    watchFor: <String>[
      'You see blood, cannot keep fluids down for a day, or stop passing '
          'urine.',
    ],
  ),

  Symptom.diarrhoea: SymptomGuidance(
    baseline: TriageLevel.selfCare,
    redFlags: <RedFlag>[
      RedFlag(
        code: 'diarrhoea.blackStool',
        question: 'Are the stools black and tarry?',
        level: TriageLevel.emergency,
        reason:
            'Black tarry stool is digested blood, which means bleeding higher '
            'up the gut.',
      ),
      RedFlag(
        code: 'diarrhoea.blood',
        question: 'Is there fresh blood or mucus in it?',
        level: TriageLevel.urgent,
        reason:
            'Blood or mucus points to an infection or inflammation that needs '
            'identifying rather than waiting out.',
      ),
      RedFlag(
        code: 'diarrhoea.dehydrated',
        question:
            'Passing much less urine, very dry mouth, or dizzy on standing?',
        level: TriageLevel.urgent,
        reason: 'These mean the fluid loss has outpaced what you are drinking.',
      ),
      RedFlag(
        code: 'diarrhoea.fever',
        question: 'With a fever above 38.5°C?',
        level: TriageLevel.urgent,
        reason:
            'A high fever alongside diarrhoea suggests a bacterial infection.',
      ),
      RedFlag(
        code: 'diarrhoea.week',
        question: 'Has it lasted more than a week?',
        level: TriageLevel.soon,
        reason:
            'Most infections settle within a week, so a longer spell needs '
            'stool tests.',
      ),
      RedFlag(
        code: 'diarrhoea.antibiotics',
        question: 'Did it start during or after a course of antibiotics?',
        level: TriageLevel.soon,
        reason:
            'Antibiotics can let a harmful gut bug take over, which is treated '
            'differently from ordinary food poisoning.',
      ),
    ],
    escalations: <RiskEscalation>[
      RiskEscalation(
        factor: HealthRiskFactor.kidneyDisease,
        level: TriageLevel.urgent,
        reason:
            'Fluid loss puts kidneys already under strain at real risk, and '
            'some medicines need pausing during it.',
      ),
      RiskEscalation(
        factor: HealthRiskFactor.immunosuppressed,
        level: TriageLevel.urgent,
        reason: 'Gut infections are harder to shake off and spread further.',
      ),
      RiskEscalation(
        factor: HealthRiskFactor.diabetes,
        level: TriageLevel.soon,
        reason:
            'Being ill unsettles blood sugar, so check yours more often than '
            'usual today.',
      ),
    ],
    selfCare: <SelfCareTip>[
      SelfCareTip(
        'Rehydration salts after each loose stool — plain water alone does not '
        'replace what you are losing.',
        guard: SelfCareGuard.extraFluids,
      ),
      SelfCareTip('Eat small plain meals as soon as you can face them.'),
      SelfCareTip(
        'Wash hands with soap after the toilet, and keep your towel separate.',
      ),
      SelfCareTip(
        'Avoid anti-diarrhoeal tablets if there is blood or a fever — they '
        'keep the infection in.',
      ),
    ],
    watchFor: <String>[
      'Blood appears, you stop passing urine, or it lasts beyond a week.',
    ],
  ),

  Symptom.acidity: SymptomGuidance(
    baseline: TriageLevel.selfCare,
    redFlags: <RedFlag>[
      RedFlag(
        code: 'acidity.exertion',
        question:
            'Does the burning come on with effort, like stairs or walking '
            'uphill, and ease when you stop?',
        level: TriageLevel.emergency,
        reason:
            'Burning brought on by effort is the pattern of angina, not '
            'indigestion. Heart pain is mistaken for acidity every day.',
      ),
      RedFlag(
        code: 'acidity.cardiac',
        question:
            'With sweating, breathlessness, or pain spreading to the arm or '
            'jaw?',
        level: TriageLevel.emergency,
        reason:
            'These belong to the heart rather than the stomach, whatever the '
            'burning feels like.',
      ),
      RedFlag(
        code: 'acidity.bleeding',
        question: 'Vomiting blood, or passing black tarry stools?',
        level: TriageLevel.emergency,
        reason: 'This suggests an ulcer that has started to bleed.',
      ),
      RedFlag(
        code: 'acidity.swallowing',
        question: 'Is food sticking, or is swallowing painful?',
        level: TriageLevel.soon,
        reason:
            'Trouble swallowing always needs a proper look at the gullet, and '
            'sooner rather than later.',
      ),
      RedFlag(
        code: 'acidity.weightLoss',
        question: 'With weight loss you did not plan?',
        level: TriageLevel.soon,
        reason:
            'Losing weight alongside long-standing reflux changes what needs '
            'ruling out.',
      ),
    ],
    escalations: <RiskEscalation>[
      RiskEscalation(
        factor: HealthRiskFactor.heartDisease,
        level: TriageLevel.urgent,
        reason:
            'Burning in the chest is much harder to tell apart from angina '
            'when you already have a heart condition.',
      ),
      RiskEscalation(
        factor: HealthRiskFactor.olderAdult,
        level: TriageLevel.soon,
        reason:
            'New indigestion after 55 is investigated rather than treated '
            'blind.',
      ),
    ],
    selfCare: <SelfCareTip>[
      SelfCareTip('Smaller meals, and nothing within three hours of bed.'),
      SelfCareTip('Raise the head of the bed rather than piling up pillows.'),
      SelfCareTip('Cut back on spicy and fried food, caffeine and alcohol.'),
      SelfCareTip(
        'A simple antacid settles most episodes. Leave four hours between an '
        'antacid and thyroid or iron tablets, which it stops being absorbed.',
      ),
    ],
    watchFor: <String>[
      'The burning comes with effort or sweating, or swallowing becomes '
          'difficult.',
    ],
  ),

  Symptom.fever: SymptomGuidance(
    baseline: TriageLevel.selfCare,
    redFlags: <RedFlag>[
      RedFlag(
        code: 'fever.rash',
        question:
            'Is there a rash that stays visible when you press a glass '
            'against it?',
        level: TriageLevel.emergency,
        reason:
            'A rash that does not fade under pressure, with a fever, can mean '
            'blood poisoning from meningococcal infection.',
      ),
      RedFlag(
        code: 'fever.meningism',
        question: 'With a stiff neck, or pain looking at bright light?',
        level: TriageLevel.emergency,
        reason: 'These point towards meningitis.',
      ),
      RedFlag(
        code: 'fever.confusion',
        question: 'Are you confused, very drowsy, or hard to rouse?',
        level: TriageLevel.emergency,
        reason:
            'Confusion with a fever is one of the clearest signs of sepsis.',
      ),
      RedFlag(
        code: 'fever.sepsis',
        question:
            'Cold hands and feet, mottled or grey skin, or shivering you '
            'cannot control?',
        level: TriageLevel.emergency,
        reason:
            'These are the circulation signs of sepsis, which is treated in '
            'hours.',
      ),
      RedFlag(
        code: 'fever.breathing',
        question: 'Breathing fast, or working hard to breathe?',
        level: TriageLevel.emergency,
        reason:
            'Fast breathing with a fever suggests the infection has reached '
            'the lungs or the bloodstream.',
      ),
      RedFlag(
        code: 'fever.threeDays',
        question: 'Has the fever lasted more than three days?',
        level: TriageLevel.urgent,
        reason:
            'Most viral fevers break within three days, so a longer one needs '
            'a cause found.',
      ),
      RedFlag(
        code: 'fever.travel',
        question:
            'Have you been somewhere with malaria or dengue in the last '
            'month?',
        level: TriageLevel.urgent,
        reason:
            'Both are treatable and both are missed when travel is not '
            'mentioned. Say where you went when you are seen.',
      ),
    ],
    escalations: <RiskEscalation>[
      RiskEscalation(
        factor: HealthRiskFactor.immunosuppressed,
        level: TriageLevel.urgent,
        reason:
            'A fever needs same-day assessment when your immune system is '
            'suppressed, even if you otherwise feel reasonably well.',
      ),
      RiskEscalation(
        factor: HealthRiskFactor.pregnant,
        level: TriageLevel.urgent,
        reason: 'A fever in pregnancy is checked the same day.',
      ),
      RiskEscalation(
        factor: HealthRiskFactor.olderAdult,
        level: TriageLevel.urgent,
        reason:
            'Infections after 65 can be advanced while the temperature stays '
            'modest.',
      ),
      RiskEscalation(
        factor: HealthRiskFactor.diabetes,
        level: TriageLevel.soon,
        reason:
            'Infection raises blood sugar, so check yours more often while '
            'this lasts.',
      ),
    ],
    selfCare: <SelfCareTip>[
      SelfCareTip(
        'Paracetamol brings the temperature and the aching down.',
        guard: SelfCareGuard.paracetamol,
      ),
      SelfCareTip(
        'Drink more than usual — clear urine is the sign you are keeping up.',
        guard: SelfCareGuard.extraFluids,
      ),
      SelfCareTip('Light clothing and a cool room rather than heavy blankets.'),
      SelfCareTip('Rest. A fever is the body working, and it takes energy.'),
    ],
    watchFor: <String>[
      'You develop a rash, a stiff neck, confusion, or fast breathing.',
      'The fever passes three days, or keeps climbing after paracetamol.',
    ],
  ),

  Symptom.fatigue: SymptomGuidance(
    baseline: TriageLevel.soon,
    redFlags: <RedFlag>[
      RedFlag(
        code: 'fatigue.cardiac',
        question: 'With chest pain or breathlessness?',
        level: TriageLevel.urgent,
        reason:
            'Tiredness with either of these can be the heart or the lungs '
            'rather than simple exhaustion.',
      ),
      RedFlag(
        code: 'fatigue.anaemia',
        question:
            'Are you unusually pale, or breathless on stairs you used to '
            'manage?',
        level: TriageLevel.urgent,
        reason:
            'That combination suggests anaemia, which is worth a blood test '
            'and is very treatable.',
      ),
      RedFlag(
        code: 'fatigue.bleeding',
        question: 'With black stools, or heavy periods?',
        level: TriageLevel.urgent,
        reason:
            'Slow blood loss is the commonest reason for tiredness that has a '
            'physical cause.',
      ),
      RedFlag(
        code: 'fatigue.weightLoss',
        question: 'With weight loss you did not plan, or night sweats?',
        level: TriageLevel.urgent,
        reason:
            'These change tiredness from a lifestyle question to a medical '
            'one.',
      ),
      RedFlag(
        code: 'fatigue.mood',
        question: 'Along with low mood, or losing interest in things?',
        level: TriageLevel.soon,
        reason:
            'Exhaustion is one of the most common physical faces of '
            'depression, and it responds to treatment.',
      ),
    ],
    escalations: <RiskEscalation>[
      RiskEscalation(
        factor: HealthRiskFactor.immunosuppressed,
        level: TriageLevel.urgent,
        reason:
            'New tiredness deserves a same-day look when your immune system is '
            'suppressed.',
      ),
    ],
    selfCare: <SelfCareTip>[
      SelfCareTip('Keep the same sleep and wake time, including weekends.'),
      SelfCareTip('Daylight and a short walk early in the day.'),
      SelfCareTip(
        'Go easy on alcohol and late caffeine, which fragment sleep.',
      ),
      SelfCareTip(
        'Ask for basic blood tests if it lasts more than a few weeks — thyroid, '
        'iron and blood count explain a good share of it.',
      ),
    ],
    watchFor: <String>[
      'Breathlessness, chest pain, weight loss or bleeding appear alongside '
          'it.',
    ],
  ),

  Symptom.swollenLegs: SymptomGuidance(
    baseline: TriageLevel.soon,
    redFlags: <RedFlag>[
      RedFlag(
        code: 'swelling.breathless',
        question: 'With breathlessness or chest pain?',
        level: TriageLevel.emergency,
        reason:
            'Leg swelling with breathlessness can mean a clot has reached the '
            'lung, or that the heart is struggling.',
      ),
      RedFlag(
        code: 'swelling.oneLeg',
        question: 'Is only one leg swollen, and is it warm or painful?',
        level: TriageLevel.urgent,
        reason:
            'One-sided swelling is how a deep vein clot presents, and it is '
            'treated the same day.',
      ),
      RedFlag(
        code: 'swelling.orthopnoea',
        question:
            'Do you wake at night breathless, or need more pillows than '
            'before?',
        level: TriageLevel.urgent,
        reason:
            'Needing to sit up to breathe is a sign of fluid backing up from '
            'the heart.',
      ),
      RedFlag(
        code: 'swelling.rapidWeight',
        question: 'Has your weight climbed quickly over a few days?',
        level: TriageLevel.urgent,
        reason:
            'Fast weight gain is retained fluid, and it is the earliest '
            'measurable sign of it.',
      ),
    ],
    escalations: <RiskEscalation>[
      RiskEscalation(
        factor: HealthRiskFactor.pregnant,
        level: TriageLevel.urgent,
        reason:
            'Swelling in pregnancy is checked alongside blood pressure for '
            'pre-eclampsia, particularly if your face or hands are puffy.',
      ),
      RiskEscalation(
        factor: HealthRiskFactor.heartDisease,
        level: TriageLevel.urgent,
        reason:
            'New swelling with a heart condition usually means the fluid '
            'balance needs adjusting.',
      ),
      RiskEscalation(
        factor: HealthRiskFactor.kidneyDisease,
        level: TriageLevel.urgent,
        reason:
            'Swelling can be the first sign that kidney function has '
            'slipped.',
      ),
      RiskEscalation(
        factor: HealthRiskFactor.liverDisease,
        level: TriageLevel.urgent,
        reason: 'Fluid retention with liver disease needs reviewing promptly.',
      ),
    ],
    selfCare: <SelfCareTip>[
      SelfCareTip('Raise your legs above hip level when sitting.'),
      SelfCareTip('Move your ankles regularly if you sit or stand all day.'),
      SelfCareTip('Cut down on added salt.'),
      SelfCareTip(
        'Do not stop or change a prescribed water tablet on your own — ask '
        'first.',
      ),
    ],
    watchFor: <String>[
      'One leg becomes painful, or you become breathless lying flat.',
    ],
  ),

  Symptom.bloodSugarSymptoms: SymptomGuidance(
    baseline: TriageLevel.soon,
    redFlags: <RedFlag>[
      RedFlag(
        code: 'sugar.ketoacidosis',
        question:
            'Drowsy or vomiting, breathing deep and fast, or a sweet smell on '
            'your breath?',
        level: TriageLevel.emergency,
        reason:
            'Together these suggest diabetic ketoacidosis, which needs '
            'hospital treatment and gets worse by the hour.',
      ),
      RedFlag(
        code: 'sugar.hypo',
        question:
            'Shaky, sweating and confused right now, or too drowsy to eat?',
        level: TriageLevel.emergency,
        reason:
            'A low blood sugar this severe needs treating this minute, and '
            'help if you cannot swallow safely.',
      ),
      RedFlag(
        code: 'sugar.highReadings',
        question: 'Are your readings staying above 300 mg/dL (16.7 mmol/L)?',
        level: TriageLevel.urgent,
        reason:
            'Sugars that will not come down need the treatment plan changing '
            'today.',
      ),
      RedFlag(
        code: 'sugar.sickDay',
        question:
            'Are you unable to eat, or to keep your usual diabetes medicine '
            'down?',
        level: TriageLevel.urgent,
        reason:
            'Illness raises blood sugar even without food, which is why '
            'insulin is never simply stopped when you cannot eat.',
      ),
      RedFlag(
        code: 'sugar.newSymptoms',
        question:
            'New heavy thirst, passing a lot of urine, or blurred vision?',
        level: TriageLevel.soon,
        reason:
            'This is how diabetes first announces itself, and a blood test '
            'settles it.',
      ),
    ],
    escalations: <RiskEscalation>[
      RiskEscalation(
        factor: HealthRiskFactor.diabetes,
        level: TriageLevel.urgent,
        reason:
            'You already have diabetes, so these symptoms mean the control has '
            'slipped rather than that something new has begun.',
      ),
    ],
    actions: <String>[
      'Check your blood sugar now if you have a meter, and write the number '
          'and time down.',
      'If you feel low, take 15g of fast sugar — three glucose tablets, or '
          'half a glass of juice — and check again in 15 minutes.',
    ],
    selfCare: <SelfCareTip>[
      SelfCareTip(
        'Sip water steadily; high sugar dehydrates you.',
        guard: SelfCareGuard.extraFluids,
      ),
      SelfCareTip('Test more often than usual while you feel unwell.'),
      SelfCareTip(
        'Keep taking your insulin even if you are eating very '
        'little.',
      ),
    ],
    watchFor: <String>[
      'You become drowsy, start vomiting, or your breathing changes.',
    ],
  ),

  Symptom.urinarySymptoms: SymptomGuidance(
    baseline: TriageLevel.soon,
    redFlags: <RedFlag>[
      RedFlag(
        code: 'urinary.retention',
        question:
            'Are you unable to pass urine at all, with a full painful '
            'bladder?',
        level: TriageLevel.emergency,
        reason:
            'A bladder that cannot empty needs draining, and waiting damages '
            'the kidneys.',
      ),
      RedFlag(
        code: 'urinary.kidney',
        question: 'With fever, chills, or pain in your back or side?',
        level: TriageLevel.urgent,
        reason:
            'This suggests the infection has reached the kidney, which needs '
            'stronger treatment than a simple bladder infection.',
      ),
      RedFlag(
        code: 'urinary.blood',
        question: 'Is there blood in the urine?',
        level: TriageLevel.urgent,
        reason:
            'Blood needs testing even when an infection explains the rest of '
            'it.',
      ),
      RedFlag(
        code: 'urinary.confusion',
        question: 'Any new confusion, or feeling very unwell in yourself?',
        level: TriageLevel.urgent,
        reason:
            'A urine infection that makes you feel systemically unwell may '
            'already be in the bloodstream.',
      ),
    ],
    escalations: <RiskEscalation>[
      RiskEscalation(
        factor: HealthRiskFactor.pregnant,
        level: TriageLevel.urgent,
        reason:
            'Urine infections in pregnancy are treated promptly, because they '
            'can bring on early labour.',
      ),
      RiskEscalation(
        factor: HealthRiskFactor.diabetes,
        level: TriageLevel.urgent,
        reason: 'Urine infections spread more readily with diabetes.',
      ),
      RiskEscalation(
        factor: HealthRiskFactor.kidneyDisease,
        level: TriageLevel.urgent,
        reason:
            'An infection reaching kidneys that are already impaired needs '
            'treating quickly.',
      ),
    ],
    selfCare: <SelfCareTip>[
      SelfCareTip(
        'Drink more water through the day to flush the bladder.',
        guard: SelfCareGuard.extraFluids,
      ),
      SelfCareTip('Pass urine often rather than holding on.'),
      SelfCareTip(
        'Paracetamol for the burning and discomfort.',
        guard: SelfCareGuard.paracetamol,
      ),
      SelfCareTip(
        'If it has not eased within two days, most infections need '
        'antibiotics — book a urine test rather than waiting it out.',
      ),
    ],
    watchFor: <String>[
      'Fever, back pain, blood in the urine, or being unable to pass any.',
    ],
  ),
};
