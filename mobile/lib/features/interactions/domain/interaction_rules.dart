import '../../safety/domain/health_risk.dart';
import 'medicine_group.dart';
import 'medicine_warning.dart';

/// Interactions between medicines the user takes.
///
/// Every rule is written to survive being read by a worried person at midnight:
/// what the problem is, why it happens, and what to actually do. None of them
/// tell anyone to stop a prescribed medicine — stopping a blood thinner or a
/// blood pressure tablet unsupervised is more dangerous than most interactions.
///
/// Scope is deliberately narrow. These are the combinations that are common,
/// consequential, and recognisable from an ingredient name alone.
const List<InteractionRule> interactionRules = <InteractionRule>[
  // ---------------------------------------------------------------- bleeding
  InteractionRule(
    code: 'anticoagulant+nsaid',
    groups: <MedicineGroup>[MedicineGroup.anticoagulant, MedicineGroup.nsaid],
    severity: MedicineWarningSeverity.serious,
    title: 'A blood thinner with an anti-inflammatory painkiller',
    detail:
        'Your blood thinner already slows clotting. Anti-inflammatory '
        'painkillers thin the blood further and strip the stomach lining at '
        'the same time, so the pair causes bleeds that neither causes alone.',
    action:
        'Ask a pharmacist about paracetamol for the pain instead. If a doctor '
        'has told you to take both, watch for black stools, unusual bruising, '
        'or blood in vomit or urine.',
  ),
  InteractionRule(
    code: 'anticoagulant+antiplatelet',
    groups: <MedicineGroup>[
      MedicineGroup.anticoagulant,
      MedicineGroup.antiplatelet,
    ],
    severity: MedicineWarningSeverity.serious,
    title: 'Two blood thinners together',
    detail:
        'These work on clotting in different ways, so taking both multiplies '
        'the bleeding risk. It is sometimes prescribed on purpose after a '
        'stent or a valve, but usually only for a set number of months.',
    action:
        'Do not stop either one yourself. Check with your doctor that this is '
        'still meant to be your combination, and for how long.',
  ),
  InteractionRule(
    code: 'ssri+bloodthinning',
    groups: <MedicineGroup>[MedicineGroup.ssri, MedicineGroup.bloodThinning],
    severity: MedicineWarningSeverity.caution,
    title: 'An antidepressant that adds to bleeding risk',
    detail:
        'SSRIs reduce how well platelets stick together. On their own that '
        'rarely matters; alongside a blood thinner or an anti-inflammatory it '
        'raises the chance of a stomach bleed.',
    action:
        'Worth mentioning at your next review. Tell a doctor promptly if you '
        'notice black stools, indigestion that will not settle, or bruising '
        'you cannot explain.',
  ),
  InteractionRule(
    code: 'nsaid+antiplatelet',
    groups: <MedicineGroup>[MedicineGroup.nsaid, MedicineGroup.antiplatelet],
    severity: MedicineWarningSeverity.caution,
    title: 'An anti-inflammatory alongside aspirin or clopidogrel',
    detail:
        'The combination roughly doubles the risk of a stomach bleed, and '
        'ibuprofen can also block the heart protection low-dose aspirin is '
        'meant to give.',
    action:
        'Use paracetamol where it works instead. If you need both, take the '
        'anti-inflammatory with food and ask whether you need a stomach '
        'protector.',
  ),
  InteractionRule(
    code: 'nsaid+corticosteroid',
    groups: <MedicineGroup>[MedicineGroup.nsaid, MedicineGroup.corticosteroid],
    severity: MedicineWarningSeverity.caution,
    title: 'An anti-inflammatory with steroid tablets',
    detail:
        'Both irritate the stomach lining, and together they make an ulcer '
        'considerably more likely — often without the warning of pain first.',
    action:
        'Take both with food and ask whether a stomach protector is sensible '
        'while the steroid course lasts.',
  ),

  // --------------------------------------------- antibiotic + INR (warfarin)
  InteractionRule(
    code: 'warfarin+sulfonamide',
    groups: <MedicineGroup>[MedicineGroup.warfarin, MedicineGroup.sulfonamide],
    severity: MedicineWarningSeverity.serious,
    title: 'This antibiotic can push your INR up sharply',
    detail:
        'Cotrimoxazole strongly boosts the effect of warfarin. INR can climb '
        'into the bleeding range within a few days of starting it.',
    action:
        'Tell whoever prescribed the antibiotic that you take warfarin, and '
        'ask for an INR check during the course.',
  ),
  InteractionRule(
    code: 'warfarin+nitroimidazole',
    groups: <MedicineGroup>[
      MedicineGroup.warfarin,
      MedicineGroup.nitroimidazole,
    ],
    severity: MedicineWarningSeverity.serious,
    title: 'Metronidazole raises the effect of warfarin',
    detail:
        'It slows the breakdown of warfarin, so the same dose thins your blood '
        'more than usual for as long as the course lasts.',
    action:
        'Ask for an INR check while you are on it, and watch for bleeding or '
        'bruising.',
  ),
  InteractionRule(
    code: 'warfarin+macrolide',
    groups: <MedicineGroup>[MedicineGroup.warfarin, MedicineGroup.macrolide],
    severity: MedicineWarningSeverity.caution,
    title: 'This antibiotic can unsettle your INR',
    detail: 'Azithromycin can increase the effect of warfarin over a few days.',
    action:
        'Mention the warfarin to your prescriber and ask about an INR check.',
  ),
  InteractionRule(
    code: 'warfarin+quinolone',
    groups: <MedicineGroup>[MedicineGroup.warfarin, MedicineGroup.quinolone],
    severity: MedicineWarningSeverity.caution,
    title: 'This antibiotic can unsettle your INR',
    detail:
        'Ciprofloxacin and levofloxacin can increase the effect of warfarin '
        'during the course.',
    action:
        'Mention the warfarin to your prescriber and ask about an INR check.',
  ),
  InteractionRule(
    code: 'warfarin+paracetamol',
    groups: <MedicineGroup>[MedicineGroup.warfarin, MedicineGroup.paracetamol],
    severity: MedicineWarningSeverity.caution,
    title: 'Regular paracetamol can nudge your INR up',
    detail:
        'Paracetamol is still the safest painkiller to pair with warfarin. But '
        'taking it at full dose every day for more than a few days can raise '
        'your INR.',
    action:
        'Occasional doses are fine. If you end up taking it daily for over a '
        'week, ask for an INR check.',
  ),

  // --------------------------------------------------- breathing and sedation
  InteractionRule(
    code: 'opioid+benzodiazepine',
    groups: <MedicineGroup>[MedicineGroup.opioid, MedicineGroup.benzodiazepine],
    severity: MedicineWarningSeverity.serious,
    title: 'Both of these slow your breathing',
    detail:
        'An opioid painkiller and a benzodiazepine together suppress breathing '
        'far more than either alone, especially at night and especially with '
        'alcohol. This combination is a common cause of accidental overdose.',
    action:
        'Check with your doctor that both are still needed at the same time. '
        'Avoid alcohol entirely, and do not take an extra dose of either to '
        'get to sleep.',
  ),

  // ----------------------------------------------------------- serotonin, QT
  InteractionRule(
    code: 'serotonergic+serotonergic',
    groups: <MedicineGroup>[MedicineGroup.serotonergic],
    minimumMedicines: 2,
    severity: MedicineWarningSeverity.serious,
    title: 'Two medicines that raise serotonin',
    detail:
        'Stacking them can cause serotonin syndrome — agitation, sweating, '
        'shivering, twitching muscles and a fast heartbeat, usually within '
        'hours of a new dose. Tramadol also makes seizures more likely at the '
        'same time.',
    action:
        'Check with a doctor or pharmacist that both are meant to be taken '
        'together. Seek urgent help if you feel agitated and shivery with a '
        'racing heart after a dose.',
  ),
  InteractionRule(
    code: 'qt+qt',
    groups: <MedicineGroup>[MedicineGroup.qtProlonging],
    minimumMedicines: 2,
    severity: MedicineWarningSeverity.caution,
    title: 'Two medicines that affect heart rhythm',
    detail:
        'Each of these slightly lengthens the heart\u2019s electrical reset '
        '(the QT interval). Two at once, or one with low potassium, can '
        'occasionally trigger a dangerous rhythm.',
    action:
        'Mention the pairing to your doctor, especially if you are also on '
        'water tablets or have had a rhythm problem before. Get checked if you '
        'faint or feel your heart flutter.',
  ),

  // ---------------------------------------------------------- kidneys and BP
  InteractionRule(
    code: 'triple-whammy',
    groups: <MedicineGroup>[
      MedicineGroup.aceInhibitorOrArb,
      MedicineGroup.diuretic,
      MedicineGroup.nsaid,
    ],
    supersedes: <String>['nsaid+ace', 'nsaid+diuretic'],
    severity: MedicineWarningSeverity.serious,
    title: 'These three together can injure the kidneys',
    detail:
        'A blood pressure medicine, a water tablet and an anti-inflammatory '
        'attack kidney blood flow from three directions at once. Clinicians '
        'call it the triple whammy; it is a well known cause of sudden kidney '
        'injury, particularly during a bout of vomiting or diarrhoea.',
    action:
        'Drop the anti-inflammatory if you can — paracetamol is the safer '
        'choice here. Speak to your doctor before taking it again.',
  ),
  InteractionRule(
    code: 'ace+ace',
    groups: <MedicineGroup>[MedicineGroup.aceInhibitorOrArb],
    minimumMedicines: 2,
    severity: MedicineWarningSeverity.serious,
    title: 'Two blood pressure medicines of the same kind',
    detail:
        'ACE inhibitors and ARBs work on the same pathway. Combining them adds '
        'little benefit but clearly raises the risk of kidney injury, high '
        'potassium and dizzy spells.',
    action:
        'Check with your doctor that both are intended — it is often a leftover '
        'from a change of prescription that never got removed.',
  ),
  InteractionRule(
    code: 'ace+sulfonamide',
    groups: <MedicineGroup>[
      MedicineGroup.aceInhibitorOrArb,
      MedicineGroup.sulfonamide,
    ],
    severity: MedicineWarningSeverity.caution,
    title: 'This combination can raise potassium',
    detail:
        'Both cotrimoxazole and your blood pressure medicine hold potassium in '
        'the body. Too much causes muscle weakness and, rarely, a dangerous '
        'heart rhythm.',
    action:
        'Fine for a short course in most people. Ask for a blood test if the '
        'course runs longer than a week or you already have kidney problems.',
  ),
  InteractionRule(
    code: 'ace+spironolactone',
    groups: <MedicineGroup>[
      MedicineGroup.aceInhibitorOrArb,
      MedicineGroup.potassiumSparingDiuretic,
    ],
    severity: MedicineWarningSeverity.caution,
    title: 'These two can push potassium too high',
    detail:
        'Spironolactone and ACE inhibitors or ARBs both hold potassium in the '
        'body. Together that is useful for heart failure, but only with blood '
        'tests to keep potassium in range.',
    action:
        'Keep your blood tests up to date. Tell a doctor if you get muscle '
        'weakness, a fluttering heart, or feel unusually tired.',
  ),
  InteractionRule(
    code: 'nsaid+ace',
    groups: <MedicineGroup>[
      MedicineGroup.nsaid,
      MedicineGroup.aceInhibitorOrArb,
    ],
    severity: MedicineWarningSeverity.caution,
    title: 'An anti-inflammatory works against your blood pressure medicine',
    detail:
        'Anti-inflammatories make the body hold on to salt and water, which '
        'pushes blood pressure back up and puts extra strain on the kidneys.',
    action:
        'Keep anti-inflammatory use short and occasional, and use paracetamol '
        'where it does the job.',
  ),
  InteractionRule(
    code: 'nsaid+diuretic',
    groups: <MedicineGroup>[MedicineGroup.nsaid, MedicineGroup.diuretic],
    severity: MedicineWarningSeverity.caution,
    title: 'An anti-inflammatory blunts your water tablet',
    detail:
        'It reduces how much fluid the water tablet clears, so ankles and '
        'breathlessness can creep back, and the kidneys take the strain.',
    action:
        'Prefer paracetamol. Tell your doctor if you gain weight quickly or '
        'your ankles swell.',
  ),

  // ------------------------------------------------------------- diabetes
  InteractionRule(
    code: 'betablocker+hypo',
    groups: <MedicineGroup>[
      MedicineGroup.betaBlocker,
      MedicineGroup.hypoglycaemiaRisk,
    ],
    severity: MedicineWarningSeverity.caution,
    title: 'A beta blocker can hide a low blood sugar',
    detail:
        'The shaking and pounding heart that normally warn you of a hypo are '
        'produced by the same signals a beta blocker blocks. Sweating usually '
        'still happens, but the early warning is quieter.',
    action:
        'Test rather than rely on how you feel, particularly before driving '
        'and at night.',
  ),
  InteractionRule(
    code: 'steroid+glucose',
    groups: <MedicineGroup>[
      MedicineGroup.corticosteroid,
      MedicineGroup.glucoseLowering,
    ],
    severity: MedicineWarningSeverity.caution,
    title: 'Steroids push blood sugar up',
    detail:
        'A steroid course usually raises blood sugar within a day or two, most '
        'noticeably in the afternoon. Your usual diabetes dose may not be '
        'enough while it lasts.',
    action:
        'Test more often during the course and ask your diabetes team whether '
        'your doses need adjusting up, then back down at the end.',
  ),

  // ----------------------------------------------------- duplication and dose
  InteractionRule(
    code: 'paracetamol+paracetamol',
    groups: <MedicineGroup>[MedicineGroup.paracetamol],
    minimumMedicines: 2,
    severity: MedicineWarningSeverity.serious,
    title: 'Two of your medicines contain paracetamol',
    detail:
        'Paracetamol hides inside many cold, flu and combination painkillers '
        'under different brand names. Taking two of them can quietly exceed '
        'the daily limit, and liver damage from that has no early symptoms.',
    action:
        'Add up the paracetamol across everything you take and keep the total '
        'at or under 4 g (usually eight 500 mg tablets) in 24 hours. Ask a '
        'pharmacist if you are unsure what is in a product.',
  ),
  InteractionRule(
    code: 'nsaid+nsaid',
    groups: <MedicineGroup>[MedicineGroup.nsaid],
    minimumMedicines: 2,
    severity: MedicineWarningSeverity.serious,
    title: 'Two anti-inflammatory painkillers at once',
    detail:
        'Taking two of these together does not relieve pain any better, but it '
        'does double the risk of a stomach bleed and of kidney strain.',
    action:
        'Stick to one at a time. If one is not controlling the pain, ask about '
        'adding paracetamol rather than a second anti-inflammatory.',
  ),
  InteractionRule(
    code: 'ppi+ppi',
    groups: <MedicineGroup>[MedicineGroup.protonPumpInhibitor],
    minimumMedicines: 2,
    severity: MedicineWarningSeverity.caution,
    title: 'Two acid-reducing medicines of the same kind',
    detail:
        'Omeprazole and pantoprazole do the same job. Two together is usually '
        'a leftover from a prescription change rather than a plan.',
    action: 'Check with your pharmacist which one you are meant to be taking.',
  ),
  InteractionRule(
    code: 'statin+statin',
    groups: <MedicineGroup>[MedicineGroup.statin],
    minimumMedicines: 2,
    severity: MedicineWarningSeverity.serious,
    title: 'Two statins together',
    detail:
        'Statins are not meant to be combined. Doubling up raises the risk of '
        'muscle damage, which can affect the kidneys.',
    action:
        'Check which one you should be on, and tell a doctor if you have '
        'unexplained muscle pain, tenderness or dark urine.',
  ),
  InteractionRule(
    code: 'clopidogrel+omeprazole',
    groups: <MedicineGroup>[
      MedicineGroup.clopidogrel,
      MedicineGroup.omeprazole,
    ],
    severity: MedicineWarningSeverity.serious,
    title: 'Omeprazole can weaken clopidogrel',
    detail:
        'Clopidogrel has to be activated by a liver enzyme that omeprazole '
        'blocks, so less of it works. That matters when it is protecting a '
        'stent or preventing a stroke.',
    action:
        'Pantoprazole does the same stomach job without this problem. Ask your '
        'doctor or pharmacist about switching — keep taking both until they '
        'advise you.',
  ),

  // ------------------------------------------------------------------ timing
  InteractionRule(
    code: 'levothyroxine+minerals',
    groups: <MedicineGroup>[
      MedicineGroup.levothyroxine,
      MedicineGroup.mineralSupplement,
    ],
    severity: MedicineWarningSeverity.timing,
    title: 'Iron and calcium block your thyroid tablet',
    detail:
        'They bind to levothyroxine in the gut, so much less of it is '
        'absorbed. Taken together every day, this is enough to make a correct '
        'dose look like it is not working.',
    action:
        'Take levothyroxine on an empty stomach first thing, and leave at '
        'least four hours before the iron or calcium.',
  ),
  InteractionRule(
    code: 'levothyroxine+acidreducer',
    groups: <MedicineGroup>[
      MedicineGroup.levothyroxine,
      MedicineGroup.acidReducer,
    ],
    severity: MedicineWarningSeverity.caution,
    title: 'Acid-reducing medicines lower thyroid absorption',
    detail:
        'Levothyroxine needs stomach acid to dissolve properly, so a regular '
        'acid reducer can leave your thyroid levels lower than the dose '
        'suggests.',
    action:
        'Keep the timing consistent day to day, and ask for a thyroid blood '
        'test if you started or stopped the acid reducer recently.',
  ),
  InteractionRule(
    code: 'antibiotic+minerals',
    groups: <MedicineGroup>[
      MedicineGroup.chelatedAntibiotic,
      MedicineGroup.mineralSupplement,
    ],
    severity: MedicineWarningSeverity.timing,
    title: 'Iron and calcium stop this antibiotic working',
    detail:
        'The mineral grabs the antibiotic in the gut and both pass straight '
        'through. Enough of the dose is lost that the infection may not clear.',
    action:
        'Take the antibiotic two hours before, or four to six hours after, the '
        'iron or calcium. Dairy counts too.',
  ),
];

