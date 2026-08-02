import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/firebase_providers.dart';
import '../../auth/application/auth_providers.dart';

/// The name to show the user, preferring what they typed into their TARU
/// profile over whatever the auth provider happens to hold.
final userDisplayNameProvider = StreamProvider<String?>((ref) {
  final User? user = ref.watch(authStateChangesProvider).value;

  if (user == null) return Stream<String?>.value(null);

  return ref
      .watch(firestoreProvider)
      .collection('users')
      .doc(user.uid)
      .snapshots()
      .map((snapshot) {
        final Object? name = snapshot.data()?['name'];

        if (name is String && name.trim().isNotEmpty) return name.trim();

        final String? fallback = user.displayName?.trim();

        return (fallback == null || fallback.isEmpty) ? null : fallback;
      });
});
