# TARU Features

## Shipped
- Splash + onboarding (shown once per device)
- Email/password auth (login, signup, forgot password)
- Firestore user profile
- Profile: edit name, email, password reset, logout
- **Main app shell** with bottom navigation
- **Auth gate**: session persists across restarts, so returning users open
  straight into the app. Riverpod owns auth and onboarding state.
- **Health profile basics**: date of birth (age is derived, never stored),
  biological sex, height, weight, blood group, pregnancy status, emergency
  contact. Live BMI with a caveat where BMI is not clinically meaningful.
  Metric/imperial entry, stored in cm and kg. Completeness card on Home.
- **Medical conditions**: searchable checklist covering 44 conditions by body
  system, with everyday-language search and optional year diagnosed plus how
  well controlled. Stored as codes, not display text.
- **Allergies**: medicines, food and environmental triggers, each with the
  reactions it causes and how severe they are. Anaphylaxis or a life-threatening
  severity raises a red emergency banner, and later features will escalate
  rather than suggest home care. "No known allergies" is recorded explicitly.
- **Medications**: searchable by generic name or brand, with form, dose,
  frequency, times of day, food timing, reason and start date. Warns when a
  medicine belongs to an allergy family the user already reported, and points
  out when the chosen dose times do not add up to the stated frequency.
- **Emergency card**: blood group, severe allergies, conditions, current
  medicines and emergency contact on one large-type screen with a call button,
  one tap from Home.
- **Profile completeness** spans basics, conditions, allergies and medications.
  An unanswered allergy question turns the Home card amber instead of letting
  it read as complete.
- **Firestore rules** are now in the repo (`firestore.rules`) and restrict every
  user document and subcollection to its owner.

- **Medication reminders & adherence**: Routine tab turns each daily medicine
  into today's checklist (morning / afternoon / evening / bedtime). Tap to
  mark taken, Skip to mark skipped. Optional local reminders — one nudge per
  time of day, listing every dose due then. A short adherence summary covers
  the days since tracking began (not a padded empty week).

- **Symptom check with red-flag triage**: pick up to three symptoms from 26,
  searchable in everyday words, answer the warning-sign questions for each,
  and get one of four answers — emergency, today, in a few days, or manage at
  home. Rule-based and offline: no AI service is involved.

  What makes it more than a checklist is the profile. Chest pain becomes an
  emergency if a heart condition is on file; a knock on the head becomes one
  if you take warfarin; belly pain in pregnancy is never filed under "wait and
  see". Home remedies are filtered the same way, so ibuprofen is never
  suggested to someone with kidney disease, an ulcer or an NSAID allergy — and
  TARU says which suggestion it withheld and why.

  Two rules are enforced in code and covered by tests: the outcome only ever
  escalates, so one reassuring answer cannot cancel a worrying one; and home
  remedies vanish above "see a doctor today". Answering yes to an emergency
  question ends the questionnaire early rather than making someone finish it.

- **Medicine safety checks**: TARU reads the medicine list as a whole rather
  than one entry at a time. Ingredients are grouped pharmacologically, and the
  rules are written between groups — a blood thinner (including warfarin and
  the newer tablet anticoagulants) with any anti-inflammatory is a single rule,
  not nine. INR-shifting antibiotic rules stay warfarin-only, because DOACs do
  not use INR. Alongside those, cautions come from the profile:
  ibuprofen with kidney disease or heart failure, metformin against kidney
  function, ACE inhibitors or statins in pregnancy, codeine while
  breastfeeding, benzodiazepines in older adults.

  It also catches the quiet ones. Two entries that both contain paracetamol
  are flagged, because that is how people exceed the daily limit without
  noticing, and liver damage from it has no early symptoms. Omeprazole
  alongside clopidogrel is flagged with the specific fix — pantoprazole does
  the same job without blunting it.

  Three severities only: speak to a doctor, worth checking, space them apart.
  Overlapping rules collapse into one, so someone on the classic "triple
  whammy" reads a single clear warning rather than three partial ones. Every
  warning names the medicines from their own list, explains why in plain
  words, and ends with something to do. None of them tell anyone to stop a
  prescribed medicine — that is more dangerous than the interactions
  themselves.

  Warnings appear while a medicine is still being added, on the saved list, on
  Home when there is something to say, and in full on a Medicine safety
  screen. 36 unit tests cover both directions: the combinations that must fire
  and the ones that must stay quiet.

## In progress / placeholders
- Reports
- Progress
- AI health chat — the safety layer it must route through now exists
- Wider daily routine (diet, exercise, sleep, mindfulness)