/// Cautions that come from who you are rather than from another medicine:
/// a condition, a pregnancy, an age.
const List<ConditionCaution> conditionCautions = <ConditionCaution>[
  // ---------------------------------------------------- anti-inflammatories
  ConditionCaution(
    code: 'nsaid/kidney',
    group: MedicineGroup.nsaid,
    factor: HealthRiskFactor.kidneyDisease,
    severity: MedicineWarningSeverity.serious,
    title: 'Anti-inflammatories are hard on reduced kidneys',
    detail:
        'They narrow the vessels that keep blood flowing through the kidney '
        'filters. With function already reduced, even a few days of regular '
        'use can drop it further, sometimes permanently.',
    action:
        'Use paracetamol instead unless a kidney specialist has specifically '
        'approved this. Stop and get advice if you pass much less urine than '
        'usual.',
  ),
  ConditionCaution(
    code: 'nsaid/heart-failure',
    group: MedicineGroup.nsaid,
    factor: HealthRiskFactor.heartFailure,
    severity: MedicineWarningSeverity.serious,
    title: 'Anti-inflammatories make heart failure worse',
    detail:
        'They make the body retain salt and water, which is exactly what heart '
        'failure treatment is trying to remove. Hospital admissions follow '
        'from this often enough that they are generally avoided.',
    action:
        'Use paracetamol for pain. Get seen if you gain weight quickly, your '
        'ankles swell, or you become more breathless lying flat.',
  ),
  ConditionCaution(
    code: 'nsaid/ulcer',
    group: MedicineGroup.nsaid,
    factor: HealthRiskFactor.stomachUlcer,
    severity: MedicineWarningSeverity.serious,
    title: 'Anti-inflammatories can reopen an ulcer',
    detail:
        'They remove the prostaglandins that protect the stomach lining. With '
        'a history of ulcer or bleeding, the risk of another one is several '
        'times higher.',
    action:
        'Avoid these if you can. If one is unavoidable, it should come with a '
        'stomach protector — ask your doctor.',
  ),
  ConditionCaution(
    code: 'nsaid/pregnant',
    group: MedicineGroup.nsaid,
    factor: HealthRiskFactor.pregnant,
    severity: MedicineWarningSeverity.serious,
    title: 'Anti-inflammatories are avoided in pregnancy',
    detail:
        'From around 20 weeks they can affect the baby\u2019s kidneys and the '
        'circulation in the heart, and they are not recommended earlier '
        'either.',
    action:
        'Paracetamol at the lowest dose that works is the usual choice. Check '
        'with your midwife or doctor before taking anything else.',
  ),
  ConditionCaution(
    code: 'nsaid/hypertension',
    group: MedicineGroup.nsaid,
    factor: HealthRiskFactor.highBloodPressure,
    severity: MedicineWarningSeverity.caution,
    title: 'Anti-inflammatories raise blood pressure',
    detail:
        'Regular use adds a few points to blood pressure and works against '
        'most medicines used to lower it.',
    action: 'Keep courses short, and take paracetamol where it helps enough.',
  ),
  ConditionCaution(
    code: 'aspirin/child',
    group: MedicineGroup.aspirin,
    factor: HealthRiskFactor.child,
    severity: MedicineWarningSeverity.serious,
    title: 'Aspirin is not for children',
    detail:
        'In under-16s it is linked to Reye\u2019s syndrome, a rare but very '
        'serious swelling of the brain and liver that follows a viral illness.',
    action:
        'Use paracetamol or ibuprofen for a child instead, unless a specialist '
        'has prescribed aspirin for a specific heart condition.',
  ),

  // ------------------------------------------------------------------ liver
  ConditionCaution(
    code: 'paracetamol/liver',
    group: MedicineGroup.paracetamol,
    factor: HealthRiskFactor.liverDisease,
    severity: MedicineWarningSeverity.caution,
    title: 'Paracetamol needs a lower ceiling with liver disease',
    detail:
        'The liver clears paracetamol. With reduced function, or with a low '
        'body weight, the usual maximum can be too much.',
    action:
        'Ask your doctor what your daily limit should be — it is often '
        'reduced. Do not exceed it, and avoid alcohol.',
  ),
  ConditionCaution(
    code: 'statin/liver',
    group: MedicineGroup.statin,
    factor: HealthRiskFactor.liverDisease,
    severity: MedicineWarningSeverity.caution,
    title: 'Statins need liver monitoring',
    detail:
        'They are processed by the liver and can raise liver enzymes further.',
    action:
        'Keep up your blood tests, and report yellowing of the eyes or skin, '
        'or unusual tiredness.',
  ),

  // --------------------------------------------------------------- kidneys
  ConditionCaution(
    code: 'metformin/kidney',
    group: MedicineGroup.metformin,
    factor: HealthRiskFactor.kidneyDisease,
    severity: MedicineWarningSeverity.caution,
    title: 'Metformin dosing depends on your kidney function',
    detail:
        'Metformin leaves the body through the kidneys. When function drops, '
        'it builds up, and rarely that causes a serious acid build-up in the '
        'blood.',
    action:
        'Ask for a dose review against your latest eGFR. Pause metformin while '
        'you are vomiting, have diarrhoea, or cannot keep fluids down, and '
        'restart when you are eating and drinking normally.',
  ),
  ConditionCaution(
    code: 'ace/kidney',
    group: MedicineGroup.aceInhibitorOrArb,
    factor: HealthRiskFactor.kidneyDisease,
    severity: MedicineWarningSeverity.caution,
    title: 'This blood pressure medicine needs kidney bloods',
    detail:
        'ACE inhibitors and ARBs protect the kidneys long term, but they also '
        'change kidney blood flow and can raise potassium.',
    action:
        'Keep your blood tests up to date. Ask your doctor about pausing it '
        'during an illness with vomiting or diarrhoea — do not stop it '
        'routinely on your own.',
  ),
  ConditionCaution(
    code: 'hypo/kidney',
    group: MedicineGroup.hypoglycaemiaRisk,
    factor: HealthRiskFactor.kidneyDisease,
    severity: MedicineWarningSeverity.caution,
    title: 'Low blood sugars get more likely as kidneys decline',
    detail:
        'Insulin and sulfonylureas are cleared partly by the kidneys, so they '
        'last longer and hit harder when function is reduced.',
    action:
        'Test more often, especially overnight, and ask your diabetes team '
        'whether your dose should come down.',
  ),

  // -------------------------------------------------------------- pregnancy
  ConditionCaution(
    code: 'ace/pregnant',
    group: MedicineGroup.aceInhibitorOrArb,
    factor: HealthRiskFactor.pregnant,
    severity: MedicineWarningSeverity.serious,
    title: 'This blood pressure medicine is not used in pregnancy',
    detail:
        'ACE inhibitors and ARBs can seriously damage a developing baby\u2019s '
        'kidneys and skull, so they are switched for something safer as soon '
        'as a pregnancy is known.',
    action:
        'Do not just stop — uncontrolled blood pressure is dangerous too. '
        'Contact your doctor today about changing to a pregnancy-safe '
        'alternative.',
  ),
  ConditionCaution(
    code: 'statin/pregnant',
    group: MedicineGroup.statin,
    factor: HealthRiskFactor.pregnant,
    severity: MedicineWarningSeverity.serious,
    title: 'Statins are stopped in pregnancy',
    detail:
        'Cholesterol is needed for the baby\u2019s development, and a few '
        'months without a statin makes no difference to your long-term risk.',
    action: 'Tell your doctor you are pregnant and ask about stopping it.',
  ),
  ConditionCaution(
    code: 'anticoagulant/pregnant',
    group: MedicineGroup.anticoagulant,
    factor: HealthRiskFactor.pregnant,
    severity: MedicineWarningSeverity.serious,
    title: 'This blood thinner is not used in pregnancy',
    detail:
        'Warfarin and the newer tablet blood thinners can harm a developing '
        'baby. Pregnancy is usually managed with an injectable blood thinner '
        'instead.',
    action:
        'Contact your doctor urgently — do not stop it on your own, because '
        'the clot risk it is treating does not go away.',
  ),
  ConditionCaution(
    code: 'tetracycline/pregnant',
    group: MedicineGroup.tetracycline,
    factor: HealthRiskFactor.pregnant,
    severity: MedicineWarningSeverity.serious,
    title: 'This antibiotic is avoided in pregnancy',
    detail:
        'Doxycycline affects the baby\u2019s developing teeth and bones from '
        'the second trimester onwards.',
    action:
        'Tell your prescriber you are pregnant and ask for a different '
        'antibiotic.',
  ),
  ConditionCaution(
    code: 'tetracycline/child',
    group: MedicineGroup.tetracycline,
    factor: HealthRiskFactor.child,
    severity: MedicineWarningSeverity.serious,
    title: 'This antibiotic is not usually given to young children',
    detail:
        'Under about 12 it can permanently stain developing teeth, so another '
        'antibiotic is normally chosen.',
    action: 'Check the choice with the prescriber before giving it.',
  ),
  ConditionCaution(
    code: 'opioid/breastfeeding',
    group: MedicineGroup.opioid,
    factor: HealthRiskFactor.breastfeeding,
    severity: MedicineWarningSeverity.serious,
    title: 'Opioid painkillers pass into breast milk',
    detail:
        'Some people break codeine and tramadol down unusually fast, which can '
        'leave dangerous amounts in milk and make the baby very sleepy.',
    action:
        'Ask about paracetamol or ibuprofen instead. Seek help urgently if '
        'your baby is unusually floppy, hard to wake, or feeding poorly.',
  ),

  // ------------------------------------------------------------ older adults
  ConditionCaution(
    code: 'benzodiazepine/older',
    group: MedicineGroup.benzodiazepine,
    factor: HealthRiskFactor.olderAdult,
    severity: MedicineWarningSeverity.caution,
    title: 'Benzodiazepines cause falls in older adults',
    detail:
        'They stay in the body longer with age and add to unsteadiness and '
        'confusion, particularly on a trip to the bathroom at night.',
    action:
        'Ask about reviewing whether it is still needed, and about coming off '
        'it slowly if it has been going for months.',
  ),
  ConditionCaution(
    code: 'tricyclic/older',
    group: MedicineGroup.tricyclic,
    factor: HealthRiskFactor.olderAdult,
    severity: MedicineWarningSeverity.caution,
    title: 'Amitriptyline is harder to tolerate with age',
    detail:
        'It commonly causes a dry mouth, constipation, difficulty passing '
        'urine, dizziness on standing and daytime grogginess in older adults.',
    action:
        'Worth a review if any of those are bothering you — the dose used for '
        'nerve pain or sleep is often reducible.',
  ),

  // ------------------------------------------------------------------- other
  ConditionCaution(
    code: 'betablocker/lung',
    group: MedicineGroup.betaBlocker,
    factor: HealthRiskFactor.lungDisease,
    severity: MedicineWarningSeverity.caution,
    title: 'Beta blockers can tighten the airways',
    detail:
        'They are used carefully in asthma and COPD because they can worsen '
        'wheeze, though heart-selective ones are often tolerated fine.',
    action:
        'Tell your doctor if your inhaler is needed more often since starting '
        'it. Do not stop a beta blocker abruptly.',
  ),
  ConditionCaution(
    code: 'steroid/diabetes',
    group: MedicineGroup.corticosteroid,
    factor: HealthRiskFactor.diabetes,
    severity: MedicineWarningSeverity.caution,
    title: 'Steroids raise blood sugar in diabetes',
    detail:
        'Readings often climb within a day or two of starting a course, and '
        'settle again after it finishes.',
    action:
        'Test more often while the course lasts and ask your diabetes team '
        'whether doses need changing.',
  ),
];
