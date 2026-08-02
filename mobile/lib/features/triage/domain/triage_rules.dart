import 'package:flutter/foundation.dart';

import 'triage_level.dart';

/// Something in the health profile that changes how a symptom should be read.
///
/// These are deliberately coarse. "Kidney disease" covers a range a doctor
/// would separate, but the decision TARU makes with it — do not suggest
/// ibuprofen, take vomiting more seriously — is the same across that range.
enum TriageRiskFactor {
  pregnant('you are pregnant'),
  olderAdult('you are over 65'),
  child('you are under 16'),
  diabetes('you have diabetes'),
  heartDisease('you have a heart condition'),
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

  const TriageRiskFactor(this.description);

  /// Reads as the back half of a sentence: "…matters more because `this`".
  final String description;
}

/// A home remedy that is only safe for some people.
///
/// Self-care tips are tagged with the guard they depend on, and the engine
/// drops any tip whose guard is unsafe for this particular person. Suggesting
/// ibuprofen to someone on dialysis is the exact failure mode a health app
/// cannot have, and a free-text tip could not be checked.
enum SelfCareGuard { paracetamol, nsaid, extraFluids }

/// A yes/no question whose "yes" means this needs faster attention.
@immutable
class RedFlag {
  const RedFlag({
    required this.code,
    required this.question,
    required this.level,
    required this.reason,
    this.emergencyWhen = const <TriageRiskFactor>{},
  });

  /// Stable identifier stored with a saved check, so wording can change later.
  final String code;

  final String question;

  /// What a "yes" makes this, at minimum.
  final TriageLevel level;

  /// Plain-language explanation shown on the result. Never names a diagnosis
  /// as fact: "this can be a sign of" rather than "you have".
  final String reason;

  /// Risk factors that turn this particular "yes" into an emergency.
  ///
  /// A knock on the head is usually watch-and-wait, but on a blood thinner it
  /// is a hospital visit. That distinction belongs to the answer rather than
  /// to the symptom, so it cannot be expressed as a [RiskEscalation].
  final Set<TriageRiskFactor> emergencyWhen;
}

/// Raises the urgency of a symptom because of who this person is, not what
/// they answered.
@immutable
class RiskEscalation {
  const RiskEscalation({
    required this.factor,
    required this.level,
    required this.reason,
  });

  final TriageRiskFactor factor;
  final TriageLevel level;
  final String reason;
}

@immutable
class SelfCareTip {
  const SelfCareTip(this.text, {this.guard});

  final String text;

  /// Null for advice that is safe for everyone, such as resting or drinking
  /// water in normal amounts.
  final SelfCareGuard? guard;
}

/// Everything TARU knows about how to handle one symptom.
@immutable
class SymptomGuidance {
  const SymptomGuidance({
    required this.baseline,
    required this.redFlags,
    this.escalations = const <RiskEscalation>[],
    this.actions = const <String>[],
    this.selfCare = const <SelfCareTip>[],
    this.watchFor = const <String>[],
  });

  /// Where this symptom lands when every red flag is answered "no".
  ///
  /// Some symptoms have no safe floor: chest pain with no red flags is still
  /// worth a same-day opinion, because the questions cannot rule out a heart
  /// problem on their own.
  final TriageLevel baseline;

  final List<RedFlag> redFlags;
  final List<RiskEscalation> escalations;

  /// Steps that apply whatever the outcome, such as using an adrenaline pen or
  /// writing down the time symptoms started.
  final List<String> actions;

  final List<SelfCareTip> selfCare;

  /// Reasons to come back sooner, shown whatever the outcome.
  final List<String> watchFor;
}
