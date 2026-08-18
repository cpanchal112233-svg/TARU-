import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../health_context/application/health_context_providers.dart';
import '../../health_profile/application/allergies_providers.dart';
import '../../health_profile/application/conditions_providers.dart';
import '../../health_profile/application/health_profile_providers.dart';
import '../../health_profile/application/medications_providers.dart';
import '../../measurements/application/measurements_providers.dart';
import '../../reports/application/reports_providers.dart';
import '../../routine/application/habit_providers.dart';
import '../../routine/application/reminder_providers.dart';
import '../../routine/application/routine_providers.dart';
import '../data/health_export_service.dart';
import '../data/local_privacy_cleanup.dart';
import '../data/purge_client.dart';
import '../domain/purge_mode.dart';
import 'privacy_controller.dart';

final purgeClientProvider = Provider<PurgeClient>(
  (Ref ref) => PurgeClient.forRegion(),
);

final healthExportServiceProvider = Provider<HealthExportService>(
  (Ref ref) => HealthExportService(),
);

final localPrivacyCleanupProvider = Provider<LocalPrivacyCleanup>((Ref ref) {
  return LocalPrivacyCleanup(
    reminderService: ref.watch(reminderServiceProvider),
  );
});

final privacyControllerProvider = Provider<PrivacyController>((Ref ref) {
  return PrivacyController(
    auth: FirebaseAuth.instance,
    firestore: FirebaseFirestore.instance,
    purgeClient: ref.watch(purgeClientProvider),
    exportService: ref.watch(healthExportServiceProvider),
    localCleanup: ref.watch(localPrivacyCleanupProvider),
    onAfterHealthReset: () {
      ref.invalidate(remindersControllerProvider);
      ref.invalidate(lifestyleRemindersControllerProvider);
      ref.invalidate(healthProfileProvider);
      ref.invalidate(conditionsProvider);
      ref.invalidate(allergiesProvider);
      ref.invalidate(medicationsProvider);
      ref.invalidate(reportsProvider);
      ref.invalidate(weightHistoryProvider);
      ref.invalidate(latestWeightMeasurementProvider);
      ref.invalidate(todayDoseLogProvider);
      ref.invalidate(todayHabitLogProvider);
      ref.invalidate(habitPreferencesProvider);
      ref.invalidate(dietaryProfileProvider);
      ref.invalidate(lifestyleContextProvider);
      ref.invalidate(supplementsProvider);
      ref.invalidate(familyHistoryProvider);
      ref.invalidate(proceduresProvider);
      ref.invalidate(immunizationsProvider);
      ref.invalidate(healthGoalsProvider);
      ref.invalidate(careTeamProvider);
    },
  );
});

/// Whether the account root currently has an active deletion guard.
final deletionGuardActiveProvider = StreamProvider<bool>((Ref ref) {
  final User? user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    return Stream<bool>.value(false);
  }
  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .snapshots()
      .map((DocumentSnapshot<Map<String, dynamic>> snap) {
        if (!snap.exists || snap.data() == null) return false;
        final Object? flag = snap.data()!['deletionInProgress'];
        return flag == PurgeMode.health.wireValue ||
            flag == PurgeMode.account.wireValue;
      });
});
