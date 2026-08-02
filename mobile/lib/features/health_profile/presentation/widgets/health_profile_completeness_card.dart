import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/health_completeness_providers.dart';
import '../../domain/health_completeness.dart';
import '../pages/allergies_screen.dart';
import '../pages/conditions_screen.dart';
import '../pages/health_profile_screen.dart';
import '../pages/medications_screen.dart';

/// Nudges the user to finish their health profile, and shows what is missing.
///
/// Partial answers are genuinely useful, so this reports progress rather than
/// blocking the app behind a mandatory form. An unanswered allergy question is
/// treated differently from an untidy one: it turns the card amber, because
/// nothing TARU suggests later is safe until that gap is closed.
class HealthProfileCompletenessCard extends ConsumerWidget {
  const HealthProfileCompletenessCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final HealthCompleteness? completeness = ref.watch(
      healthCompletenessProvider,
    );

    // Stay out of the layout until the real numbers are known, so the card does
    // not flash a misleading 0%.
    if (completeness == null) return const SizedBox.shrink();

    final bool isComplete = completeness.isComplete;
    final HealthCompletenessItem? criticalGap = completeness.criticalGap;

    final Color accent = isComplete
        ? const Color(0xff16A34A)
        : criticalGap != null
        ? const Color(0xffD97706)
        : Theme.of(context).colorScheme.primary;

    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => _screenFor(completeness.nextSection),
        ),
      ),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accent.withValues(alpha: 0.35)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            _ProgressRing(
              progress: completeness.completion,
              accent: accent,
              isComplete: isComplete,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _titleFor(isComplete, criticalGap),
                    style: const TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _subtitleFor(completeness),
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.35,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey.shade500,
            ),
          ],
        ),
      ),
    );
  }

  static Widget _screenFor(HealthProfileSection section) {
    switch (section) {
      case HealthProfileSection.basics:
        return const HealthProfileScreen();
      case HealthProfileSection.conditions:
        return const ConditionsScreen();
      case HealthProfileSection.allergies:
        return const AllergiesScreen();
      case HealthProfileSection.medications:
        return const MedicationsScreen();
    }
  }

  static String _titleFor(bool isComplete, HealthCompletenessItem? gap) {
    if (isComplete) return 'Health profile complete';
    if (gap != null) return 'TARU does not know your allergies';

    return 'Complete your health profile';
  }

  static String _subtitleFor(HealthCompleteness completeness) {
    final List<String> missing = completeness.missingLabels;

    if (missing.isEmpty) {
      return 'Tap to review or update your details.';
    }

    if (completeness.criticalGap != null) {
      return 'Until you answer this, TARU cannot rule out a reaction to '
          'anything it suggests. It takes a moment.';
    }

    if (completeness.completion == 0) {
      return 'TARU needs a few basics before it can give advice that fits you.';
    }

    if (missing.length <= 2) {
      return 'Still needed: ${missing.join(' and ')}.';
    }

    return 'Still needed: ${missing.take(2).join(', ')} '
        'and ${missing.length - 2} more.';
  }
}

class _ProgressRing extends StatelessWidget {
  const _ProgressRing({
    required this.progress,
    required this.accent,
    required this.isComplete,
  });

  final double progress;
  final Color accent;
  final bool isComplete;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      height: 52,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 5,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
          if (isComplete)
            Icon(Icons.check, size: 24, color: accent)
          else
            Text(
              '${(progress * 100).round()}%',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: accent,
              ),
            ),
        ],
      ),
    );
  }
}
