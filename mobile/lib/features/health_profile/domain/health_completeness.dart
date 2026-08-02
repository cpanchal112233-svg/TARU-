import 'package:flutter/foundation.dart';

import 'allergy.dart';
import 'health_profile.dart';
import 'medical_condition.dart';
import 'medication.dart';

/// Which part of the health profile an answer belongs to, so the UI can send
/// someone straight to the screen that still needs them.
enum HealthProfileSection { basics, conditions, allergies, medications }

@immutable
class HealthCompletenessItem {
  const HealthCompletenessItem({
    required this.label,
    required this.isComplete,
    required this.section,
    this.isCritical = false,
  });

  final String label;
  final bool isComplete;
  final HealthProfileSection section;

  /// Missing this is a safety problem rather than an untidy form: TARU cannot
  /// safely suggest anything at all while it is unanswered.
  final bool isCritical;
}

/// How much TARU knows about the user, across every part of the health profile.
///
/// Basics alone are not enough to call a profile complete. Someone whose
/// allergies have never been asked about should never see a reassuring green
/// tick, because that is exactly the gap that makes advice dangerous.
@immutable
class HealthCompleteness {
  const HealthCompleteness(this.items);

  factory HealthCompleteness.from({
    required HealthProfile profile,
    required ConditionRecord conditions,
    required AllergyRecord allergies,
    required MedicationRecord medications,
  }) {
    return HealthCompleteness([
      for (final ({String label, bool isComplete}) item
          in profile.completionItems)
        HealthCompletenessItem(
          label: item.label,
          isComplete: item.isComplete,
          section: HealthProfileSection.basics,
        ),
      HealthCompletenessItem(
        label: 'Medical conditions',
        isComplete: conditions.hasAnswered,
        section: HealthProfileSection.conditions,
      ),
      HealthCompletenessItem(
        label: 'Allergies',
        isComplete: allergies.hasAnswered,
        section: HealthProfileSection.allergies,
        isCritical: true,
      ),
      HealthCompletenessItem(
        label: 'Medications',
        isComplete: medications.hasAnswered,
        section: HealthProfileSection.medications,
      ),
    ]);
  }

  final List<HealthCompletenessItem> items;

  List<HealthCompletenessItem> get missing =>
      items.where((HealthCompletenessItem item) => !item.isComplete).toList();

  List<String> get missingLabels =>
      missing.map((HealthCompletenessItem item) => item.label).toList();

  double get completion {
    if (items.isEmpty) return 1;

    final int done = items
        .where((HealthCompletenessItem item) => item.isComplete)
        .length;

    return done / items.length;
  }

  bool get isComplete => missing.isEmpty;

  /// The first unanswered safety-critical question, if there is one.
  HealthCompletenessItem? get criticalGap {
    for (final HealthCompletenessItem item in missing) {
      if (item.isCritical) return item;
    }

    return null;
  }

  /// Where to send someone who taps "finish my profile".
  HealthProfileSection get nextSection =>
      criticalGap?.section ??
      missing.firstOrNull?.section ??
      HealthProfileSection.basics;
}
