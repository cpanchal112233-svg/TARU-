import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/firebase_providers.dart';
import '../../auth/application/auth_providers.dart';
import '../data/health_profile_repository.dart';
import '../domain/health_profile.dart';

final healthProfileRepositoryProvider = Provider<HealthProfileRepository>(
  (ref) => HealthProfileRepository(ref.watch(firestoreProvider)),
);

/// The signed-in user's health basics, kept live so edits show up everywhere
/// at once.
final healthProfileProvider = StreamProvider<HealthProfile>((ref) {
  final User? user = ref.watch(authStateChangesProvider).value;

  if (user == null) return Stream<HealthProfile>.value(HealthProfile.empty);

  return ref.watch(healthProfileRepositoryProvider).watch(user.uid);
});

/// Saves the health basics for the signed-in user.
final saveHealthProfileProvider =
    Provider<Future<void> Function(HealthProfile)>((ref) {
      return (HealthProfile profile) async {
        final User? user = ref.read(authStateChangesProvider).value;

        if (user == null) {
          throw StateError('Cannot save a health profile while signed out.');
        }

        await ref.read(healthProfileRepositoryProvider).save(user.uid, profile);
      };
    });
