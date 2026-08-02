import 'symptom.dart';
import 'symptom_guidance.dart';
import 'triage_level.dart';
import '../../safety/domain/safety_profile.dart';
import 'triage_result.dart';
import 'triage_rules.dart';

/// Turns answered questions plus a health profile into one recommendation.
///
/// Two rules hold throughout, and every change here has to keep them true:
///
/// 1. Nothing lowers the outcome. The level only ever moves up, so a
///    reassuring answer can never cancel out a worrying one.
/// 2. Home remedies disappear above [TriageLevel.soon]. Someone who needs to
///    be seen today should not be reading about warm salt water.
class TriageEngine {
  const TriageEngine._();

  static TriageResult assess({
    required List<Symptom> symptoms,
    required Set<String> flaggedCodes,
    required SafetyProfile profile,
  }) {
    TriageLevel level = TriageLevel.selfCare;

    final List<TriageReason> reasons = <TriageReason>[];
    final List<String> symptomActions = <String>[];
    final List<SelfCareTip> tips = <SelfCareTip>[];
    final List<String> watchFor = <String>[];

    for (final Symptom symptom in symptoms) {
      final SymptomGuidance guidance = guidanceFor(symptom);

      level = level.orWorse(guidance.baseline);

      for (final RedFlag flag in guidance.redFlags) {
        if (!flaggedCodes.contains(flag.code)) continue;

        final bool escalatedByProfile = flag.emergencyWhen.any(profile.has);

        final TriageLevel flagLevel = escalatedByProfile
            ? TriageLevel.emergency
            : flag.level;

        level = level.orWorse(flagLevel);

        reasons.add(
          TriageReason(
            text: escalatedByProfile
                ? '${flag.reason} This counts for more given your health '
                      'profile.'
                : flag.reason,
            level: flagLevel,
            source: TriageReasonSource.answer,
          ),
        );
      }

      for (final RiskEscalation escalation in guidance.escalations) {
        if (!profile.has(escalation.factor)) continue;

        // A risk factor that does not raise this symptom above its own
        // baseline is not worth reporting: it would read as a warning while
        // changing nothing.
        if (escalation.level.order <= guidance.baseline.order) continue;

        level = level.orWorse(escalation.level);

        reasons.add(
          TriageReason(
            text: escalation.reason,
            level: escalation.level,
            source: TriageReasonSource.profile,
          ),
        );
      }

      symptomActions.addAll(guidance.actions);
      tips.addAll(guidance.selfCare);
      watchFor.addAll(guidance.watchFor);
    }

    final bool allowSelfCare = !level.isAtLeast(TriageLevel.urgent);

    final List<String> selfCare = <String>[];
    final List<String> cautions = <String>[];

    if (allowSelfCare) {
      for (final SelfCareTip tip in tips) {
        if (profile.allows(tip.guard)) {
          selfCare.add(tip.text);
          continue;
        }

        final String? reason = profile.blockedGuards[tip.guard];

        if (reason != null) cautions.add(reason);
      }

      if (selfCare.isNotEmpty && profile.allergiesUnanswered) {
        cautions.add(
          'TARU has not been told about your allergies yet, so check the label '
          'of anything you take and add them to your profile.',
        );
      }
    }

    return TriageResult(
      level: level,
      symptoms: symptoms,
      flaggedCodes: flaggedCodes,
      reasons: reasons,
      actions: _dedupe(<String>[..._actionsFor(level), ...symptomActions]),
      selfCare: _dedupe(selfCare),
      cautions: _dedupe(cautions),
      watchFor: _dedupe(<String>[...watchFor, ..._universalWatchFor]),
    );
  }

  /// For someone who says this is an emergency before answering anything.
  ///
  /// Their own read on the situation outranks the questionnaire, so it skips
  /// straight to the emergency advice rather than asking them to justify it.
  static TriageResult selfReportedEmergency() {
    return TriageResult(
      level: TriageLevel.emergency,
      symptoms: const <Symptom>[],
      flaggedCodes: const <String>{},
      reasons: const <TriageReason>[
        TriageReason(
          text:
              'You said this feels like an emergency. That judgement counts '
              'for more than any list of questions.',
          level: TriageLevel.emergency,
          source: TriageReasonSource.answer,
        ),
      ],
      actions: _actionsFor(TriageLevel.emergency),
      selfCare: const <String>[],
      cautions: const <String>[],
      watchFor: _universalWatchFor,
    );
  }

  static List<String> _actionsFor(TriageLevel level) {
    return switch (level) {
      TriageLevel.emergency => <String>[
        emergencyNumberHint,
        'Do not drive yourself. Ask someone to take you, or wait for an '
            'ambulance.',
        'Show the paramedic or doctor your emergency card so they see your '
            'allergies and medicines straight away.',
      ],
      TriageLevel.urgent => <String>[
        'Contact a doctor today — your own clinic, an urgent care centre, or '
            'a helpline if it is out of hours.',
        'Take a list of your medicines with you. Your emergency card has one.',
      ],
      TriageLevel.soon => <String>[
        'Book an appointment in the next few days.',
        'Write down when this started and what makes it better or worse. It '
            'is the first thing you will be asked.',
      ],
      TriageLevel.selfCare => <String>[
        'Keep an eye on it and see a doctor if it is not settling.',
      ],
    };
  }

  /// Shown whatever the symptom, because these are the signs that should send
  /// anyone back regardless of what they first came in with.
  static const List<String> _universalWatchFor = <String>[
    'Chest pain, sudden breathlessness, weakness on one side, confusion, or a '
        'rash that does not fade under pressure — treat any of these as an '
        'emergency.',
  ];

  static List<String> _dedupe(List<String> lines) {
    final Set<String> seen = <String>{};

    return lines.where((String line) => seen.add(line)).toList();
  }
}
