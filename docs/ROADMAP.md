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
- **2d — Medications ✅** 56 common generic ingredients searchable by brand
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
- **3b — Drug interaction & dose safety checks ✅** Beyond the allergy-family
  check that already exists. Ingredients are mapped to pharmacological groups,
  and 30 rules are written between groups rather than between brands, so "a
  blood thinner with an anti-inflammatory" is one rule instead of a dozen
  pairs. 22 further cautions come from the profile rather than another
  medicine: ibuprofen with kidney disease, metformin against eGFR, ACE
  inhibitors in pregnancy, codeine while breastfeeding. Three severities only,
  because a list where everything is amber gets scrolled past. Warnings appear
  live while a medicine is being added, on the saved list, on Home when there
  is something to say, and on a Medicine safety screen. Nothing ever tells
  someone to stop a prescribed medicine.

## Phase 4 — Medical reports ✅
Upload PDF or image reports (lab, scan, prescription, discharge) to Firebase
Storage, with metadata in Firestore under `users/{uid}/reports`. Owner-only
Storage rules, 20 MB cap. List, open (image in-app, PDF externally), and
delete. Plain-language explanation of what a report means waits for Phase 5.

## Phase 5 — AI assistant (future — not started)
Report explanations and health chat, built on the health profile and routed
through the Phase 3 safety layer when ready:
- Triage runs first; the model never gets to talk someone out of an ambulance
- Possible causes and "see a doctor if…" thresholds, never firm diagnoses
- Visible disclaimer plus recorded consent

## Phase 6 — Daily routine (wider) ✅
Diet, exercise, sleep and mindfulness checklist on the Routine tab, on top of
the medicine reminders already in place. Eight default habits across four
pillars, organised morning / day / evening; per-habit on/off preferences;
done/skipped logging (`habitLogs`); optional evening lifestyle reminder;
Home “Today’s routine” summary; seven-day lifestyle summary with a light
per-pillar split.

## Phase 7 — Progress (logging review) ✅
Progress tab reviews the last 7 days of recorded medicine dose logs and
lifestyle habit logs as two separate sections. It reuses the existing
medicine and lifestyle adherence calculations, with no combined health
score. The UI uses simple summaries and compact activity indicators,
with optional short factual observations. Progress reports recorded
activity rather than clinical outcomes. Expected medicine doses are
estimated from the current medication schedule. No new Firestore schema,
charting library, streaks, badges, or AI are included.

## Phase 8 — Weight history foundation ✅
Adds intentional longitudinal weight tracking using a shared
measurements collection. Weight history becomes authoritative once
tracking begins, while health/profile.weightKg remains the mirrored
latest-value snapshot for existing TARU features. Users can add/delete
weight records, view neutral history, and see their latest recorded
weight from Progress. Existing profile weights are not automatically
fabricated into history. No blood pressure, HealthKit/Health Connect,
AI interpretation, charts, or weight-change judgments are included.

## Phase 9 — Report intelligence (source text) ✅
Makes stored medical reports easier to organize and, for supported
digital PDFs, extracts selectable text locally for user review before
saving. The original uploaded report remains the source artifact;
reviewed extracted text is stored as derived content with provenance and
is not treated as clinical truth. No OCR for scanned/image reports, AI
explanation, lab interpretation, cross-report trends, or diagnosis are
included.

## Phase 10 — Privacy & account health-data controls ✅
Gives users control over TARU health data before any cloud OCR or
grounded AI work. Ships a complete local ZIP export (share/save only; no
TARU cloud export copy), delete-health-data while retaining login, and
full account deletion. Destructive cleanup uses a trusted callable
(`purgeUserData` in `europe-west2`) with recent-auth enforcement, recursive
Firestore deletion, Storage prefix orphan cleanup, and a server-owned
`deletionInProgress` write guard enforced in client Firestore/Storage
rules. Auth identity is deleted last for account removal. The official
Delete User Data extension is a backstop after Auth deletion only. Export
is a snapshot assembled during the operation (not a database transaction);
purge is idempotent/retry-aware, not atomic. No OCR, AI, FHIR, HealthKit,
emailed export, or cloud export history.

