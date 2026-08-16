import 'package:flutter/material.dart';

import '../../domain/your_data_inventory.dart';
import 'privacy_data_screen.dart';

/// User-facing trust page: what TARU stores, sources, and deliberate limits.
///
/// Not a Privacy Policy replacement.
class YourDataInTaruScreen extends StatelessWidget {
  const YourDataInTaruScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: AppBar(
        title: const Text(YourDataInventory.screenTitle),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              YourDataInventory.intro,
              style: TextStyle(
                color: Colors.grey.shade700,
                height: 1.45,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 24),
            for (final YourDataCategory category
                in YourDataInventory.categories) ...<Widget>[
              _CategoryCard(category: category),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 8),
            Text(
              YourDataInventory.doesNotDoTitle,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  for (final String point in YourDataInventory.doesNotDo) ...<
                      Widget>[
                    Text('• $point', style: const TextStyle(height: 1.45)),
                    if (point != YourDataInventory.doesNotDo.last)
                      const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              YourDataInventory.controlsIntro,
              style: TextStyle(color: Colors.grey.shade700, height: 1.4),
            ),
            const SizedBox(height: 12),
            _ControlLink(
              title: 'Export my health data',
              subtitle: 'Create a shareable archive of information you stored.',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const PrivacyDataScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _ControlLink(
              title: 'Delete my health data',
              subtitle: 'Remove health information but keep your TARU login.',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const PrivacyDataScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _ControlLink(
              title: 'Delete TARU account',
              subtitle: 'Remove your health data and login permanently.',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const PrivacyDataScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category});

  final YourDataCategory category;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: '${category.title}. Source: ${category.source}. '
          '${category.location}.',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              category.title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Source: ${category.source}',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              category.location,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 10),
            for (final String bullet in category.bullets) ...<Widget>[
              Text('• $bullet', style: const TextStyle(height: 1.4)),
              if (bullet != category.bullets.last) const SizedBox(height: 6),
            ],
          ],
        ),
      ),
    );
  }
}

class _ControlLink extends StatelessWidget {
  const _ControlLink({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

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
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
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
                        height: 1.35,
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
