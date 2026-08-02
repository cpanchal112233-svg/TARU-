import 'package:flutter/foundation.dart';

import '../../health_profile/domain/medication.dart';
import '../../safety/domain/health_risk.dart';
import 'medicine_group.dart';

/// How much a warning matters.
///
/// Three levels, not five. A list where everything is amber teaches people to
/// scroll past all of it, and the point of this feature is that the one
/// serious warning gets read.
enum MedicineWarningSeverity {
  serious(
    order: 2,
    label: 'Speak to a doctor',
    countPhrase: 'to speak to a doctor about',
    summary: 'These are not usually taken together',
  ),
  caution(
    order: 1,
    label: 'Worth checking',
    countPhrase: 'worth checking',
    summary: 'Usable together, but keep an eye on it',
  ),
  timing(
    order: 0,
    label: 'Space them apart',
    countPhrase: 'about timing',
    summary: 'Fine together, just not at the same moment',
  );

  const MedicineWarningSeverity({
    required this.order,
    required this.label,
    required this.countPhrase,
    required this.summary,
  });

  final int order;
  final String label;

  /// Reads after a number: "2 worth checking".
  final String countPhrase;

  final String summary;
}

/// An interaction between medicines the user takes.
@immutable
class InteractionRule {
  const InteractionRule({
    required this.code,
    required this.groups,
    required this.severity,
    required this.title,
    required this.detail,
    required this.action,
    this.minimumMedicines,
    this.supersedes = const <String>[],
  });

  /// Stable identifier, so a dismissed or acknowledged warning could be
  /// remembered later without depending on the wording.
  final String code;

  /// Every group here must be filled by a different medicine for the rule to
  /// fire.
  final List<MedicineGroup> groups;

  /// Overrides the usual "one medicine per group" requirement, for rules about
  /// taking two of the same kind at once.
  final int? minimumMedicines;

  /// Codes of weaker rules that say the same thing about the same medicines.
  /// When this rule fires they are dropped, so the user reads one clear warning
  /// instead of three overlapping ones.
  final List<String> supersedes;

  final MedicineWarningSeverity severity;
  final String title;
  final String detail;
  final String action;

  int get requiredCount => minimumMedicines ?? groups.length;
}

/// A medicine that needs care because of a condition, an age, or a pregnancy
/// rather than because of another medicine.
@immutable
class ConditionCaution {
  const ConditionCaution({
    required this.code,
    required this.group,
    required this.factor,
    required this.severity,
    required this.title,
    required this.detail,
    required this.action,
  });

  final String code;
  final MedicineGroup group;
  final HealthRiskFactor factor;
  final MedicineWarningSeverity severity;
  final String title;
  final String detail;
  final String action;
}

/// One thing worth telling the user, with the medicines it concerns.
@immutable
class MedicineWarning {
  const MedicineWarning({
    required this.code,
    required this.severity,
    required this.title,
    required this.detail,
    required this.action,
    required this.medicines,
  });

  final String code;
  final MedicineWarningSeverity severity;
  final String title;
  final String detail;
  final String action;

  /// The user's own entries, so the warning names what is in their cupboard
  /// rather than a drug class they may not recognise.
  final List<UserMedication> medicines;

  String get medicineNames =>
      medicines.map((UserMedication m) => m.displayName).join(' + ');

  bool involves(UserMedication medicine) => medicines.contains(medicine);
}
