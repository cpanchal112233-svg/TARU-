import '../../health_profile/domain/medication.dart';
import '../../safety/domain/safety_profile.dart';
import 'interaction_rules.dart';
import 'medicine_group.dart';
import 'medicine_warning.dart';

/// Turns a medicine list plus a safety profile into warnings worth reading.
///
/// The checker is pure: same input, same output, no Firestore and no clock. It
/// is the piece the unit tests hold to account, because a wrong answer here is
/// a wrong answer shown to someone about their own tablets.
abstract final class MedicineChecker {
  static List<MedicineWarning> check({
    required List<UserMedication> medicines,
    required SafetyProfile profile,
  }) {
    if (medicines.isEmpty) return const <MedicineWarning>[];

    final List<Set<MedicineGroup>> groupsPerMedicine = medicines
        .map((UserMedication m) => groupsOf(m.ingredient))
        .toList(growable: false);

    final List<MedicineWarning> warnings = <MedicineWarning>[];
    final Set<String> superseded = <String>{};

    for (final InteractionRule rule in interactionRules) {
      final List<UserMedication>? involved = _matchRule(
        rule,
        medicines,
        groupsPerMedicine,
      );

      if (involved == null) continue;

      superseded.addAll(rule.supersedes);
      warnings.add(
        MedicineWarning(
          code: rule.code,
          severity: rule.severity,
          title: rule.title,
          detail: rule.detail,
          action: rule.action,
          medicines: involved,
        ),
      );
    }

    for (final ConditionCaution caution in conditionCautions) {
      if (!profile.riskFactors.contains(caution.factor)) continue;

      final List<UserMedication> involved = <UserMedication>[
        for (int i = 0; i < medicines.length; i++)
          if (groupsPerMedicine[i].contains(caution.group)) medicines[i],
      ];

      if (involved.isEmpty) continue;

      warnings.add(
        MedicineWarning(
          code: caution.code,
          severity: caution.severity,
          title: caution.title,
          detail: caution.detail,
          action: caution.action,
          medicines: involved,
        ),
      );
    }

    warnings.removeWhere((MedicineWarning w) => superseded.contains(w.code));

    // Stable so that rule order — which runs bleeding first, then organs, then
    // timing — decides ties rather than the sort.
    warnings.sort(
      (MedicineWarning a, MedicineWarning b) =>
          b.severity.order.compareTo(a.severity.order),
    );

    return List<MedicineWarning>.unmodifiable(warnings);
  }

  /// The medicines a rule applies to, or null if the rule does not fire.
  ///
  /// A rule needs a *different* medicine for each of its groups, so warfarin
  /// alone cannot trigger "two blood thinners" by belonging to two groups. Two
  /// separate entries of the same ingredient can, which is the point of the
  /// duplicate-paracetamol rule.
  static List<UserMedication>? _matchRule(
    InteractionRule rule,
    List<UserMedication> medicines,
    List<Set<MedicineGroup>> groupsPerMedicine,
  ) {
    final List<MedicineGroup> slots = rule.requiredCount > rule.groups.length
        ? List<MedicineGroup>.filled(rule.requiredCount, rule.groups.single)
        : rule.groups;

    final List<List<int>> candidates = <List<int>>[
      for (final MedicineGroup group in slots)
        <int>[
          for (int i = 0; i < medicines.length; i++)
            if (groupsPerMedicine[i].contains(group)) i,
        ],
    ];

    if (candidates.any((List<int> options) => options.isEmpty)) return null;
    if (!_canFill(candidates, 0, <int>{})) return null;

    // Report every medicine the rule touches, not just one satisfying
    // assignment: someone on two anti-inflammatories and warfarin should see
    // all three named.
    final Set<int> involved = <int>{
      for (final List<int> options in candidates) ...options,
    };

    return <UserMedication>[
      for (final int index in involved.toList()..sort()) medicines[index],
    ];
  }

  static bool _canFill(List<List<int>> candidates, int slot, Set<int> used) {
    if (slot == candidates.length) return true;

    for (final int index in candidates[slot]) {
      if (used.contains(index)) continue;

      used.add(index);
      if (_canFill(candidates, slot + 1, used)) return true;
      used.remove(index);
    }

    return false;
  }
}

/// Convenience view of a warning list for the UI.
extension MedicineWarningList on List<MedicineWarning> {
  List<MedicineWarning> forMedicine(UserMedication medicine) =>
      <MedicineWarning>[
        for (final MedicineWarning warning in this)
          if (warning.involves(medicine)) warning,
      ];

  int countOf(MedicineWarningSeverity severity) =>
      where((MedicineWarning w) => w.severity == severity).length;

  MedicineWarningSeverity? get highestSeverity {
    MedicineWarningSeverity? highest;

    for (final MedicineWarning warning in this) {
      if (highest == null || warning.severity.order > highest.order) {
        highest = warning.severity;
      }
    }

    return highest;
  }
}
