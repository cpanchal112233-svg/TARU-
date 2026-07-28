import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/onboarding_repository.dart';

final onboardingRepositoryProvider = Provider<OnboardingRepository>(
  (ref) => OnboardingRepository(),
);

/// Whether onboarding has been completed on this device.
class OnboardingController extends AsyncNotifier<bool> {
  @override
  Future<bool> build() {
    return ref.watch(onboardingRepositoryProvider).hasSeenOnboarding();
  }

  Future<void> complete() async {
    await ref.read(onboardingRepositoryProvider).markOnboardingSeen();
    state = const AsyncValue.data(true);
  }
}

final onboardingControllerProvider =
    AsyncNotifierProvider<OnboardingController, bool>(OnboardingController.new);
