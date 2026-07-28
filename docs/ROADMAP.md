# TARU Roadmap

Mobile-first: Android and iOS only. Web and desktop are out of scope.

## Phase 1 — App shell ✅
Bottom navigation with Home, Reports, Routine, Progress, and Profile tabs.

## Phase 1.5 — Session & state foundation ✅
`AuthGate` at the app root decides between onboarding, login, and the shell.
Riverpod + repositories keep auth and onboarding state out of the widgets.

## Phase 2 — Health profile
The clinical context every later feature reads from.

- **2a — Basics ✅** Date of birth, biological sex, height, weight, blood group,
  pregnancy status, emergency contact. Derives age and BMI. Metric and imperial
  input, always stored in cm/kg.
- **2b — Conditions ✅** 44 conditions grouped by body system, searchable by
  everyday words ("sugar", "BP"), with optional year diagnosed and how well
  controlled. Stored as stable codes, mappable to ICD-10 later.
- **2c — Allergies** Structured drug allergies so they can be checked in code,
  plus food and environmental.
- **2d — Medications** Name, dose, frequency. Feeds interaction checks,
  reminders, and adherence tracking.

## Phase 3 — Medical reports
Upload PDF/image reports to Firebase Storage + Firestore metadata.

## Phase 4 — AI assistant (with safety layer)
Report explanations and health chat, built on top of the health profile.
Safety is part of the feature, not an afterthought:
- Red-flag triage that escalates emergencies instead of advising
- Allergy and drug-interaction checks against the user's profile
- Possible causes and "see a doctor if…" thresholds, never firm diagnoses
- Visible disclaimer plus recorded consent

## Phase 5 — Daily routine
Medication reminders, diet, exercise, sleep, mindfulness checklist.

## Phase 6 — Progress & insights
Charts, streaks, and personalized health insights.
