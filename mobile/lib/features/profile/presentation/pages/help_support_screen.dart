import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_public_links.dart';
import '../../../privacy/presentation/pages/privacy_data_screen.dart';

/// Minimal Help & support: medical boundary, privacy controls, optional links.
class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  static const String medicalBoundary =
      'TARU helps you organize and review information you record. It does not '
      'diagnose conditions or replace professional medical care.';

  Future<void> _openUri(BuildContext context, Uri uri) async {
    try {
      final bool launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open that link.')),
        );
      }
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open that link.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: AppBar(
        title: const Text('Help & support'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'About TARU',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: const Text(
              medicalBoundary,
              style: TextStyle(fontSize: 15, height: 1.45),
            ),
          ),
          const SizedBox(height: 24),
          _HelpTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy & data',
            subtitle: 'Export or delete your TARU health data',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const PrivacyDataScreen(),
                ),
              );
            },
          ),
          if (AppPublicLinks.hasSupportEmail) ...[
            const SizedBox(height: 12),
            _HelpTile(
              icon: Icons.mail_outline,
              title: 'Contact support',
              subtitle: AppPublicLinks.supportEmail!.trim(),
              onTap: () {
                final String email = AppPublicLinks.supportEmail!.trim();
                _openUri(context, Uri(scheme: 'mailto', path: email));
              },
            ),
          ],
          if (AppPublicLinks.hasPrivacyPolicyUrl) ...[
            const SizedBox(height: 12),
            _HelpTile(
              icon: Icons.article_outlined,
              title: 'Privacy Policy',
              subtitle: 'Opens in your browser',
              onTap: () {
                _openUri(
                  context,
                  Uri.parse(AppPublicLinks.privacyPolicyUrl!.trim()),
                );
              },
            ),
          ],
          if (AppPublicLinks.hasTermsOfUseUrl) ...[
            const SizedBox(height: 12),
            _HelpTile(
              icon: Icons.gavel_outlined,
              title: 'Terms of Use',
              subtitle: 'Opens in your browser',
              onTap: () {
                _openUri(
                  context,
                  Uri.parse(AppPublicLinks.termsOfUseUrl!.trim()),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _HelpTile extends StatelessWidget {
  const _HelpTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Icon(icon, color: Colors.blue),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}
