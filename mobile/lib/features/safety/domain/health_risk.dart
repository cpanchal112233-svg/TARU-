/// Something in the health profile that changes how medical advice should be
/// given.
///
/// These are deliberately coarse. "Kidney disease" covers a range a doctor
/// would separate, but the decisions TARU makes with it — do not suggest
/// ibuprofen, take vomiting more seriously, flag metformin — are the same
/// across that range.
///
/// Shared by the symptom check and the medicine interaction checker, so the
/// mapping from a recorded condition to a safety decision lives in one place.
enum HealthRiskFactor {
  pregnant('you are pregnant'),
  breastfeeding('you are breastfeeding'),
  olderAdult('you are over 65'),
  child('you are under 16'),
  diabetes('you have diabetes'),
  heartDisease('you have a heart condition'),
  heartFailure('you have heart failure'),
  highBloodPressure('you have high blood pressure'),
  strokeHistory('you have had a stroke or TIA before'),
  kidneyDisease('you have kidney disease'),
  liverDisease('you have a liver condition'),
  lungDisease('you have asthma or COPD'),
  immunosuppressed('your immune system is suppressed'),
  bleedingRisk('you take a blood thinner'),
  anaphylaxisHistory('you have had a life-threatening allergic reaction'),
  stomachUlcer('you have had a stomach ulcer'),
  epilepsy('you have epilepsy');

  const HealthRiskFactor(this.description);

  /// Reads as the back half of a sentence: "…matters more because `this`".
  final String description;
}

/// An over-the-counter suggestion that is only safe for some people.
///
/// Advice is tagged with the guard it depends on, and anything whose guard is
/// unsafe for this person is dropped. Suggesting ibuprofen to someone on
/// dialysis is the exact failure a health app cannot have, and free text could
/// not be checked.
enum SelfCareGuard { paracetamol, nsaid, extraFluids }
