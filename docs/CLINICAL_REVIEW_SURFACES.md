# CLINICAL_REVIEW_SURFACES

Internal inventory of **existing** user-facing surfaces that need qualified
clinical review before broader public distribution.

This document does **not** rewrite clinical content.
Cursor / engineering has **not** performed clinical review.
No recommended “correct” clinical answers are asserted here unless noted as a
pure engineering/usability observation.

## Triage result presentation

| Field | Value |
| --- | --- |
| **FILE** | `mobile/lib/features/triage/presentation/pages/triage_result_screen.dart` |
| **SCREEN** | Symptom check result |
| **CURRENT PURPOSE** | Shows triage level, guidance text, escalation actions (including emergency card / call patterns). |
| **WHY REVIEW IS NEEDED** | Diagnosis-named and escalation wording can be read as clinical advice; emergency vs self-care framing must be clinically appropriate. |

## Triage guidance rules (chest / head / body and related)

| Field | Value |
| --- | --- |
| **FILE** | `mobile/lib/features/triage/domain/guidance/` (e.g. `chest_and_head_guidance.dart`, `body_guidance.dart`, and sibling guidance modules) |
| **SCREEN** | Content surfaced through triage result UI |
| **CURRENT PURPOSE** | Rule-based offline guidance strings tied to symptoms, red flags, and profile risk factors. |
| **WHY REVIEW IS NEEDED** | Named conditions, urgency language, and “manage at home” style self-care content carry false-reassurance and under/over-escalation risk. |

## Triage engine / levels

| Field | Value |
| --- | --- |
| **FILE** | `mobile/lib/features/triage/domain/` (engine + `triage_result.dart` and related) |
| **SCREEN** | Symptom check flow |
| **CURRENT PURPOSE** | Deterministic escalation-only level selection feeding UI. |
| **WHY REVIEW IS NEEDED** | Deterministic thresholds and escalation logic are clinically consequential even when presented as organizer guidance. |

## Medicine interaction & profile cautions

| Field | Value |
| --- | --- |
| **FILE** | `mobile/lib/features/interactions/domain/interaction_rules.dart` |
| **SCREEN** | Medicine add / list / Home warnings / Medicine safety surfaces that display these strings |
| **CURRENT PURPOSE** | Ingredient-group interaction and profile-based caution messages (e.g. illness, pregnancy, organ-risk contexts). |
| **WHY REVIEW IS NEEDED** | Includes Pause/Stop and “do not stop on your own” style medicine language that users may skim; clinical accuracy and skim-risk matter. |

## Medicine safety presentation

| Field | Value |
| --- | --- |
| **FILE** | `mobile/lib/features/interactions/presentation/pages/medicine_safety_screen.dart` (banner: `medicine_safety_banner.dart`; Home warning entry points) |
| **SCREEN** | Medicine safety / in-context warning lists |
| **CURRENT PURPOSE** | Surfaces live cautions while adding or reviewing medicines. |
| **WHY REVIEW IS NEEDED** | Users may treat warnings as prescribing advice; severity framing and call-to-action language need clinical review. |

## Help & support medical boundary

| Field | Value |
| --- | --- |
| **FILE** | `mobile/lib/features/profile/presentation/pages/help_support_screen.dart` |
| **SCREEN** | Help & support |
| **CURRENT PURPOSE** | States TARU organizes recorded information and does not diagnose or replace professional care. |
| **WHY REVIEW IS NEEDED** | Product/medical boundary claims should be consistent with clinical and legal review of the rest of the app. |

## Evidence Brief disclaimer posture

| Field | Value |
| --- | --- |
| **FILE** | `mobile/lib/features/evidence_brief/presentation/pages/evidence_brief_screen.dart` (and share preview) |
| **SCREEN** | Evidence Brief / Share Preview |
| **CURRENT PURPOSE** | Factual period summary from stored records; not a clinical assessment. |
| **WHY REVIEW IS NEEDED** | Confirm user-facing framing cannot be reasonably misread as diagnosis, prognosis, or care advice. |

## Notes for reviewers

- Do not treat automated tests or engineering inventories as clinical sign-off.
- Prefer reviewing **shipped strings** in the files above over marketing docs.
- Deterministic numeric/clinical thresholds that appear in guidance should be
  listed by the clinical reviewer during review; this inventory points to
  locations rather than enumerating every rule string.
