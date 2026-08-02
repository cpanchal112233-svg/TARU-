import 'package:flutter/foundation.dart';

import '../../safety/domain/health_risk.dart';
import 'triage_level.dart';

/// Risk factors and self-care guards are shared with the medicine interaction
/// checker, and re-exported here so the guidance tables only need one import.
export '../../safety/domain/health_risk.dart';

/// A yes/no question whose "yes" means this needs faster attention.
@immutable
class RedFlag {
  const RedFlag({
    required this.code,
    required this.question,
    required this.level,
    required this.reason,
    this.emergencyWhen = const <HealthRiskFactor>{},
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
  final Set<HealthRiskFactor> emergencyWhen;
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

  final HealthRiskFactor factor;
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
