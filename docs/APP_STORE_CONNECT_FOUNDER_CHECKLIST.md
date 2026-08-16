# APP_STORE_CONNECT_FOUNDER_CHECKLIST

Internal founder checklist. No uploads by engineering automation.

## Membership

- [ ] Apple Developer Program membership active
- [ ] Provide **DEVELOPMENT_TEAM** id to configure Xcode (`FOUNDER APPLE DEVELOPER TEAM REQUIRED` until then)
- [ ] App Store Connect access for the same team

## App record

- [ ] Create App Store Connect app with bundle id `com.taru.health`
- [ ] SKU / primary language
- [ ] Category (Health & Fitness or founder-chosen)
- [ ] Age rating answers (founder/legal — do not guess)

## Build identity

- [ ] Version / build from `mobile/pubspec.yaml` (`1.0.0+1` until deliberately bumped)
- [ ] Display name TARU (already set)
- [ ] **FINAL TARU APP ICON / BRAND MARK** (Flutter placeholders are a
  beta-quality blocker; do not invent a temporary medical/generic logo)
- [ ] Support URL
- [ ] Privacy Policy URL
- [ ] Marketing / review contact when required

## Privacy

- [ ] App Privacy questionnaire (Crashlytics, Auth, Firestore, Storage, notifications as applicable)
- [ ] Do not invent answers; use `docs/RELEASE_DATA_INVENTORY.md` as engineering input only

## TestFlight

- [ ] Internal / external TestFlight group
- [ ] Beta app description
- [ ] Beta feedback email
- [ ] Export compliance / encryption answers as required

## Do not

- Upload archives from this foundation phase
- Hardcode another developer's team id
- Fill legal/privacy questionnaires by guessing
