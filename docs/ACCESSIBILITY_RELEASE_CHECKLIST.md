# ACCESSIBILITY_RELEASE_CHECKLIST

Internal release checklist for early external users.

Automated Accessibility Foundation source work is treated as **complete**.
This checklist tracks **manual runtime** validation still required before
public distribution.

Do **not** mark runtime validation complete unless it was actually performed
on a real device/emulator session for that platform.

## TalkBack (Android) — critical flows

Status: **OPEN** (manual runtime not claimed complete by this checklist)

Walk each flow with TalkBack enabled:

- [ ] Sign in / sign out
- [ ] Home → Emergency card
- [ ] Symptom check → result (including emergency-level presentation)
- [ ] Add / view medicine; medicine caution surfaces
- [ ] Routine dose / habit logging
- [ ] Reports list → detail → extract/OCR review save & cancel
- [ ] Progress measurements
- [ ] Evidence Brief create → section toggles → Share Preview
- [ ] Profile → Privacy & data → Your data in TARU
- [ ] Profile → Privacy & data → Export / Delete health / Delete account dialogs
- [ ] Profile → Help & support (medical boundary; feedback/support only if shown)

## VoiceOver (iOS) — critical flows

Status: **OPEN** (manual VoiceOver remains **OPEN**)

Same critical flows as TalkBack, on a physical iPhone preferred:

- [ ] Sign in / sign out
- [ ] Home → Emergency card
- [ ] Symptom check → result
- [ ] Medicines + caution surfaces
- [ ] Routine logging
- [ ] Reports + OCR/extract review
- [ ] Progress measurements
- [ ] Evidence Brief + Share Preview
- [ ] Your data in TARU
- [ ] Privacy destructive dialogs
- [ ] Help & support

## Large text (~200%) — critical flows

Status: **OPEN** for physical-device repetition; widget tests cover selected
screens only and do **not** replace device validation.

- [ ] Your data in TARU remains operable (scroll + control links)
- [ ] Help & support feedback/support tiles remain operable when configured
- [ ] Evidence Brief core controls remain operable
- [ ] Privacy & data actions remain operable
- [ ] Triage result primary actions remain reachable
- [ ] Charts/measurements remain understandable without color-only meaning

## Explicit non-claims

- Simulator/emulator passes are not a VoiceOver physical-device pass.
- Passing `flutter test` accessibility suites is not manual TalkBack/VoiceOver
  completion.
