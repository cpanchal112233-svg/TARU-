import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../health_profile/application/medications_providers.dart';
import '../../../health_profile/domain/medication.dart';
import '../../../health_profile/presentation/pages/allergies_screen.dart';
import '../../../health_profile/presentation/pages/conditions_screen.dart';
import '../../../health_profile/presentation/pages/medications_screen.dart';
import '../../../safety/application/safety_providers.dart';
import '../../../safety/domain/safety_profile.dart';
import '../../application/interaction_providers.dart';
import '../../domain/medicine_warning.dart';
import '../widgets/medicine_warning_widgets.dart';

/// Everything TARU has to say about the medicines the user takes together.
class MedicineSafetyScreen extends ConsumerWidget {
  const MedicineSafetyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final MedicationRecord record =
        ref.watch(medicationsProvider).value ?? MedicationRecord.empty;

    final List<MedicineWarning> warnings = ref.watch(medicineWarningsProvider);
    final SafetyProfile profile = ref.watch(safetyProfileProvider);
    final List<_ProfileGap> gaps = _gaps(profile);

    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: AppBar(
        title: const Text('Medicine safety'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: record.medications.isEmpty
          ? _EmptyState(hasAnswered: record.hasAnswered)
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              children: [
                _Header(count: record.medications.length),
                const SizedBox(height: 16),

                MedicineWarningsPanel(
                  warnings: warnings,
                  emptyMessage:
                      'Nothing on your list sets off one of TARU\u2019s '
                      'interaction checks.',
                ),

                if (gaps.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _ProfileGapCard(gaps: gaps),
                ],

                const SizedBox(height: 24),
                const MedicineSafetyDisclaimer(),
              ],
            ),
    );
  }

  /// What TARU still does not know that would change these checks.
  static List<_ProfileGap> _gaps(SafetyProfile profile) => <_ProfileGap>[
    if (profile.conditionsUnanswered)
      const _ProfileGap(
        text:
            'your conditions — kidney, liver, heart and stomach history change '
            'several of these warnings',
        screenBuilder: ConditionsScreen.new,
        buttonLabel: 'Add conditions',
      ),
    if (profile.allergiesUnanswered)
      const _ProfileGap(
        text:
            'your allergies — so TARU can spot a medicine from a family you '
            'react to',
        screenBuilder: AllergiesScreen.new,
        buttonLabel: 'Add allergies',
      ),
  ];
}

class _ProfileGap {
  const _ProfileGap({
    required this.text,
    required this.screenBuilder,
    required this.buttonLabel,
  });

  final String text;
  final Widget Function() screenBuilder;
  final String buttonLabel;
}

class _Header extends StatelessWidget {
  const _Header({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.medication_liquid_outlined,
                size: 18,
                color: Color(0xff2E8BFF),
              ),
              const SizedBox(width: 8),
              Text(
                'Checked $count ${count == 1 ? 'medicine' : 'medicines'}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'TARU looks at your medicines against each other, and against your '
            'health profile, for the interactions that come up most often.',
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileGapCard extends StatelessWidget {
  const _ProfileGapCard({required this.gaps});

  final List<_ProfileGap> gaps;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xffF1F5F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'These checks get sharper with more of your profile',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          for (final _ProfileGap gap in gaps) ...[
            Text(
              'TARU still needs ${gap.text}.',
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => gap.screenBuilder()),
              ),
              child: Text(gap.buttonLabel),
            ),
            if (gap != gaps.last) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasAnswered});

  final bool hasAnswered;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.medication_outlined,
              size: 56,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              hasAnswered
                  ? 'You have told TARU you take no medicines, so there is '
                        'nothing to check.'
                  : 'Add the medicines you take and TARU will check them '
                        'against each other and your health profile.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const MedicationsScreen(),
                ),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Manage medicines'),
            ),
          ],
        ),
      ),
    );
  }
}
