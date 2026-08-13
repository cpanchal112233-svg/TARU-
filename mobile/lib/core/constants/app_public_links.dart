/// Non-secret public launch links. Null/empty values hide the related UI.
///
/// Founder/legal must supply real values before public release. Do not invent
/// placeholder URLs or emails that look live.
class AppPublicLinks {
  const AppPublicLinks._();

  /// Support contact for Help & support → Contact support.
  static const String? supportEmail = null;

  /// Absolute https URL for Privacy Policy.
  static const String? privacyPolicyUrl = null;

  /// Absolute https URL for Terms of Use.
  static const String? termsOfUseUrl = null;

  static bool get hasSupportEmail => _hasText(supportEmail);

  static bool get hasPrivacyPolicyUrl => _hasText(privacyPolicyUrl);

  static bool get hasTermsOfUseUrl => _hasText(termsOfUseUrl);

  static bool _hasText(String? value) =>
      value != null && value.trim().isNotEmpty;
}
