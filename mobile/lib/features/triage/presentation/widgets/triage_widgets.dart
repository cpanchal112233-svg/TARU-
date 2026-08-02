import 'package:flutter/material.dart';

import '../../domain/triage_level.dart';

/// Colour and icon for each outcome, in one place so the questions screen and
/// the result screen cannot drift apart on what "urgent" looks like.
class TriageLevelStyle {
  const TriageLevelStyle({
    required this.colour,
    required this.icon,
    required this.label,
  });

  final Color colour;
  final IconData icon;
  final String label;

  static TriageLevelStyle of(TriageLevel level) {
    return switch (level) {
      TriageLevel.emergency => const TriageLevelStyle(
        colour: Color(0xffB3261E),
        icon: Icons.emergency,
        label: 'Emergency',
      ),
      TriageLevel.urgent => const TriageLevelStyle(
        colour: Color(0xffC2410C),
        icon: Icons.priority_high,
        label: 'Urgent',
      ),
      TriageLevel.soon => const TriageLevelStyle(
        colour: Color(0xff2E8BFF),
        icon: Icons.event_note_outlined,
        label: 'See a doctor soon',
      ),
      TriageLevel.selfCare => const TriageLevelStyle(
        colour: Color(0xff15803D),
        icon: Icons.home_outlined,
        label: 'Self care',
      ),
    };
  }
}

/// Always-available way out of the questionnaire.
///
/// Someone whose symptoms are worsening while they answer should not have to
/// finish the form first, and should not have to hunt for the way out either.
class TriageEmergencyBar extends StatelessWidget {
  const TriageEmergencyBar({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const Color red = Color(0xffB3261E);

    return Material(
      color: red.withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.emergency_outlined, color: red, size: 20),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'If this feels like an emergency, do not wait for questions',
                  style: TextStyle(
                    color: red,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: red, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

/// The line that keeps TARU honest about what this is.
class TriageDisclaimer extends StatelessWidget {
  const TriageDisclaimer({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline, size: 16, color: Colors.grey.shade500),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'TARU is not a doctor and cannot diagnose. This is guidance on how '
            'quickly to get help, based on what you have told it. Trust your '
            'own judgement over this screen.',
            style: TextStyle(
              fontSize: 11.5,
              height: 1.45,
              color: Colors.grey.shade600,
            ),
          ),
        ),
      ],
    );
  }
}

/// Shared card shell for the sections on the result screen.
class TriageSection extends StatelessWidget {
  const TriageSection({
    super.key,
    required this.title,
    required this.child,
    this.icon,
    this.accent,
  });

  final String title;
  final Widget child;
  final IconData? icon;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final Color colour = accent ?? Colors.grey.shade800;

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
              if (icon != null) ...[
                Icon(icon, size: 18, color: colour),
                const SizedBox(width: 8),
              ],
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: colour,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

/// One line of advice, reasoning or warning.
class TriageBullet extends StatelessWidget {
  const TriageBullet(this.text, {super.key, this.icon, this.colour});

  final String text;
  final IconData? icon;
  final Color? colour;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              icon ?? Icons.circle,
              size: icon == null ? 6 : 17,
              color: colour ?? Colors.grey.shade500,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Colors.grey.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
