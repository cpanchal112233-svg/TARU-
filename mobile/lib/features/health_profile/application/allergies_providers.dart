import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/firebase_providers.dart';
import '../../auth/application/auth_providers.dart';
import '../data/allergies_repository.dart';
import '../domain/allergy.dart';

final allergiesRepositoryProvider = Provider<AllergiesRepository>(
  (ref) => AllergiesRepository(ref.watch(firestoreProvider)),
);

final allergiesProvider = StreamProvider<AllergyRecord>((ref) {
  final User? user = ref.watch(authStateChangesProvider).value;

  if (user == null) return Stream<AllergyRecord>.value(AllergyRecord.empty);

  return ref.watch(allergiesRepositoryProvider).watch(user.uid);
});

final saveAllergiesProvider = Provider<Future<void> Function(AllergyRecord)>((
  ref,
) {
  return (AllergyRecord record) async {
    final User? user = ref.read(authStateChangesProvider).value;

    if (user == null) {
      throw StateError('Cannot save allergies while signed out.');
    }

    await ref.read(allergiesRepositoryProvider).save(user.uid, record);
  };
});
