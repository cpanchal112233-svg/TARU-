import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/firebase_providers.dart';
import '../../auth/application/auth_providers.dart';
import '../../health_profile/application/allergies_providers.dart';
import '../../health_profile/application/conditions_providers.dart';
import '../../health_profile/application/health_profile_providers.dart';
import '../../health_profile/application/medications_providers.dart';
import '../../health_profile/domain/allergy.dart';
import '../../health_profile/domain/health_profile.dart';
import '../../health_profile/domain/medical_condition.dart';
import '../../health_profile/domain/medication.dart';
import '../data/snapshot_document_repositories.dart';
import '../data/user_owned_collection_repository.dart';
import '../domain/care_team_member.dart';
import '../domain/dietary_profile.dart';
import '../domain/family_history_record.dart';
import '../domain/health_context_paths.dart';
import '../domain/health_context_snapshot.dart';
import '../domain/health_goal_record.dart';
import '../domain/immunization_record.dart';
import '../domain/lifestyle_context.dart';
import '../domain/procedure_record.dart';
import '../domain/supplement_record.dart';

final dietaryProfileRepositoryProvider = Provider<DietaryProfileRepository>(
  (Ref ref) => DietaryProfileRepository(ref.watch(firestoreProvider)),
);

final lifestyleContextRepositoryProvider = Provider<LifestyleContextRepository>(
  (Ref ref) => LifestyleContextRepository(ref.watch(firestoreProvider)),
);

final supplementRepositoryProvider =
    Provider<UserOwnedCollectionRepository<SupplementRecord>>(
      (Ref ref) => UserOwnedCollectionRepository<SupplementRecord>(
        firestore: ref.watch(firestoreProvider),
        collectionName: HealthContextPaths.supplements,
        fromMap: SupplementRecord.fromMap,
        toMap: (SupplementRecord value) => value.toMap(),
      ),
    );

final familyHistoryRepositoryProvider =
    Provider<UserOwnedCollectionRepository<FamilyHistoryRecord>>(
      (Ref ref) => UserOwnedCollectionRepository<FamilyHistoryRecord>(
        firestore: ref.watch(firestoreProvider),
        collectionName: HealthContextPaths.familyHistory,
        fromMap: FamilyHistoryRecord.fromMap,
        toMap: (FamilyHistoryRecord value) => value.toMap(),
      ),
    );

final procedureRepositoryProvider =
    Provider<UserOwnedCollectionRepository<ProcedureRecord>>(
      (Ref ref) => UserOwnedCollectionRepository<ProcedureRecord>(
        firestore: ref.watch(firestoreProvider),
        collectionName: HealthContextPaths.procedures,
        fromMap: ProcedureRecord.fromMap,
        toMap: (ProcedureRecord value) => value.toMap(),
      ),
    );

final immunizationRepositoryProvider =
    Provider<UserOwnedCollectionRepository<ImmunizationRecord>>(
      (Ref ref) => UserOwnedCollectionRepository<ImmunizationRecord>(
        firestore: ref.watch(firestoreProvider),
        collectionName: HealthContextPaths.immunizations,
        fromMap: ImmunizationRecord.fromMap,
        toMap: (ImmunizationRecord value) => value.toMap(),
      ),
    );

final healthGoalRepositoryProvider =
    Provider<UserOwnedCollectionRepository<HealthGoalRecord>>(
      (Ref ref) => UserOwnedCollectionRepository<HealthGoalRecord>(
        firestore: ref.watch(firestoreProvider),
        collectionName: HealthContextPaths.healthGoals,
        fromMap: HealthGoalRecord.fromMap,
        toMap: (HealthGoalRecord value) => value.toMap(),
      ),
    );

final careTeamRepositoryProvider =
    Provider<UserOwnedCollectionRepository<CareTeamMember>>(
      (Ref ref) => UserOwnedCollectionRepository<CareTeamMember>(
        firestore: ref.watch(firestoreProvider),
        collectionName: HealthContextPaths.careTeam,
        fromMap: CareTeamMember.fromMap,
        toMap: (CareTeamMember value) => value.toMap(),
      ),
    );

