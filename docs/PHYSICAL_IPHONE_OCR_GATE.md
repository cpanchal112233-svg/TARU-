# PHYSICAL_IPHONE_OCR_GATE

Phase 12 physical-iPhone OCR smoke remains **explicitly OPEN** before public
release / TestFlight reliance.

Do **not** treat iOS Simulator validation as a physical-device pass.
Do **not** add new OCR product code under this gate document.

## Required physical iPhone checks (synthetic documents only)

Use non-PHI synthetic fixtures (lab-style pages, scanned PDF pages, digital
PDFs with selectable text, HEIC photos of text).

- [ ] **Image OCR** — photograph/image report produces reviewable text on device
- [ ] **Scanned PDF OCR** — PDF without usable selectable text; explicit
      “Read text from pages” path
- [ ] **Digital PDF selectable-text path** — selectable text preferred over OCR
- [ ] **Reviewed save** — user confirms; reviewed text persists as derived
      content with provenance
- [ ] **Cancel / no persistence** — declining save leaves no reviewed body
- [ ] **Source / provenance** — UI makes original vs reviewed derived text clear
- [ ] **HEIC** — HEIC capture/import path exercises platform codec limits
- [ ] **Temp cleanup** — `taru_ocr_*` (or equivalent) temp dirs do not linger
      after success/cancel/error

## Status

**OPEN** until a founder/engineer records an actual physical-iPhone pass date
and outcome in release notes or this file.
