import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../safety/application/safety_providers.dart';
import '../../../safety/domain/safety_profile.dart';
import '../../domain/symptom.dart';
import '../../domain/symptom_guidance.dart';
import '../../domain/triage_engine.dart';
import '../../domain/triage_level.dart';
import '../../domain/triage_rules.dart';
import '../widgets/triage_widgets.dart';
import 'triage_result_screen.dart';

/// The warning-sign questions for the chosen symptoms.
///
/// Every question has to be answered before the result appears. Defaulting an
/// unanswered question to "no" would let someone skim past the one about
/// slurred speech, and that is the whole reason this screen exists.
class RedFlagQuestionsScreen extends ConsumerStatefulWidget {
  const RedFlagQuestionsScreen({super.key, required this.symptoms});

  final List<Symptom> symptoms;

  @override
  ConsumerState<RedFlagQuestionsScreen> createState() =>
      _RedFlagQuestionsScreenState();
}

class _RedFlagQuestionsScreenState
    extends ConsumerState<RedFlagQuestionsScreen> {
  final Map<String, bool> _answers = <String, bool>{};

  List<RedFlag> get _allFlags => <RedFlag>[
    for (final Symptom symptom in widget.symptoms)
      ...guidanceFor(symptom).redFlags,
  ];

  Set<String> get _flagged => _answers.entries
      .where((MapEntry<String, bool> entry) => entry.value)
      .map((MapEntry<String, bool> entry) => entry.key)
      .toSet();

  /// True once an answer on its own means emergency care, so the rest of the
  /// questionnaire can be skipped.
  bool _emergencyAlready(SafetyProfile profile) {
    return _allFlags.any((RedFlag flag) {
      if (_answers[flag.code] != true) return false;

      return flag.level == TriageLevel.emergency ||
          flag.emergencyWhen.any(profile.has);
    });
  }

  void _showResult(SafetyProfile profile) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => TriageResultScreen(
          result: TriageEngine.assess(
            symptoms: widget.symptoms,
            flaggedCodes: _flagged,
            profile: profile,
          ),
        ),
      ),
    );
  }

  void _openEmergencyAdvice() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            TriageResultScreen(result: TriageEngine.selfReportedEmergency()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final SafetyProfile profile = ref.watch(safetyProfileProvider);

    final List<RedFlag> flags = _allFlags;
    final int answered = _answers.length;
    final bool complete = answered == flags.length;
    final bool emergency = _emergencyAlready(profile);

    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: AppBar(
        title: const Text('A few warning signs'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          TriageEmergencyBar(onTap: _openEmergencyAdvice),

          const SizedBox(height: 16),

          _Progress(answered: answered, total: flags.length),

          const SizedBox(height: 8),

          for (final Symptom symptom in widget.symptoms)
            _SymptomQuestions(
              symptom: symptom,
              answers: _answers,
              onAnswer: (String code, bool value) =>
                  setState(() => _answers[code] = value),
            ),

          const SizedBox(height: 8),

          const TriageDisclaimer(),
        ],
      ),
      bottomNavigationBar: _QuestionsBar(
        emergency: emergency,
        complete: complete,
        remaining: flags.length - answered,
        onSubmit: () => _showResult(profile),
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.answered, required this.total});

  final int answered;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$answered of $total answered',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: total == 0 ? 1 : answered / total,
            minHeight: 6,
            backgroundColor: Colors.grey.shade200,
          ),
        ),
      ],
    );
  }
}

class _SymptomQuestions extends StatelessWidget {
  const _SymptomQuestions({
    required this.symptom,
    required this.answers,
    required this.onAnswer,
  });

  final Symptom symptom;
  final Map<String, bool> answers;
  final void Function(String code, bool value) onAnswer;

  @override
  Widget build(BuildContext context) {
    final List<RedFlag> flags = guidanceFor(symptom).redFlags;

    if (flags.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            symptom.label,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          for (final RedFlag flag in flags)
            _QuestionTile(
              flag: flag,
              answer: answers[flag.code],
              onAnswer: (bool value) => onAnswer(flag.code, value),
            ),
        ],
      ),
    );
  }
}

class _QuestionTile extends StatelessWidget {
  const _QuestionTile({
    required this.flag,
    required this.answer,
    required this.onAnswer,
  });

  final RedFlag flag;
  final bool? answer;
  final ValueChanged<bool> onAnswer;

  @override
  Widget build(BuildContext context) {
    final bool isYes = answer == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isYes ? const Color(0xffB3261E) : Colors.grey.shade200,
          width: isYes ? 1.4 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            flag.question,
            style: const TextStyle(fontSize: 14.5, height: 1.45),
          ),
          const SizedBox(height: 12),
          SegmentedButton<bool>(
            segments: const <ButtonSegment<bool>>[
              ButtonSegment<bool>(value: false, label: Text('No')),
              ButtonSegment<bool>(value: true, label: Text('Yes')),
            ],
            selected: answer == null ? <bool>{} : <bool>{answer!},
            emptySelectionAllowed: true,
            showSelectedIcon: false,
            style: SegmentedButton.styleFrom(
              visualDensity: VisualDensity.compact,
              selectedBackgroundColor: isYes
                  ? const Color(0xffB3261E).withValues(alpha: 0.12)
                  : null,
              selectedForegroundColor: isYes ? const Color(0xffB3261E) : null,
            ),
            onSelectionChanged: (Set<bool> selection) =>
                onAnswer(selection.first),
          ),
        ],
      ),
    );
  }
}

class _QuestionsBar extends StatelessWidget {
  const _QuestionsBar({
    required this.emergency,
    required this.complete,
    required this.remaining,
    required this.onSubmit,
  });

  final bool emergency;
  final bool complete;
  final int remaining;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    const Color red = Color(0xffB3261E);

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (emergency) ...[
            const Text(
              'One of your answers is a warning sign. You do not need to '
              'finish the rest.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: red,
                fontSize: 12.5,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
          ],
          SizedBox(
            width: double.infinity,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 52),
              child: FilledButton(
                style: emergency
                    ? FilledButton.styleFrom(backgroundColor: red)
                    : null,
                onPressed: emergency || complete ? onSubmit : null,
                child: Text(
                  emergency
                      ? 'See what to do now'
                      : complete
                      ? 'See what to do'
                      : '$remaining question${remaining == 1 ? '' : 's'} left',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
