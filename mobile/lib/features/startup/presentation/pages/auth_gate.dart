import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../account/application/account_providers.dart';
import '../../../account/domain/account_integrity.dart';
import '../../../account/presentation/pages/account_recovery_screen.dart';
import '../../../auth/application/auth_providers.dart';
import '../../../auth/presentation/pages/login_screen.dart';
import '../../../onboarding/application/onboarding_providers.dart';
import '../../../onboarding/presentation/pages/onboarding_screen.dart';
import '../../../shell/presentation/pages/main_shell.dart';
import '../../../splash/presentation/splash_screen.dart';

enum AuthGateDestination { splash, onboarding, login, mainShell, recovery }

/// Maps startup/auth/account-root signals to a screen. Does not create data.
AuthGateDestination resolveAuthGate({
  required bool splashPending,
  required bool onboardingPending,
  required bool? onboardingComplete,
  required bool authPending,
  required bool signedIn,
  required bool integrityPending,
  required AccountIntegrity? integrity,
}) {
  if (splashPending || onboardingPending || authPending) {
    return AuthGateDestination.splash;
  }
  if (onboardingComplete != true) {
    return AuthGateDestination.onboarding;
  }
  if (!signedIn) {
    return AuthGateDestination.login;
  }
  if (integrityPending) {
    return AuthGateDestination.splash;
  }

  final AccountIntegrity status =
      integrity ?? AccountIntegrity.temporarilyUnavailable;

  switch (status) {
    case AccountIntegrity.signedOut:
      return AuthGateDestination.login;
    case AccountIntegrity.checking:
      return AuthGateDestination.splash;
    case AccountIntegrity.ready:
      return AuthGateDestination.mainShell;
    case AccountIntegrity.deletionHealthInProgress:
    case AccountIntegrity.deletionAccountInProgress:
    case AccountIntegrity.missingRoot:
    case AccountIntegrity.temporarilyUnavailable:
      return AuthGateDestination.recovery;
  }
}

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
    final bool signedIn = authState.value != null;
    final AsyncValue<AccountIntegrity> integrity = signedIn
        ? ref.watch(accountIntegrityProvider)
        : const AsyncValue<AccountIntegrity>.data(AccountIntegrity.signedOut);

    final AuthGateDestination destination = resolveAuthGate(
      splashPending: splash.isLoading,
      onboardingPending: onboarding.isLoading,
      onboardingComplete: onboarding.value,
      authPending: authState.isLoading,
      signedIn: signedIn,
      integrityPending: integrity.isLoading,
      integrity: integrity.value,
    );

    switch (destination) {
      case AuthGateDestination.splash:
        return const SplashScreen();
      case AuthGateDestination.onboarding:
        return const OnboardingScreen();
      case AuthGateDestination.login:
        return const LoginScreen();
      case AuthGateDestination.mainShell:
        return const MainShell();
      case AuthGateDestination.recovery:
        return AccountRecoveryScreen(
          integrity: integrity.value ?? AccountIntegrity.temporarilyUnavailable,
        );
    }
  }
}
