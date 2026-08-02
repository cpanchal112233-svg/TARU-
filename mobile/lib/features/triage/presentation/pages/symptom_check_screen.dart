import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../health_profile/presentation/widgets/health_form_widgets.dart';
import '../../domain/symptom.dart';
import '../../domain/triage_engine.dart';
import '../widgets/triage_widgets.dart';
import 'red_flag_questions_screen.dart';
import 'triage_result_screen.dart';

/// Where a symptom check starts: pick what is bothering you.
///
/// Selection is capped at three. Triage works by asking focused questions
/// about each complaint, and someone who ticks eight boxes gets a long
/// questionnaire and a muddy answer instead of a clear one.
class SymptomCheckScreen extends ConsumerStatefulWidget {
  const SymptomCheckScreen({super.key});

  static const int maxSymptoms = 3;

  @override
  ConsumerState<SymptomCheckScreen> createState() => _SymptomCheckScreenState();
}

class _SymptomCheckScreenState extends ConsumerState<SymptomCheckScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Set<Symptom> _selected = <Symptom>{};

  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggle(Symptom symptom) {
    setState(() {
      if (_selected.remove(symptom)) return;

      if (_selected.length >= SymptomCheckScreen.maxSymptoms) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text(
                'Pick the three that bother you most. You can run another '
                'check afterwards.',
              ),
            ),
          );

        return;
      }

      _selected.add(symptom);
    });
  }

  void _openEmergencyAdvice() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            TriageResultScreen(result: TriageEngine.selfReportedEmergency()),
      ),
    );
  }

  void _continue() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RedFlagQuestionsScreen(symptoms: _selected.toList()),
      ),
    );
  }

  List<Symptom> get _matches => Symptom.values
      .where((Symptom symptom) => symptom.matches(_query))
      .toList();

  @override
  Widget build(BuildContext context) {
    final List<Symptom> matches = _matches;
    final bool searching = _query.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: AppBar(
        title: const Text('Symptom check'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          TriageEmergencyBar(onTap: _openEmergencyAdvice),

          const SizedBox(height: 16),

          const HealthNote(
            icon: Icons.help_outline,
            text:
                'Tell TARU what you are feeling and it will ask a few '
                'questions about warning signs, then say how quickly you '
                'should be seen. It reads your conditions, allergies and '
                'medicines while it does.',
          ),

          const SizedBox(height: 16),

          TextField(
            controller: _searchController,
            onChanged: (String value) => setState(() => _query = value),
            decoration: InputDecoration(
              hintText: 'Search — "chest", "loose motion", "giddy"',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
          ),

          if (_selected.isNotEmpty) ...[
            const HealthSectionLabel('Checking'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final Symptom symptom in _selected)
                  Chip(
                    label: Text(symptom.label),
                    onDeleted: () => _toggle(symptom),
                    backgroundColor: Colors.white,
                    deleteIcon: const Icon(Icons.close, size: 17),
                  ),
              ],
            ),
          ],

          if (matches.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 32),
              child: Text(
                'Nothing matches "$_query". Try a simpler word, or pick the '
                'closest thing from the list.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, height: 1.5),
              ),
            )
          else if (searching)
            _SymptomGroup(
              title: 'Results',
              symptoms: matches,
              selected: _selected,
              onToggle: _toggle,
            )
          else ...[
            _SymptomGroup(
              title: 'Most common',
              symptoms: matches
                  .where((Symptom symptom) => symptom.isCommon)
                  .toList(),
              selected: _selected,
              onToggle: _toggle,
            ),
            for (final SymptomCategory category in SymptomCategory.values)
              _SymptomGroup(
                title: category.label,
                symptoms: matches
                    .where(
                      (Symptom symptom) =>
                          symptom.category == category && !symptom.isCommon,
                    )
                    .toList(),
                selected: _selected,
                onToggle: _toggle,
              ),
          ],

          const SizedBox(height: 24),

          const TriageDisclaimer(),
        ],
      ),
      bottomNavigationBar: _ContinueBar(
        count: _selected.length,
        onContinue: _selected.isEmpty ? null : _continue,
      ),
    );
  }
}

class _SymptomGroup extends StatelessWidget {
  const _SymptomGroup({
    required this.title,
    required this.symptoms,
    required this.selected,
    required this.onToggle,
  });

  final String title;
  final List<Symptom> symptoms;
  final Set<Symptom> selected;
  final ValueChanged<Symptom> onToggle;

  @override
  Widget build(BuildContext context) {
    if (symptoms.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HealthSectionLabel(title),
        for (final Symptom symptom in symptoms)
          _SymptomTile(
            symptom: symptom,
            isSelected: selected.contains(symptom),
            onTap: () => onToggle(symptom),
          ),
      ],
    );
  }
}

class _SymptomTile extends StatelessWidget {
  const _SymptomTile({
    required this.symptom,
    required this.isSelected,
    required this.onTap,
  });

  final Symptom symptom;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xff2E8BFF);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isSelected ? primary.withValues(alpha: 0.08) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(
                  isSelected
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  size: 21,
                  color: isSelected ? primary : Colors.grey.shade400,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    symptom.label,
                    style: TextStyle(
                      fontSize: 14.5,
                      height: 1.35,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: isSelected ? primary : Colors.grey.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ContinueBar extends StatelessWidget {
  const _ContinueBar({required this.count, required this.onContinue});

  final int count;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
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
      child: SizedBox(
        height: 52,
        width: double.infinity,
        child: FilledButton(
          onPressed: onContinue,
          child: Text(
            count == 0 ? 'Choose what you are feeling' : 'Continue with $count',
          ),
        ),
      ),
    );
  }
}
