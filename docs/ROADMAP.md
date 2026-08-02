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
- **2c — Allergies ✅** 37 allergens across medicines, food and environmental
  triggers, each with reaction type and severity. Stored as stable codes so
  drug allergies can be checked in code. Anaphylaxis or a life-threatening
  severity flags the record as an emergency risk. "No known allergies" is
  stored explicitly, because it is a different answer from not asked yet.
- **2d — Medications ✅** 50 common generic ingredients searchable by brand
  ("Dolo", "Augmentin"), with form, dose, frequency, times of day, food timing,
  reason and start date. Free text is still accepted, because an unrecognised
  medicine on the list beats a missing one. Recognised ingredients carry the
  allergy family they belong to, so adding amoxicillin while carrying a
  penicillin allergy raises a warning immediately.
- **2e — Emergency card ✅** One screen with blood group, life-threatening
  allergies, conditions, current medicines and the emergency contact, in large
  type with a call button. Reachable in one tap from Home. Empty sections say
  "not recorded" rather than implying there is nothing to report.

Completeness across every part of the profile drives the Home card. Allergies
count as safety-critical: while unanswered the card turns amber instead of
showing tidy progress, since basics alone never make advice safe.

- **2f — Medication reminders & adherence ✅** Today's doses as a checklist on
  the Routine tab, derived from each medicine's frequency and times of day.
  Local notifications (one per time of day, listing what is due). Taken /
  skipped logging in Firestore. A 7-day adherence summary that counts from
  when tracking began, so a first-day user is not shown a misleadingly low
  percentage.

## Phase 3 — Safety layer
Built before the AI rather than after it, so there is something for a language
model to route through when it arrives.

- **3a — Symptom check & red-flag triage ✅** 26 symptoms, each with the
  warning-sign questions that separate "manage at home" from "go now". The
  outcome is one of four levels and it only ever escalates. The health profile
  feeds in: conditions, allergies, medicines, age and pregnancy all raise
  urgency where they should, and filter which home remedies are safe to
  suggest. Rule-based and offline. Unit tests cover the rules that matter —
  no de-escalation, no home remedies above "today", no ibuprofen for kidney
  disease.
- **3b — Drug interaction checks** Beyond the allergy-family check that
  already exists: pairs that should not be taken together, and doses that
  need adjusting for kidney function.

## Phase 4 — Medical reports
Upload PDF/image reports to Firebase Storage + Firestore metadata.

## Phase 5 — AI assistant
Report explanations and health chat, built on the health profile and routed
through the Phase 3 safety layer:
- Triage runs first; the model never gets to talk someone out of an ambulance
- Possible causes and "see a doctor if…" thresholds, never firm diagnoses
- Visible disclaimer plus recorded consent

## Phase 6 — Daily routine (wider)
Diet, exercise, sleep and mindfulness checklist, on top of the medicine
reminders already in place.

## Phase 7 — Progress & insights
Charts, streaks, and personalized health insights.
