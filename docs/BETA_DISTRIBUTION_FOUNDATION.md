# BETA_DISTRIBUTION_FOUNDATION

Engineering notes for the uncommitted `feature/beta-distribution-foundation`
work. Not a store upload guide.

## Android signing

- Release uses external `mobile/android/key.properties` + keystore
  (both gitignored). Template: `mobile/android/key.properties.example`.
- Hard invariant: release must **not** fall back to the debug keystore.
- Missing signing material → clear Gradle failure on
  `assembleRelease` / `bundleRelease`.
- Debug builds remain unaffected.
- Founder must create the real upload key later; disposable `/tmp`
  keystores are for pipeline proof only.

## Versioning

Source of truth: `mobile/pubspec.yaml` → currently `1.0.0+1`
(`versionName`/`CFBundleShortVersionString` = `1.0.0`,
`versionCode`/`CFBundleVersion` = `1`).

- Keep `1.0.0+1` until the first real store upload needs a new identity.
- Every uploaded Play / TestFlight build must use a **monotonically
  increasing** build number / `versionCode`.
- First actual uploaded beta may use build `1` if no store build already
  consumed that identity.
- No release automation framework yet.

## Size evidence (measured)

Universal release APK ≈ **170 MB** packages all ABIs.
Release AAB ≈ **143.5 MB** (Play upload / publishing artifact — not the
per-device download).

### bundletool `get-size total` (from the disposable-signed AAB)

Compressed download estimates:

| Spec | MIN (bytes) | MAX (bytes) | ≈ MB |
| --- | ---: | ---: | ---: |
| All configurations | 32,936,046 | 35,825,101 | ~31–34 |
| abi=arm64-v8a | 34,668,950 | 34,776,816 | ~33 |
| Device: arm64-v8a, en, density 420, sdk 34 | 34,775,616 | 34,775,616 | ~33 |

Play base-module compressed download limit is far above these figures →
**not a hard store-size blocker**. ~33 MB arm64 download is notable for
beta UX on slow networks but does **not** justify removing OCR/PDF.

Largest native contributors (per-ABI, from AAB/APK listing):

- `libpdf_oxide.so` (pdf_manipulator / Rust) — largest single libs
- `libflutter.so`
- `libmlkit_google_ocr_pipeline.so` + ML Kit OCR model assets (~1.5–2 MB)
- `libapp.so` (Dart AOT)
- Multi-ABI duplication in the universal APK/AAB contents
- AAB `BUNDLE-METADATA` native debug symbols (upload metadata; not the
  same as Play-delivered install size)

## iOS

- Bundle id `com.taru.health`, display name `TARU`
- Version `1.0.0` / build `1`
- `CODE_SIGN_STYLE = Automatic`, **no `DEVELOPMENT_TEAM`**
- No local codesigning identities found → archive/TestFlight blocked on
  founder Apple team membership/configuration

## FINAL TARU APP ICON / BRAND MARK

Android + iOS launcher icons are the **default Flutter logo**.

This remains an explicit **beta-quality blocker** before external testers.
Do not invent a temporary medical cross, hospital mark, ECG line, or
generic heart-with-plus. Design TARU’s brand mark deliberately in a
dedicated product-design phase.

## Beta build identifier in Help

Deferred: no existing dependency exposes version/build at runtime without
adding `package_info_plus` (or similar). Prefer adding later without
growing deps unless needed.
