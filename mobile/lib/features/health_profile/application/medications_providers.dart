import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/firebase_providers.dart';
import '../../auth/application/auth_providers.dart';
import '../data/medications_repository.dart';
import '../domain/medication.dart';

final medicationsRepositoryProvider = Provider<MedicationsRepository>(
  (ref) => MedicationsRepository(ref.watch(firestoreProvider)),
);

final medicationsProvider = StreamProvider<MedicationRecord>((ref) {
  final User? user = ref.watch(authStateChangesProvider).value;

  if (user == null) {
    return Stream<MedicationRecord>.value(MedicationRecord.empty);
  }

  return ref.watch(medicationsRepositoryProvider).watch(user.uid);
});

final saveMedicationsProvider =
    Provider<Future<void> Function(MedicationRecord)>((ref) {
      return (MedicationRecord record) async {
        final User? user = ref.read(authStateChangesProvider).value;

        if (user == null) {
          throw StateError('Cannot save medications while signed out.');
        }

        await ref.read(medicationsRepositoryProvider).save(user.uid, record);
      };
    });
