import 'package:shared_preferences/shared_preferences.dart';

/// Remembers whether the user has already been through onboarding, so the
/// intro slides are only ever shown once per device.
class OnboardingRepository {
  static const String _hasSeenOnboardingKey = 'has_seen_onboarding';

  Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasSeenOnboardingKey) ?? false;
  }

  Future<void> markOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasSeenOnboardingKey, true);
  }
}
