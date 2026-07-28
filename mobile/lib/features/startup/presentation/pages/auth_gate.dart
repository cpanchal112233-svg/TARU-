import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/application/auth_providers.dart';
import '../../../auth/presentation/pages/login_screen.dart';
import '../../../onboarding/application/onboarding_providers.dart';
import '../../../onboarding/presentation/pages/onboarding_screen.dart';
import '../../../shell/presentation/pages/main_shell.dart';
import '../../../splash/presentation/splash_screen.dart';

/// Keeps the branded splash visible briefly even when startup resolves instantly.
final _minimumSplashProvider = FutureProvider<void>(
  (ref) => Future<void>.delayed(const Duration(milliseconds: 1500)),
);

/// Single source of truth for which screen the app shows.
///
/// Because this sits at the root of the app, signing in or out swaps the screen
/// automatically — individual screens never need to rewrite the navigation stack.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<void> splash = ref.watch(_minimumSplashProvider);
    final AsyncValue<bool> onboarding = ref.watch(onboardingControllerProvider);
    final AsyncValue<User?> authState = ref.watch(authStateChangesProvider);

    if (splash.isLoading || onboarding.isLoading || authState.isLoading) {
      return const SplashScreen();
    }

    if (onboarding.value != true) {
      return const OnboardingScreen();
    }

    if (authState.value == null) {
      return const LoginScreen();
    }

    return const MainShell();
  }
}