final dietaryProfileProvider = StreamProvider<DietaryProfile>((Ref ref) {
  final User? user = ref.watch(authStateChangesProvider).value;
  if (user == null) return Stream<DietaryProfile>.value(DietaryProfile.empty);
  return ref.watch(dietaryProfileRepositoryProvider).watch(user.uid);
});

final lifestyleContextProvider = StreamProvider<LifestyleContext>((Ref ref) {
  final User? user = ref.watch(authStateChangesProvider).value;
  if (user == null) {
    return Stream<LifestyleContext>.value(LifestyleContext.empty);
  }
  return ref.watch(lifestyleContextRepositoryProvider).watch(user.uid);
});

final supplementsProvider = StreamProvider<List<SupplementRecord>>((Ref ref) {
  final User? user = ref.watch(authStateChangesProvider).value;
  if (user == null) {
    return Stream<List<SupplementRecord>>.value(const <SupplementRecord>[]);
  }
  return ref.watch(supplementRepositoryProvider).watch(user.uid);
});

final familyHistoryProvider = StreamProvider<List<FamilyHistoryRecord>>((
  Ref ref,
) {
  final User? user = ref.watch(authStateChangesProvider).value;
  if (user == null) {
    return Stream<List<FamilyHistoryRecord>>.value(
      const <FamilyHistoryRecord>[],
    );
  }
  return ref.watch(familyHistoryRepositoryProvider).watch(user.uid);
});

final proceduresProvider = StreamProvider<List<ProcedureRecord>>((Ref ref) {
  final User? user = ref.watch(authStateChangesProvider).value;
  if (user == null) {
    return Stream<List<ProcedureRecord>>.value(const <ProcedureRecord>[]);
  }
  return ref.watch(procedureRepositoryProvider).watch(user.uid);
});

final immunizationsProvider = StreamProvider<List<ImmunizationRecord>>((
  Ref ref,
) {
  final User? user = ref.watch(authStateChangesProvider).value;
  if (user == null) {
    return Stream<List<ImmunizationRecord>>.value(const <ImmunizationRecord>[]);
  }
  return ref.watch(immunizationRepositoryProvider).watch(user.uid);
});

final healthGoalsProvider = StreamProvider<List<HealthGoalRecord>>((Ref ref) {
  final User? user = ref.watch(authStateChangesProvider).value;
  if (user == null) {
    return Stream<List<HealthGoalRecord>>.value(const <HealthGoalRecord>[]);
  }
  return ref.watch(healthGoalRepositoryProvider).watch(user.uid);
});

final careTeamProvider = StreamProvider<List<CareTeamMember>>((Ref ref) {
  final User? user = ref.watch(authStateChangesProvider).value;
  if (user == null) {
    return Stream<List<CareTeamMember>>.value(const <CareTeamMember>[]);
  }
  return ref.watch(careTeamRepositoryProvider).watch(user.uid);
});

/// Read-only aggregate. Never written to Firestore.
/// [generatedAt] is assembly time at this provider boundary, not event time.
final healthContextSnapshotProvider = Provider<HealthContextSnapshot>((
  Ref ref,
) {
  return HealthContextSnapshot(
    generatedAt: DateTime.now().toUtc(),
    profile: ref.watch(healthProfileProvider).value ?? HealthProfile.empty,
    conditions: ref.watch(conditionsProvider).value ?? ConditionRecord.empty,
    allergies: ref.watch(allergiesProvider).value ?? AllergyRecord.empty,
    medications: ref.watch(medicationsProvider).value ?? MedicationRecord.empty,
    diet: ref.watch(dietaryProfileProvider).value ?? DietaryProfile.empty,
    supplements:
        ref.watch(supplementsProvider).value ?? const <SupplementRecord>[],
    familyHistory:
        ref.watch(familyHistoryProvider).value ?? const <FamilyHistoryRecord>[],
    procedures:
        ref.watch(proceduresProvider).value ?? const <ProcedureRecord>[],
    immunizations:
        ref.watch(immunizationsProvider).value ?? const <ImmunizationRecord>[],
    lifestyle:
        ref.watch(lifestyleContextProvider).value ?? LifestyleContext.empty,
    goals: ref.watch(healthGoalsProvider).value ?? const <HealthGoalRecord>[],
    careTeam: ref.watch(careTeamProvider).value ?? const <CareTeamMember>[],
  );
});
