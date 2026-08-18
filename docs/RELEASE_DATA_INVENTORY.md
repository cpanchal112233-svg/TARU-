# RELEASE_DATA_INVENTORY

Internal engineering inventory for qualified legal review.

This is **not** a Privacy Policy, Terms of Use, or compliance attestation.
It describes what the current TARU mobile + Firebase architecture stores and
does. No GDPR/HIPAA/compliance conclusions are made here.

Last aligned with: Early User Release Readiness work on `main` after Evidence
Brief V1.

## First-launch country

Founder has locked **India** as the intended first public-launch country.
Public distribution remains parked (private R&D). Product code stays
country-neutral in runtime behavior. Legal/store work is not approved by this
inventory.

## Account / authentication

- **Firebase Auth** email/password accounts.
- Identity fields used in-product: display name / email as shown in Profile.
- Password reset via Firebase Auth.
- No Google/Apple/phone sign-in in V1 UI.

## Health profile (Firestore under the signed-in user)

Self-reported:

- Basics (DOB, sex, height, weight snapshot, blood group, pregnancy status,
  emergency contact)
- Conditions
- Allergies
- Medicines / medication schedule fields used for reminders

## Health context (Firestore; private R&D)

Current snapshot documents under `users/{uid}/health/`:

- `dietaryProfile` — pattern, avoidances, dislikes, optional user-entered
  cultural constraints. Not allergy records.
- `lifestyle` — generally-true lifestyle context, not daily Routine logs

Collections:

- `users/{uid}/supplements/{id}`
- `users/{uid}/familyHistory/{id}`
- `users/{uid}/procedures/{id}`
- `users/{uid}/immunizations/{id}`
- `users/{uid}/healthGoals/{id}` — `desiredBy` is a user goal date
- `users/{uid}/careTeam/{id}` — user-owned reference; no clinician messaging

`HealthContextSnapshot` is a **read-only in-memory** aggregate. It is not
persisted. Existing conditions/allergies/medications are not duplicated.

## Measurements (Firestore)

- Weight history (manual; user-chosen `recordedAt`)
- Blood pressure (systolic/diastolic only; manual)

## Routine (Firestore + local device)

- Dose logs (taken / skipped style logging)
- Lifestyle / habit logs
- Habit on/off preferences
- **Local notifications** for medicine/lifestyle reminders (device-local
  scheduling; not a cloud push product)

## Reports (Firestore metadata + Cloud Storage originals)

- Report metadata (type, titles, dates, provenance fields for derived text)
- Original uploaded PDF/image in Cloud Storage
- Reviewed extracted text sidecar only after explicit user save
- Raw OCR / extraction preview is transient unless the user saves reviewed text
- On-device Latin-script OCR via ML Kit for images / scanned PDFs; selectable
  digital PDF text extraction is preferred when present
- OCR runs on-device; TARU does not operate a cloud OCR pipeline in this
  architecture

## Evidence Brief

- Generated on device from existing TARU records for a chosen period
- **No persistent Evidence Brief document** written to Firestore/Storage as a
  brief artifact
- Personal notes/questions for share are **ephemeral** (session / device UI
  state; not cloud-saved)
- Does not auto-include OCR/report body text

## Export

- Local ZIP assembled on device and shared/saved by the user
- TARU does not keep a cloud copy of the export archive
- TARU does not email exports

## Delete health data

- Removes TARU health information while retaining Auth login / name-email
  identity
- Server-assisted purge via trusted callable (`purgeUserData`, region
  `europe-west2`) with recent-auth enforcement
- Client writes blocked while server-owned `deletionInProgress` guard is set

## Delete account

- Purges health data then deletes Firebase Auth identity (Auth last)
- Official **Firebase Delete User Data** extension is a backstop after Auth
  deletion

## Crash diagnostics (Firebase Crashlytics)

- Opt-in from Privacy & data
- Preference stored in **SharedPreferences** (`crash_diagnostics_enabled`)
- **Default OFF**
- Native automatic collection default OFF in AndroidManifest / Info.plist
- No intentional health attachment; no `setUserIdentifier`
- External Crashlytics pipeline is configured, receiving, and synthetically
  verified; remaining public-release work is legal/store disclosure of
  retention and processing — not Console enablement

## SharedPreferences / local operational settings

Examples of device-local operational state (not a complete key dump):

- Crash diagnostics preference
- Onboarding / local UX flags as implemented
- Reminder-related local scheduling state coordinated with notifications

## Analytics

- **Firebase Analytics is not used** in the current product architecture.

## Public configuration (client constants)

`AppPublicLinks` may hold:

- `supportEmail`
- `feedbackEmail` / `feedbackUrl`
- `privacyPolicyUrl`
- `termsOfUseUrl`

Null/empty values **hide** related UI. Do not invent live-looking placeholders.

## Product feedback

- Optional Help & support action when feedback destination is configured
- Mailto uses a non-sensitive subject only (`TARU product feedback`)
- Does **not** auto-attach name, email, UID, health records, reports, OCR,
  Evidence Brief, routine logs, or crash logs

## Out of scope / not present in current architecture

- HealthKit / Health Connect sync
- AI assistant / cloud LLM features
- Evidence Delta (not started)
- Firebase Analytics
- Invented first-launch country

## Reviewer note

Ask engineering for current collection paths and callable names only as needed
for counsel review. Do not paste internal paths into user-facing legal text
unless counsel decides otherwise.
