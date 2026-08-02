import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../emergency/presentation/pages/emergency_card_screen.dart';
import '../../../health_profile/application/health_profile_providers.dart';
import '../../../health_profile/domain/health_profile.dart';
import '../../domain/symptom.dart';
import '../../domain/triage_level.dart';
import '../../domain/triage_result.dart';
import '../widgets/triage_widgets.dart';

/// What TARU makes of it.
///
/// The order is deliberate: how soon, then what to do, then why. Someone
/// reading an emergency result should not have to scroll past reasoning to
/// find the instruction.
class TriageResultScreen extends ConsumerWidget {
  const TriageResultScreen({super.key, required this.result});

  final TriageResult result;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TriageLevelStyle style = TriageLevelStyle.of(result.level);

    final HealthProfile profile =
        ref.watch(healthProfileProvider).value ?? HealthProfile.empty;

    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: AppBar(
        title: const Text('What to do'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          _LevelBanner(level: result.level, style: style),

          if (result.symptoms.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              'Based on: ${result.symptoms.map((Symptom s) => s.label.toLowerCase()).join(', ')}',
              style: TextStyle(
                fontSize: 12.5,
                height: 1.4,
                color: Colors.grey.shade600,
              ),
            ),
          ],

          const SizedBox(height: 16),

          TriageSection(
            title: 'What to do now',
            icon: Icons.play_circle_outline,
            accent: style.colour,
            child: Column(
              children: [
                for (final String action in result.actions)
                  TriageBullet(
                    action,
                    icon: Icons.arrow_forward,
                    colour: style.colour,
                  ),
              ],
            ),
          ),

          if (result.level.isAtLeast(TriageLevel.urgent)) ...[
            const SizedBox(height: 12),
            _EmergencyActions(profile: profile),
          ],

          if (result.reasons.isNotEmpty) ...[
            const SizedBox(height: 12),
            TriageSection(
              title: 'Why TARU says this',
              icon: Icons.psychology_outlined,
              child: Column(
                children: [
                  for (final TriageReason reason in result.reasons)
                    TriageBullet(
                      reason.text,
                      icon: reason.source == TriageReasonSource.profile
                          ? Icons.person_outline
                          : Icons.flag_outlined,
                      colour: TriageLevelStyle.of(reason.level).colour,
                    ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),
            TriageSection(
              title: 'Why TARU says this',
              icon: Icons.psychology_outlined,
              child: const TriageBullet(
                'None of the warning signs you were asked about are present. '
                'That is reassuring, but it is not the same as being checked.',
              ),
            ),
          ],

          if (result.selfCare.isNotEmpty) ...[
            const SizedBox(height: 12),
            TriageSection(
              title: 'Looking after yourself',
              icon: Icons.spa_outlined,
              accent: const Color(0xff15803D),
              child: Column(
                children: [
                  for (final String tip in result.selfCare)
                    TriageBullet(
                      tip,
                      icon: Icons.check,
                      colour: const Color(0xff15803D),
                    ),
                ],
              ),
            ),
          ],

          if (result.cautions.isNotEmpty) ...[
            const SizedBox(height: 12),
            TriageSection(
              title: 'Written for your profile',
              icon: Icons.shield_outlined,
              accent: const Color(0xffC2410C),
              child: Column(
                children: [
                  for (final String caution in result.cautions)
                    TriageBullet(
                      caution,
                      icon: Icons.info_outline,
                      colour: const Color(0xffC2410C),
                    ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),

          TriageSection(
            title: 'Get help sooner if',
            icon: Icons.visibility_outlined,
            accent: const Color(0xffB3261E),
            child: Column(
              children: [
                for (final String line in result.watchFor)
                  TriageBullet(
                    line,
                    icon: Icons.warning_amber_rounded,
                    colour: const Color(0xffB3261E),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          const TriageDisclaimer(),

          const SizedBox(height: 20),

          TextButton(
            onPressed: () =>
                Navigator.of(context).popUntil((Route<void> r) => r.isFirst),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}

class _LevelBanner extends StatelessWidget {
  const _LevelBanner({required this.level, required this.style});

  final TriageLevel level;
  final TriageLevelStyle style;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: style.colour,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(style.icon, color: Colors.white, size: 24),
              const SizedBox(width: 10),
              Text(
                style.label.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            level.headline,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 23,
              height: 1.25,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            level.timeframe,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

/// The two things worth one tap when someone needs to be seen: the person they
/// asked TARU to call, and the card that answers the questions they will be
/// asked on arrival.
class _EmergencyActions extends StatelessWidget {
  const _EmergencyActions({required this.profile});

  final HealthProfile profile;

  Future<void> _call(BuildContext context, String phone) async {
    final Uri uri = Uri(scheme: 'tel', path: phone);

    try {
      final bool launched = await launchUrl(uri);

      if (launched || !context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not start a call to $phone.')),
      );
    } on Exception {
      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not start a call.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? phone = profile.emergencyContactPhone?.trim();
    final String name = profile.emergencyContactName?.trim() ?? 'your contact';

    return Column(
      children: [
        if (phone != null && phone.isNotEmpty)
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xffB3261E),
              ),
              onPressed: () => _call(context, phone),
              icon: const Icon(Icons.call),
              label: Text('Call $name'),
            ),
          ),
        if (phone != null && phone.isNotEmpty) const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xffB3261E),
              side: const BorderSide(color: Color(0xffB3261E)),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const EmergencyCardScreen(),
              ),
            ),
            icon: const Icon(Icons.emergency_outlined),
            label: const Text('Open emergency card'),
          ),
        ),
      ],
    );
  }
}
