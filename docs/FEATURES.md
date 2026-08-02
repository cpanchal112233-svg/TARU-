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

## In progress / placeholders
- Reports
- Progress
- AI Assistant — Home quick action shows “coming soon”
- Wider daily routine (diet, exercise, sleep, mindfulness)
