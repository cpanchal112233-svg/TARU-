import 'package:flutter/foundation.dart';

import 'guidance/body_guidance.dart';
import 'guidance/chest_and_head_guidance.dart';
import 'guidance/skin_injury_and_mind_guidance.dart';
import 'symptom.dart';
import 'triage_level.dart';
import 'triage_rules.dart';

const Map<Symptom, SymptomGuidance> _guidance = <Symptom, SymptomGuidance>{
  ...chestAndHeadGuidance,
  ...bodyGuidance,
  ...skinInjuryAndMindGuidance,
};

/// Used when a symptom somehow has no rules written for it.
///
/// This should be impossible — a test asserts every symptom is covered — but
/// if it ever happens, TARU says "get this looked at" rather than inventing
/// reassurance it has no basis for.
const SymptomGuidance _fallback = SymptomGuidance(
  baseline: TriageLevel.urgent,
  redFlags: <RedFlag>[],
  actions: <String>[
    'TARU does not have specific guidance for this yet, so it is erring '
        'towards having it looked at.',
  ],
);

SymptomGuidance guidanceFor(Symptom symptom) {
  final SymptomGuidance? guidance = _guidance[symptom];

  assert(guidance != null, 'No triage guidance written for ${symptom.name}.');

  return guidance ?? _fallback;
}

/// Exposed so a test can prove nothing was left out.
@visibleForTesting
Set<Symptom> get symptomsWithGuidance => _guidance.keys.toSet();
