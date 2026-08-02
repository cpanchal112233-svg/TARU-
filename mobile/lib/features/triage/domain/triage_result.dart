import 'package:flutter/foundation.dart';

import 'symptom.dart';
import 'triage_level.dart';

/// Whether a line of reasoning came from what someone answered or from who
/// they are. Both are shown, because "because you take a blood thinner" is the
/// part people most often did not expect.
enum TriageReasonSource { answer, profile }

@immutable
class TriageReason {
  const TriageReason({
    required this.text,
    required this.level,
    required this.source,
  });

  final String text;
  final TriageLevel level;
  final TriageReasonSource source;
}

/// The outcome of one symptom check.
///
/// Everything shown on the result screen is here, so what the user reads is
/// exactly what a test can assert on.
@immutable
class TriageResult {
  const TriageResult({
    required this.level,
    required this.symptoms,
    required this.flaggedCodes,
    required this.reasons,
    required this.actions,
    required this.selfCare,
    required this.cautions,
    required this.watchFor,
  });

  final TriageLevel level;
  final List<Symptom> symptoms;

  /// Codes of the red flags answered "yes", kept so a saved check can be
  /// re-read later without storing the wording of the questions.
  final Set<String> flaggedCodes;

  final List<TriageReason> reasons;
  final List<String> actions;
  final List<String> selfCare;

  /// Things TARU deliberately did not suggest, and why.
  final List<String> cautions;

  final List<String> watchFor;

  bool get isEmergency => level == TriageLevel.emergency;

  List<TriageReason> get answerReasons => reasons
      .where(
        (TriageReason reason) => reason.source == TriageReasonSource.answer,
      )
      .toList();

  List<TriageReason> get profileReasons => reasons
      .where(
        (TriageReason reason) => reason.source == TriageReasonSource.profile,
      )
      .toList();
}
