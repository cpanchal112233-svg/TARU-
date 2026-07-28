import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/firebase_providers.dart';
import '../../auth/application/auth_providers.dart';
import '../data/conditions_repository.dart';
import '../domain/medical_condition.dart';

final conditionsRepositoryProvider = Provider<ConditionsRepository>(
  (ref) => ConditionsRepository(ref.watch(firestoreProvider)),
);

final conditionsProvider = StreamProvider<List<UserCondition>>((ref) {
  final User? user = ref.watch(authStateChangesProvider).value;

  if (user == null) {
    return Stream<List<UserCondition>>.value(const <UserCondition>[]);
  }

  return ref.watch(conditionsRepositoryProvider).watch(user.uid);
});

final saveConditionsProvider =
    Provider<Future<void> Function(List<UserCondition>)>((ref) {
      return (List<UserCondition> conditions) async {
        final User? user = ref.read(authStateChangesProvider).value;

        if (user == null) {
          throw StateError('Cannot save conditions while signed out.');
        }

        await ref
            .read(conditionsRepositoryProvider)
            .save(user.uid, conditions);
      };
    });
