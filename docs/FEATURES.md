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
- **Firestore rules** are now in the repo (`firestore.rules`) and restrict every
  user document and subcollection to its owner.

## In progress / placeholders
- Reports (Phase 2)
- Routine (Phase 4)
- Progress (Phase 5)
- AI Assistant (Phase 3) — Home quick action shows “coming soon”