## Phase 11 — Measurements / Progress maturity ✅
Matures longitudinal measurements without clinical interpretation.
Weight recording gains user-selectable `recordedAt`, a raw recent chart
(`fl_chart` 1.2.0), and mirror-safe backdating so `profile.weightKg`
tracks only the authoritative latest. Adds blood pressure as typed
sibling measurements (systolic/diastolic mmHg only), with dated add,
dual raw chart, history list, and delete. Progress gains a separate
Measurements section (latest weight + BP) that stays outside Last 7 Days
medicine/lifestyle adherence. Local export adds
`measurements/blood_pressure.json` alongside uncapped weight history.
No pulse, BP categories/alerts, weight goals, HealthKit/Health Connect,
OCR, AI, combined scores, or measurement edit-in-place. No Firebase
Functions/rules/index deploy required for this phase.

## Phase 12 — Local OCR for image reports and scanned PDFs ✅
Adds on-device Latin-script OCR for image reports and for PDFs whose
document-level selectable text is empty. Selectable digital PDF text
remains first choice (`method: pdf_text`); scanned-page OCR runs only
after an explicit “Read text from pages” action (`method: ocr`). Raw OCR
is transient; reviewed text saves to the existing
`derived/extracted.txt` sidecar after user confirmation. Same 256 KiB
UTF-8 reviewed-text cap. No cloud OCR, structured labs, reference
ranges, abnormal flags, extracted-body search, AI, handwriting
guarantee, non-Latin models, or per-page mixed digital+scanned merge.
Physically sideways images without usable orientation metadata may OCR
poorly; HEIC is supported via the platform codec with that limitation.
iOS currently uses CocoaPods with Flutter Swift Package Manager disabled
project-wide because the ML Kit Flutter bridge is not compatible with
TARU’s prior SwiftPM-only plugin setup — monitor future bridge/SPM
compatibility; this is not claimed as permanent architecture. No
Firebase rules/index/Functions deploy required for this phase.

## Trust & Launch Integrity ✅ (local implementation)
Aligns present-tense product claims and judgment-heavy presentation with
the shipped organizer + companion. Truthful onboarding/signup/Home/
completeness/reports copy; BMI number-only (no clinical categories);
neutral adherence presentation (Phase 7 math unchanged); working
Firebase Auth password reset; nonfunctional Google/Apple/phone stubs
removed from V1 UI; Help & support with medical boundary and conditional
privacy/terms/support links; VISION split into current vs long-term.
No AI, HealthKit/Health Connect, Crashlytics, localization, triage
clinical rewrite, Firebase rules/Functions changes, or redesign.

## Reliability Foundation (source integration)
Opt-in crash diagnostics via Firebase Crashlytics. Native automatic
collection defaults OFF. Device-local preference
`crash_diagnostics_enabled` (default false; not synced). No Firebase
Analytics, no intentional health-data attachment, no `setUserIdentifier`.
Dart reporting is sanitized (`UnexpectedFailure(<category>)`) and stops
immediately on opt-out. Account-root integrity is fail-closed: Auth
presence is not enough for MainShell; missing `users/{uid}` does not
auto-bootstrap. Crashlytics is **not** marked publicly enabled until
Firebase Console activation and a synthetic remote smoke are done
separately. Accessibility Phase B is not started.

### Public-release blockers (unresolved)
- **Founder:** first launch country; real support email
- **Legal:** Privacy Policy; Terms; jurisdiction/product disclaimer;
  Firebase/ML Kit/data-processing disclosure; Crashlytics disclosure
  before production use; store claim review
- **Clinical:** triage diagnosis-named guidance; self-care
  false-reassurance review; medicine Pause/Stop skim-risk wording;
  future clinical thresholds
- **Platform:** physical iPhone Phase 12 OCR smoke before
  TestFlight/public release
- **Accessibility Phase B:** project-wide semantics and text scaling
- **Crashlytics:** Firebase Console enablement and synthetic remote
  smoke (source integration only so far)

## Phase 5 — AI assistant (future)
Report explanations and health chat remain deferred until grounded
safety, consent, and evidence design are ready. Not started.
