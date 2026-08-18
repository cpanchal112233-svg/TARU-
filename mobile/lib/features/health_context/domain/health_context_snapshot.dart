import '../../health_profile/domain/allergy.dart';
import '../../health_profile/domain/health_profile.dart';
import '../../health_profile/domain/medical_condition.dart';
import '../../health_profile/domain/medication.dart';
import 'care_team_member.dart';
import 'dietary_profile.dart';
import 'family_history_record.dart';
import 'health_goal_record.dart';
import 'immunization_record.dart';
import 'lifestyle_context.dart';
import 'procedure_record.dart';
import 'supplement_record.dart';

/// Read-only structured current context for future Evidence Brief, Doctor
/// Mode, AI grounding, and care planning.
///
/// Not persisted. Domain records remain authoritative.
/// [generatedAt] is when this in-memory aggregate was assembled. It is not
/// the event time or recorded time of any underlying fact.
class HealthContextSnapshot {
  const HealthContextSnapshot({
    required this.generatedAt,
    required this.profile,
    required this.conditions,
    required this.allergies,
    required this.medications,
    required this.diet,
    required this.supplements,
    required this.familyHistory,
    required this.procedures,
    required this.immunizations,
    required this.lifestyle,
    required this.goals,
    required this.careTeam,
  });

  /// Assembly time of this derived view. Not persisted.
  final DateTime generatedAt;
  final HealthProfile profile;
  final ConditionRecord conditions;
  final AllergyRecord allergies;
  final MedicationRecord medications;
  final DietaryProfile diet;
  final List<SupplementRecord> supplements;
  final List<FamilyHistoryRecord> familyHistory;
  final List<ProcedureRecord> procedures;
  final List<ImmunizationRecord> immunizations;
  final LifestyleContext lifestyle;
  final List<HealthGoalRecord> goals;
  final List<CareTeamMember> careTeam;

  List<SupplementRecord> get currentSupplements =>
      supplements.where((SupplementRecord item) => item.isCurrent).toList();

  List<HealthGoalRecord> get activeGoals => goals
      .where((HealthGoalRecord item) => item.status == HealthGoalStatus.active)
      .toList();

  Map<String, dynamic> toDebugMap() {
    return <String, dynamic>{
      'generatedAt': generatedAt.toUtc().toIso8601String(),
      'hasProfileBasics': profile.dateOfBirth != null,
      'conditionCount': conditions.conditions.length,
      'allergyCount': allergies.allergies.length,
      'medicationCount': medications.medications.length,
      'dietRecorded': diet.isRecorded,
      'supplementCount': supplements.length,
      'familyHistoryCount': familyHistory.length,
      'procedureCount': procedures.length,
      'immunizationCount': immunizations.length,
      'lifestyleRecorded': lifestyle.isRecorded,
      'goalCount': goals.length,
      'careTeamCount': careTeam.length,
      'snapshotPersisted': false,
    };
  }
}
