/// Non-secret public launch links. Null/empty values hide the related UI.
///
/// Founder/legal must supply real values before public release. Do not invent
/// placeholder URLs or emails that look live.
class AppPublicLinks {
  const AppPublicLinks._();

  /// Support contact for Help & support → Contact support.
  static const String? supportEmail = null;

  /// Product feedback for Help & support → Send product feedback.
  /// Prefer [feedbackEmail] (mailto) or [feedbackUrl] (https). If both are
  /// set, email is used.
  static const String? feedbackEmail = null;

  /// Absolute https URL for product feedback (used when [feedbackEmail] is unset).
  static const String? feedbackUrl = null;

  /// Absolute https URL for Privacy Policy.
  static const String? privacyPolicyUrl = null;

  /// Absolute https URL for Terms of Use.
  static const String? termsOfUseUrl = null;

  static bool get hasSupportEmail => _hasText(supportEmail);

  static bool get hasFeedbackEmail => _hasText(feedbackEmail);

  static bool get hasFeedbackUrl => _hasText(feedbackUrl);

  /// True when either feedback email or URL is configured.
  static bool get hasFeedbackDestination =>
      hasFeedbackEmail || hasFeedbackUrl;

  static bool get hasPrivacyPolicyUrl => _hasText(privacyPolicyUrl);

  static bool get hasTermsOfUseUrl => _hasText(termsOfUseUrl);

  /// Mailto or https URI for product feedback. Never includes account or
  /// health contents. Subject-only for mailto is intentional.
  static Uri? feedbackLaunchUri({
    String? emailOverride,
    String? urlOverride,
  }) {
    final String? email = (emailOverride ?? feedbackEmail)?.trim();
    if (email != null && email.isNotEmpty) {
      return Uri(
        scheme: 'mailto',
        path: email,
        query: 'subject=${Uri.encodeComponent('TARU product feedback')}',
      );
    }
    final String? url = (urlOverride ?? feedbackUrl)?.trim();
    if (url != null && url.isNotEmpty) {
      return Uri.parse(url);
    }
    return null;
  }

  static bool _hasText(String? value) =>
      value != null && value.trim().isNotEmpty;
}
